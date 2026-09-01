from typing import Any, Optional, Union
from urllib.parse import quote
import time
import uuid

import requests
import sqlalchemy as sa
from flask import current_app, session
from marshmallow import EXCLUDE, ValidationError, fields
from pypnusershub.auth import ProviderConfigurationSchema, oauth
from pypnusershub.auth.providers.openid_provider import OpenIDConnectProvider
from pypnusershub.db import db, models


class KeycloakOrganismProvider(OpenIDConnectProvider):
    """
    OpenID Connect provider with automatic organism reconciliation.

    Expected token/userinfo claims:
    - groups (list[str]) with entries like "/organismes/<slug-or-name>"
    - optionally a claim containing organism UUID (default: "uuid_organisme")
    - optionally a claim containing organism label (default: "organisme")
    """

    group_prefix = "/organismes/"
    organism_uuid_claim = "uuid_organisme"
    organism_name_claim = "organisme"
    user_uuid_claim = "sub"
    keycloak_issuer = None
    keycloak_admin_client_id = None
    keycloak_admin_client_secret = None
    keycloak_admin_timeout = 5
    _kc_admin_token = None
    _kc_admin_token_exp = 0

    def configure(self, configuration: Union[dict, Any]) -> None:
        super().configure(configuration)

        class KeycloakOrganismConfiguration(ProviderConfigurationSchema):
            ORGANISM_GROUP_PREFIX = fields.String(load_default="/organismes/")
            ORGANISM_UUID_CLAIM = fields.String(load_default="uuid_organisme")
            ORGANISM_NAME_CLAIM = fields.String(load_default="organisme")
            USER_UUID_CLAIM = fields.String(load_default="sub")
            KEYCLOAK_ADMIN_CLIENT_ID = fields.String(load_default=None, allow_none=True)
            KEYCLOAK_ADMIN_CLIENT_SECRET = fields.String(load_default=None, allow_none=True)
            KEYCLOAK_ADMIN_TIMEOUT = fields.Integer(load_default=5)

        try:
            conf = KeycloakOrganismConfiguration().load(configuration, unknown=EXCLUDE)
        except ValidationError as e:
            raise ValidationError(f"Error while loading Keycloak organism configuration: {e}")

        self.group_prefix = conf["ORGANISM_GROUP_PREFIX"]
        self.organism_uuid_claim = conf["ORGANISM_UUID_CLAIM"]
        self.organism_name_claim = conf["ORGANISM_NAME_CLAIM"]
        self.user_uuid_claim = conf["USER_UUID_CLAIM"]
        self.keycloak_admin_client_id = conf["KEYCLOAK_ADMIN_CLIENT_ID"]
        self.keycloak_admin_client_secret = conf["KEYCLOAK_ADMIN_CLIENT_SECRET"]
        self.keycloak_admin_timeout = conf["KEYCLOAK_ADMIN_TIMEOUT"]
        # ISSUER is required by OpenIDConnectProvider, keep it for admin API calls.
        self.keycloak_issuer = configuration.get("ISSUER")

    def _extract_first_group_organism_path(self, groups):
        if not groups:
            return None
        for group in groups:
            if isinstance(group, str) and group.startswith(self.group_prefix):
                return group
        return None

    def _extract_first_group_organism_name(self, groups):
        group_path = self._extract_first_group_organism_path(groups)
        if not group_path:
            return None
        # Keep leaf name only: /organismes/foo/bar -> bar
        return group_path.rstrip("/").split("/")[-1] or None

    def _get_kc_admin_base(self) -> Optional[str]:
        if not self.keycloak_issuer or "/realms/" not in self.keycloak_issuer:
            return None
        host, realm = self.keycloak_issuer.split("/realms/", 1)
        return f"{host}/admin/realms/{realm}"

    def _get_kc_admin_token(self) -> Optional[str]:
        if not (
            self.keycloak_issuer
            and self.keycloak_admin_client_id
            and self.keycloak_admin_client_secret
        ):
            return None
        if self._kc_admin_token and time.time() < self._kc_admin_token_exp:
            return self._kc_admin_token

        token_url = f"{self.keycloak_issuer}/protocol/openid-connect/token"
        resp = requests.post(
            token_url,
            data={
                "grant_type": "client_credentials",
                "client_id": self.keycloak_admin_client_id,
                "client_secret": self.keycloak_admin_client_secret,
            },
            timeout=self.keycloak_admin_timeout,
        )
        if not resp.ok:
            current_app.logger.warning(
                "Keycloak admin token request failed: %s - %s",
                resp.status_code,
                resp.text[:200],
            )
            return None
        payload = resp.json()
        self._kc_admin_token = payload.get("access_token")
        self._kc_admin_token_exp = time.time() + max(payload.get("expires_in", 60) - 10, 10)
        return self._kc_admin_token

    def _get_group_attributes_from_keycloak(self, group_path):
        admin_base = self._get_kc_admin_base()
        admin_token = self._get_kc_admin_token()
        if not admin_base or not admin_token or not group_path:
            return None

        # Some Keycloak setups expect "/" to remain unescaped in group-by-path.
        url = f"{admin_base}/group-by-path/{quote(group_path, safe='/')}"
        resp = requests.get(
            url,
            headers={"Authorization": f"Bearer {admin_token}"},
            timeout=self.keycloak_admin_timeout,
        )
        if resp.ok:
            return resp.json()

        # Fallback: use search endpoint then match exact path recursively.
        leaf_name = group_path.rstrip("/").split("/")[-1]
        search_url = (
            f"{admin_base}/groups?search={quote(leaf_name, safe='')}"
            "&briefRepresentation=false&max=200"
        )
        search_resp = requests.get(
            search_url,
            headers={"Authorization": f"Bearer {admin_token}"},
            timeout=self.keycloak_admin_timeout,
        )
        if search_resp.ok:
            groups = search_resp.json()

            def walk(items):
                for item in items or []:
                    if item.get("path") == group_path:
                        return item
                    found = walk(item.get("subGroups") or [])
                    if found:
                        return found
                return None

            found_group = walk(groups)
            if found_group:
                return found_group

        # Keep warning logs for diagnostics.
        if not resp.ok:
            current_app.logger.warning(
                "Keycloak group-by-path failed for %s: %s - %s",
                group_path,
                resp.status_code,
                resp.text[:200],
            )
        if "search_resp" in locals() and not search_resp.ok:
            current_app.logger.warning(
                "Keycloak groups search failed for %s: %s - %s",
                leaf_name,
                search_resp.status_code,
                search_resp.text[:200],
            )
        return None

    def _resolve_organism(self, user_info, source_groups):
        org_id = None
        org_uuid = user_info.get(self.organism_uuid_claim)
        org_name = user_info.get(self.organism_name_claim)

        if not org_uuid or not org_name:
            group_path = self._extract_first_group_organism_path(source_groups)
            group_obj = self._get_group_attributes_from_keycloak(group_path)
            if group_obj:
                group_attrs = group_obj.get("attributes") or {}
                id_values = group_attrs.get("id_organisme") or []
                if id_values:
                    try:
                        org_id = int(id_values[0])
                    except (TypeError, ValueError):
                        current_app.logger.warning(
                            "Invalid id_organisme value on group %s: %s",
                            group_obj.get("path"),
                            id_values[0],
                        )
                if not org_uuid:
                    uuid_values = group_attrs.get("uuid_organisme") or []
                    if uuid_values:
                        org_uuid = uuid_values[0]
                if not org_name:
                    name_values = group_attrs.get("nom_organisme") or []
                    org_name = name_values[0] if name_values else group_obj.get("name")

        # Fallback to group leaf if no nom_organisme is provided.
        org_name = org_name or self._extract_first_group_organism_name(source_groups)

        # Nothing to reconcile.
        if not org_uuid and not org_name:
            return None

        organism = None
        if org_id:
            organism = db.session.execute(
                sa.select(models.Organisme).where(models.Organisme.id_organisme == org_id)
            ).scalar_one_or_none()
        if org_uuid:
            organism_by_uuid = db.session.execute(
                sa.select(models.Organisme).where(models.Organisme.uuid_organisme == org_uuid)
            ).scalar_one_or_none()
            if (
                organism
                and organism_by_uuid
                and organism.id_organisme != organism_by_uuid.id_organisme
            ):
                current_app.logger.warning(
                    "Organism mismatch between id_organisme=%s and uuid_organisme=%s",
                    org_id,
                    org_uuid,
                )
            if not organism:
                organism = organism_by_uuid
        if not organism and org_name:
            organism = db.session.execute(
                sa.select(models.Organisme).where(models.Organisme.nom_organisme == org_name)
            ).scalar_one_or_none()

        if not organism:
            organism = models.Organisme(nom_organisme=org_name or str(org_uuid))
            if org_id:
                # Keep upstream identifier when available (migration-friendly).
                organism.id_organisme = org_id
            if org_uuid:
                organism.uuid_organisme = org_uuid
            db.session.add(organism)
            db.session.flush()
            return organism

        updated = False
        if org_id and organism.id_organisme != org_id:
            # id_organisme is the local PK, do not overwrite an existing row identity.
            current_app.logger.warning(
                "Ignoring id_organisme=%s for existing organism id=%s",
                org_id,
                organism.id_organisme,
            )
        if org_uuid and organism.uuid_organisme != org_uuid:
            organism.uuid_organisme = org_uuid
            updated = True
        if org_name and organism.nom_organisme != org_name:
            organism.nom_organisme = org_name
            updated = True
        if updated:
            db.session.flush()
        return organism

    def authorize(self):
        oauth_provider = getattr(oauth, self.id_provider)
        token = oauth_provider.authorize_access_token()
        session["openid_token_resp"] = token

        user_info = token["userinfo"]
        source_groups = (
            user_info[self.group_claim_name] if self.group_claim_name in user_info else []
        )

        organism = self._resolve_organism(user_info, source_groups)
        keycloak_user_uuid = None
        uuid_claim_value = user_info.get(self.user_uuid_claim)
        if uuid_claim_value:
            try:
                keycloak_user_uuid = str(uuid.UUID(str(uuid_claim_value)))
            except (ValueError, TypeError):
                current_app.logger.warning(
                    "Invalid user UUID claim '%s' value: %s",
                    self.user_uuid_claim,
                    uuid_claim_value,
                )
        new_user = {
            "identifiant": user_info[self.identifier_field],
            "email": user_info["email"],
            "prenom_role": user_info["given_name"],
            "nom_role": user_info["family_name"],
            "active": True,
        }
        if keycloak_user_uuid:
            new_user["uuid_role"] = keycloak_user_uuid
        if organism:
            new_user["id_organisme"] = organism.id_organisme

        user = self.insert_or_update_role(
            new_user, source_groups=source_groups, reconciliate_attr="identifiant"
        )
        db.session.commit()
        return user
