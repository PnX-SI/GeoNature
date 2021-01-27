import pytest
from flask import url_for, Response, request, current_app
from .bootstrap_test import app, post_json, json_of_response


@pytest.mark.usefixtures("client_class")
class TestApiPyPnUsershub:
    """
        Test de l'api du sous module d'authentification
    """

    def test_login(self):
        login_data = {
            "login": "admin",
            "password": "admin",
            "id_application": current_app.config["ID_APPLICATION_GEONATURE"],
        }
        response = post_json(self.client, url_for("auth.login"), login_data)
        assert response.status_code == 200

