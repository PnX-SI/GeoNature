import json
import pytest
from flask import url_for, session, Response, request
from tests.bootstrap_test import app, post_json, json_of_response
from cookies import Cookie


@pytest.mark.usefixtures("client_class")
class TestApiRegister:
    """
        Test de l'api register
    """

    def test_register1(self):
        assert True

