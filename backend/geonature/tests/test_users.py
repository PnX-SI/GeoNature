import uuid

import pytest
from flask import url_for, current_app
from pypnusershub.db.models import Organisme

# Apparently: need to import both?
from geonature.tests.fixtures import acquisition_frameworks, datasets
from geonature.tests.utils import set_logged_user_cookie
from geonature.utils.env import db


@pytest.fixture
def organisms():
    """
    Returns all organismes
    """
    return db.session.query(Organisme).order_by(Organisme.id_organisme).all()


@pytest.mark.usefixtures("client_class", "temporary_transaction")
class TestUsers:
    def test_get_organismes(self, users, organisms):
        set_logged_user_cookie(self.client, users["admin_user"])

        response = self.client.get(url_for("users.get_organismes"))

        assert response.status_code == 200
        resp_uuids = [uuid.UUID(json_r["uuid_organisme"]) for json_r in response.get_json()]
        for org in organisms:
            assert org.uuid_organisme in resp_uuids

    @pytest.mark.skip()
    def test_get_organismes_no_right(self, users):
        set_logged_user_cookie(self.client, users["noright_user"])

        response = self.client.get(url_for("users.get_organismes"))

        assert response.status_code == 403

    def test_get_organisme_order_by(self, users, organisms):
        set_logged_user_cookie(self.client, users["admin_user"])
        order_by_column = "nom_organisme"

        response = self.client.get(
            url_for("users.get_organismes"), query_string={"orderby": order_by_column}
        )

        assert response.status_code == 200
        org_names = [getattr(org, order_by_column) for org in organisms]
        org_names.sort()
        assert org_names == [j_resp[order_by_column] for j_resp in response.json]

    def test_get_role(self, users):
        self_user = users["self_user"]
        set_logged_user_cookie(self.client, users["admin_user"])

        response = self.client.get(url_for("users.get_role", id_role=self_user.id_role))

        assert response.status_code == 200
        assert self_user.id_role == response.json["id_role"]

    def test_get_roles(self, users):
        noright_user = users["noright_user"]
        set_logged_user_cookie(self.client, users["admin_user"])

        response = self.client.get(url_for("users.get_roles"))

        assert response.status_code == 200
        assert noright_user.id_role in [j_resp["id_role"] for j_resp in response.json]

    def test_get_roles_group(self):
        pass

    def test_get_roles_order_by(self, users):
        set_logged_user_cookie(self.client, users["admin_user"])

        response = self.client.get(
            url_for("users.get_roles"), query_string={"orderby": "identifiant"}
        )

        assert response.status_code == 200
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

        assert response.status_code == 200
        assert users["admin_user"].organisme.nom_organisme not in [
            org["nom_organisme"] for org in response.json
        ]

    def test_inscription_not_found(self):
        response = self.client.post(url_for("users.inscription"))

        assert response.status_code == 404
        assert response.json["message"] == "Page introuvable"
