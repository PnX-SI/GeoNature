import pytest
from flask import url_for
from sqlalchemy import func

from geonature.core.users.models import VUserslistForallMenu
from geonature.utils.env import db


@pytest.fixture
def unavailable_menu_id():
    return db.session.query(func.max(VUserslistForallMenu.id_menu)).scalar() + 1


@pytest.mark.usefixtures("client_class")
class TestApiUsersMenu:
    """
    Test de l'api users/menu
    """

    def test_menu_exists(self):
        resp = self.client.get(url_for("users.getRolesByMenuId", id_menu=1))
        users = resp.json
        mandatory_attr = ["id_role", "nom_role", "prenom_role"]
        for user in users:
            for attr in mandatory_attr:
                assert attr in user.keys()
        assert resp.status_code == 200

    def test_menu_notexists(self, unavailable_menu_id):
        resp = self.client.get(url_for("users.getRolesByMenuId", id_menu=unavailable_menu_id))

        assert resp.status_code == 404
