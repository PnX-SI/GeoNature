import json
import pytest
from flask import url_for, session, Response, request
from .bootstrap_test import app, post_json, json_of_response
from cookies import Cookie


@pytest.mark.usefixtures("client_class")
class TestApiUsersMenu:
    """
        Test de l'api users/menu
    """

    def test_menu_exists(self):
        resp = self.client.get(url_for("users.getRolesByMenuId", id_menu=1))
        data = json_of_response(resp)
        user = data[0]
        mandatory_attr = ["id_role", "nom_role", "prenom_role"]
        for attr in mandatory_attr:
            assert attr in user
        assert resp.status_code == 200

    def test_menu_notexists(self):
        resp = self.client.get(url_for("users.getRolesByMenuId", id_menu=4554269545))
        assert resp.status_code == 404
