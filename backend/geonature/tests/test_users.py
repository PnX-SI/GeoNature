import json
import uuid

from flask import url_for
import pytest
from pypnusershub.db.models import Organisme as BibOrganismes

from geonature.utils.env import db
from geonature.tests.utils import set_logged_user_cookie

# Apparently: need to import both?
from geonature.tests.fixtures import datasets, acquisition_frameworks


@pytest.fixture
def organisms():
    """
    Returns all organismes
    """
    return db.session.query(BibOrganismes).order_by(BibOrganismes.id_organisme).all()


@pytest.mark.usefixtures("client_class", "temporary_transaction")
class TestUsers:
    def test_get_organismes(self, organisms):
        response = self.client.get(url_for("users.get_organismes"))

        resp_uuids = [uuid.UUID(json_r["uuid_organisme"]) for json_r in response.json]
        for org in organisms:
            assert org.uuid_organisme in resp_uuids

    def test_get_organisme_order_by(self, organisms):
        order_by_column = "nom_organisme"
        response = self.client.get(
            url_for("users.get_organismes"), query_string={"orderby": order_by_column}
        )

        org_names = [getattr(org, order_by_column) for org in organisms]
        org_names.sort()
        assert org_names == [j_resp[order_by_column] for j_resp in response.json]

    def test_get_role(self, users):
        self_user = users["self_user"]
        response = self.client.get(url_for("users.get_role", id_role=self_user.id_role))

        assert self_user.id_role == response.json["id_role"]

    def test_get_roles(self, users):
        noright_user = users["noright_user"]
        response = self.client.get(url_for("users.get_roles"))

        assert noright_user.id_role in [j_resp["id_role"] for j_resp in response.json]

    def test_get_roles_group(self):
        pass

    def test_get_roles_order_by(self, users):
        response = self.client.get(
            url_for("users.get_roles"), query_string={"orderby": "identifiant"}
        )

        identifiants_resp = [resp["identifiant"] for resp in response.json]
        assert identifiants_resp.index(users["admin_user"].identifiant) < identifiants_resp.index(
            users["stranger_user"].identifiant
        )

    def test_get_organismes_jdd_no_auth(self):
        response = self.client.get(url_for("users.get_organismes_jdd"))

        assert response.status_code == 401

    def test_get_organismes_jdd(self, users, datasets):
        # Need to have a dataset to have the organism...
        set_logged_user_cookie(self.client, users["admin_user"])

        response = self.client.get(url_for("users.get_organismes_jdd"))

        assert users["admin_user"].organisme.nom_organisme in [
            org["nom_organisme"] for org in response.json
        ]

    def test_get_organismes_jdd_no_dataset(self, users):
        set_logged_user_cookie(self.client, users["admin_user"])

        response = self.client.get(url_for("users.get_organismes_jdd"))

        assert users["admin_user"].organisme.nom_organisme not in [
            org["nom_organisme"] for org in response.json
        ]
