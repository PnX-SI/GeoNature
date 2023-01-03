import pytest
from flask import url_for
from sqlalchemy import func
from sqlalchemy.sql import and_

from geonature.tests.fixtures import users
from geonature.core.users.models import VUserslistForallMenu
from geonature.utils.env import db

from pypnusershub.db.models import UserList


@pytest.fixture
def unavailable_menu_id(tlist):
    return db.session.query(func.max(VUserslistForallMenu.id_menu)).scalar() + 1


@pytest.fixture
def tlist(users):
    """
    Create a list if there is no list in the database
    """
    with db.session.begin_nested():
        test_list = UserList(code_liste="testCode", nom_liste="testNom", desc_liste="testDesc")
        db.session.add(test_list)
        test_list.users.append(users["user"])
    return test_list


@pytest.fixture
def user_tlist(tlist):
    """
    Get a user list that is mentioned in VUserslistForallMenu so
    that the get_roles_by_menu_code call works
    """
    # with entity ?
    return (
        UserList.query.with_entities(
            UserList.nom_liste,
            UserList.code_liste,
            UserList.desc_liste,
            VUserslistForallMenu.nom_complet,
        )
        .join(
            VUserslistForallMenu,
            and_(UserList.id_liste == VUserslistForallMenu.id_menu),
        )
        .first()
    )


# No need of temporary transaction since only selects are performed
@pytest.mark.usefixtures("client_class")
class TestApiUsersMenu:
    """
    Test de l'api users/menu
    """

    def test_menu_exists(self):
        resp = self.client.get(url_for("users.get_roles_by_menu_id", id_menu=1))
        users = resp.json
        mandatory_attr = ["id_role", "nom_role", "prenom_role"]
        for user in users:
            for attr in mandatory_attr:
                assert attr in user.keys()
        assert resp.status_code == 200

    def test_menu_notexists(self, unavailable_menu_id):
        resp = self.client.get(url_for("users.get_roles_by_menu_id", id_menu=unavailable_menu_id))

        assert resp.status_code == 200
        assert len(resp.json) == 0

    def test_get_roles_by_menu_code(self, user_tlist):
        resp = self.client.get(
            url_for("users.get_roles_by_menu_code", code_liste=user_tlist.code_liste)
        )
        json_resp = resp.json

        assert resp.status_code == 200
        assert user_tlist.nom_complet in [resp["nom_complet"] for resp in json_resp]

    def test_get_listes(self, user_tlist):
        resp = self.client.get(url_for("users.get_listes"))

        assert resp.status_code == 200
        assert user_tlist.nom_liste in [resp["nom_liste"] for resp in resp.json]
