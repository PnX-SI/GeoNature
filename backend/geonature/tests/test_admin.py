from datetime import datetime, timedelta

import pytest
from flask import url_for
from sqlalchemy import select
from ref_geo.models import LAreas, BibAreasTypes
from pypnusershub.db.models import Application, User, UserApplicationRight
from pypnusershub.db.models import Profils as Profil
from pypnusershub.tests.utils import set_logged_user

from geonature.utils.env import db
from geonature.core.gn_commons.models import TModules
from geonature.core.gn_permissions.admin import PermissionAdmin
from geonature.core.gn_permissions.models import (
    Permission,
    PermAction,
    PermObject,
    PermissionAvailable,
)

PERMISSION_ADMIN_ENDPOINTS = [
    "permissions/group.index_view",
    "permissions/user.index_view",
    "permissions/permission.index_view",
]


@pytest.mark.usefixtures("client_class")
class TestAreaPermissionAdmin:

    def test_ajax_area_lookup_sorting(self, users):
        """Teste que la recherche 'Ain' remonte 'Ain' en premier."""

        set_logged_user(self.client, users["admin_user"])
        url = url_for("permissions/permission.ajax_lookup")
        response = self.client.get(
            url, query_string={"name": "areas_filter", "query": "Ain", "offset": 0, "limit": 10}
        )

        assert response.status_code == 200
        data = response.json

        assert isinstance(data, list)
        results = [item[1] for item in data]

        assert results[0] == "Ain (Départements)"
        assert results[1].startswith("Ain")

    def test_ajax_area_no_query(self, users):
        """Teste le tri par défaut (id_type, area_name) sans paramètre query."""

        set_logged_user(self.client, users["admin_user"])
        url = url_for("permissions/permission.ajax_lookup", name="areas_filter")

        response = self.client.get(url)

        assert response.status_code == 200
        assert isinstance(response.json, list)
        assert len(response.json) > 0


@pytest.mark.usefixtures("client_class")
class TestPermissionAdminAccess:
    """Covers CruvedProtectedMixin.is_accessible for the registered permission admin views."""

    @pytest.mark.parametrize("endpoint", PERMISSION_ADMIN_ENDPOINTS)
    def test_anonymous_user_is_unauthorized(self, endpoint):
        response = self.client.get(url_for(endpoint))
        assert response.status_code == 401

    @pytest.mark.parametrize("endpoint", PERMISSION_ADMIN_ENDPOINTS)
    def test_no_right_user_is_forbidden(self, users, endpoint):
        set_logged_user(self.client, users["noright_user"])
        response = self.client.get(url_for(endpoint))
        assert response.status_code == 403

    @pytest.mark.parametrize("endpoint", PERMISSION_ADMIN_ENDPOINTS)
    def test_admin_user_can_access(self, users, endpoint):
        set_logged_user(self.client, users["admin_user"])
        response = self.client.get(url_for(endpoint))
        assert response.status_code == 200


@pytest.mark.usefixtures("client_class")
class TestGroupUserPermAdminScoping:
    """Covers GroupPermAdmin/UserPermAdmin.get_query filtering on User.groupe."""

    @pytest.fixture
    def admin_test_group(self):
        app = db.session.execute(
            select(Application).where(Application.code_application == "GN")
        ).scalar_one()
        profil = db.session.execute(
            select(Profil).where(Profil.nom_profil == "Lecteur")
        ).scalar_one()
        with db.session.begin_nested():
            group = User(groupe=True, nom_role="GroupePermAdminTest")
            db.session.add(group)
        with db.session.begin_nested():
            db.session.add(
                UserApplicationRight(
                    id_role=group.id_role,
                    id_application=app.id_application,
                    id_profil=profil.id_profil,
                )
            )
        return group

    def test_group_view_lists_only_groups(self, users, admin_test_group):
        set_logged_user(self.client, users["admin_user"])
        response = self.client.get(url_for("permissions/group.index_view"))
        assert response.status_code == 200
        assert b"GroupePermAdminTest" in response.data
        assert b"Bobby" not in response.data  # users["user"] is not a group

    def test_user_view_lists_only_users(self, users, admin_test_group):
        set_logged_user(self.client, users["admin_user"])
        response = self.client.get(url_for("permissions/user.index_view"))
        assert response.status_code == 200
        assert b"GroupePermAdminTest" not in response.data
        assert b"Bobby" in response.data


@pytest.mark.usefixtures("client_class")
class TestPermissionAdminActiveFilter:
    """Covers PermissionAdmin.get_query/get_count_query filtering via Permission.active_filter."""

    @pytest.fixture
    def permission_available(self):
        with db.session.begin_nested():
            module = TModules(
                module_code="PERM_ADMIN_TEST",
                module_label="Perm Admin Test",
                module_path="perm_admin_test",
                active_frontend=False,
                active_backend=False,
            )
            db.session.add(module)
        object_all = db.session.execute(
            select(PermObject).filter_by(code_object="ALL")
        ).scalar_one()
        action_r = db.session.execute(select(PermAction).filter_by(code_action="R")).scalar_one()
        with db.session.begin_nested():
            avail = PermissionAvailable(
                module=module,
                object=object_all,
                action=action_r,
                label="Lecture Test",
            )
            db.session.add(avail)
        return avail

    def test_expired_and_unvalidated_permissions_are_hidden(self, users, permission_available):
        # The real permission table is populated with hundreds of rows by the `users` fixture
        # (one row per role/module/object/action), so exercising this through index_view's HTML
        # would be at the mercy of default sorting/pagination. Call get_query/get_count_query
        # directly instead, which is what actually implements Permission.active_filter scoping.
        target = users["user"]
        with db.session.begin_nested():
            visible = Permission(
                role=target,
                module=permission_available.module,
                object=permission_available.object,
                action=permission_available.action,
            )
            expired = Permission(
                role=target,
                module=permission_available.module,
                object=permission_available.object,
                action=permission_available.action,
                expire_on=datetime.now() - timedelta(days=1),
            )
            unvalidated = Permission(
                role=target,
                module=permission_available.module,
                object=permission_available.object,
                action=permission_available.action,
                validated=False,
            )
            db.session.add_all([visible, expired, unvalidated])
            db.session.flush()

        # `target` already has plenty of unrelated permissions (created by the `users` fixture
        # itself), so scope the check to the dedicated test module instead of the role.
        view = PermissionAdmin(Permission, db)
        visible_ids = {
            p.id_permission
            for p in view.get_query().where(Permission.module == permission_available.module).all()
        }
        assert visible_ids == {visible.id_permission}
        assert (
            view.get_count_query().where(Permission.module == permission_available.module).scalar()
            == 1
        )
