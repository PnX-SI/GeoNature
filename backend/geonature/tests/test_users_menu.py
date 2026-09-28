from pypnusershub.tests.utils import set_logged_user
import pytest
from flask import url_for
from sqlalchemy import func, select
from sqlalchemy.sql import and_

from geonature.core.users.models import VUserslistForallMenu
from geonature.utils.env import db


from pypnusershub.db.models import UserList
from werkzeug.exceptions import BadRequest, Unauthorized


@pytest.fixture
def unavailable_menu_id(tlist):
    return (
        db.session.execute(
            select(func.max(VUserslistForallMenu.id_menu)).select_from(VUserslistForallMenu)
        ).scalar()
        + 1
    )


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
    return db.session.execute(
        select(
            UserList.nom_liste,
            UserList.code_liste,
            UserList.desc_liste,
            VUserslistForallMenu.nom_complet,
        ).join(
            VUserslistForallMenu,
            UserList.id_liste == VUserslistForallMenu.id_menu,
        )
    ).first()


# No need of temporary transaction since only selects are performed
@pytest.mark.usefixtures("client_class")
class TestApiUsersMenu:
    """
    Test de l'api users/menu
    """

    @pytest.mark.parametrize("id_menu", [None, 1])
    def test_menu_exists(self, users, id_menu):
        set_logged_user(self.client, users["user"])
        resp = self.client.get(url_for("users.get_roles_by_menu_id", id_menu=id_menu))
        users = resp.json
        mandatory_attr = ["id_role", "nom_role", "prenom_role"]
        for user in users:
            for attr in mandatory_attr:
                assert attr in user.keys()
        assert resp.status_code == 200

    def test_menu_by_id_with_nomcomplet(self, users, user_tlist):
        set_logged_user(self.client, users["user"])
        nom_complet = users["user"].nom_complet

        resp = self.client.get(url_for("users.get_roles_by_menu_id", nom_complet=nom_complet))
        assert resp.status_code == 200

        users_ = resp.json
        assert len(users_) == 1

        # need to lower since the nom_complet is modified by the view :/
        # (upper(a.nom_role::text) || ' '::text) || a.prenom_role::text AS nom_complet,
        assert users_[0]["nom_complet"].lower() == nom_complet.lower()

    def test_menu_notexists(self, users, unavailable_menu_id):
        set_logged_user(self.client, users["user"])
        resp = self.client.get(url_for("users.get_roles_by_menu_id", id_menu=unavailable_menu_id))

        assert resp.status_code == 200
        assert len(resp.json) == 0

    def test_get_roles_by_menu_code(self, users, user_tlist):
        set_logged_user(self.client, users["user"])
        resp = self.client.get(
            url_for("users.get_roles_by_menu_code", code_liste=user_tlist.code_liste)
        )
        json_resp = resp.json

        assert resp.status_code == 200
        assert user_tlist.nom_complet in [resp["nom_complet"] for resp in json_resp]

    def test_get_listes(self, users, user_tlist):
        set_logged_user(self.client, users["user"])
        resp = self.client.get(url_for("users.get_listes"))

        assert resp.status_code == 200
        assert user_tlist.nom_liste in [resp["nom_liste"] for resp in resp.json]


@pytest.fixture
def filter_tlist(users):
    """
    A user list containing several users, used to test the search parameters of the
    user list routes. nom_complet (computed by the view) is ``UPPER(nom_role) || ' ' || prenom_role``:
    "BOB Bobby", "USER Associate", "USER Self", "USER NoRight".
    """
    with db.session.begin_nested():
        test_list = UserList(
            code_liste="testFilterCode", nom_liste="testFilterNom", desc_liste="testFilterDesc"
        )
        db.session.add(test_list)
        for username in ("user", "associate_user", "self_user", "noright_user"):
            test_list.users.append(users[username])
    return test_list


# The same search parameters must be handled by /menu/<id_menu> and /menu_from_code/<code>
@pytest.fixture(params=["by_id", "by_code"])
def menu_url(request, filter_tlist):
    def _menu_url(**query):
        if request.param == "by_id":
            return url_for("users.get_roles_by_menu_id", id_menu=filter_tlist.id_liste, **query)
        return url_for("users.get_roles_by_menu_code", code_liste=filter_tlist.code_liste, **query)

    return _menu_url


@pytest.mark.usefixtures("client_class")
class TestApiUsersMenuSearchParams:
    """
    Search parameters (nom_complet, limit, id_role) of the user list routes
    """

    def test_no_auth(self, menu_url):
        response = self.client.get(menu_url())
        assert response.status_code == Unauthorized.code

    def test_no_param_returns_whole_list(self, users, menu_url):
        set_logged_user(self.client, users["user"])

        response = self.client.get(menu_url())

        assert response.status_code == 200
        assert {r["id_role"] for r in response.json} == {
            users[u].id_role for u in ("user", "associate_user", "self_user", "noright_user")
        }
        # response shape is unchanged
        for role in response.json:
            assert set(role.keys()) == {
                "id_role",
                "nom_role",
                "prenom_role",
                "nom_complet",
                "id_menu",
            }
        # ordered by nom_complet
        assert [r["nom_complet"] for r in response.json] == sorted(
            r["nom_complet"] for r in response.json
        )

    @pytest.mark.parametrize(
        "nom_complet",
        [
            "Associate",  # end of the name
            "sociat",  # middle of the name (contains, not only prefix)
            "USER ASSOC",  # case insensitive
            "  associate  ",  # stripped
        ],
    )
    def test_nom_complet_contains(self, users, menu_url, nom_complet):
        set_logged_user(self.client, users["user"])

        response = self.client.get(menu_url(nom_complet=nom_complet))

        assert response.status_code == 200
        assert [r["id_role"] for r in response.json] == [users["associate_user"].id_role]

    def test_nom_complet_matches_several(self, users, menu_url):
        set_logged_user(self.client, users["user"])

        response = self.client.get(menu_url(nom_complet="user"))

        assert response.status_code == 200
        assert {r["id_role"] for r in response.json} == {
            users[u].id_role for u in ("associate_user", "self_user", "noright_user")
        }

    def test_nom_complet_no_match(self, users, menu_url):
        set_logged_user(self.client, users["user"])

        response = self.client.get(menu_url(nom_complet="zzz-no-such-user-zzz"))

        assert response.status_code == 200
        assert response.json == []

    @pytest.mark.parametrize("nom_complet", ["", " ", "   ", "\t"])
    def test_nom_complet_whitespace_ignored(self, users, menu_url, nom_complet):
        set_logged_user(self.client, users["user"])

        response = self.client.get(menu_url(nom_complet=nom_complet))

        assert response.status_code == 200
        assert len(response.json) == 4

    @pytest.mark.parametrize("limit,expected_len", [(0, 0), (1, 1), (2, 2), (4, 4), (100, 4)])
    def test_limit(self, users, menu_url, limit, expected_len):
        set_logged_user(self.client, users["user"])

        response = self.client.get(menu_url(limit=limit))

        assert response.status_code == 200
        assert len(response.json) == expected_len
        # limit is applied after ordering by nom_complet
        full = self.client.get(menu_url()).json
        assert response.json == full[:expected_len]

    def test_limit_with_nom_complet(self, users, menu_url):
        set_logged_user(self.client, users["user"])

        response = self.client.get(menu_url(nom_complet="user", limit=2))

        assert response.status_code == 200
        assert len(response.json) == 2
        assert all("USER" in r["nom_complet"] for r in response.json)

    @pytest.mark.parametrize("limit", ["abc", "1.5", "-1"])
    def test_invalid_limit(self, users, menu_url, limit):
        set_logged_user(self.client, users["user"])

        response = self.client.get(menu_url(limit=limit))

        assert response.status_code == BadRequest.code

    def test_id_role_single(self, users, menu_url):
        set_logged_user(self.client, users["user"])
        id_role = users["self_user"].id_role

        response = self.client.get(menu_url(id_role=id_role))

        assert response.status_code == 200
        assert [r["id_role"] for r in response.json] == [id_role]

    @pytest.mark.parametrize("mode", ["repeat", "comma", "mixed"])
    def test_id_role_multiple(self, users, menu_url, mode):
        set_logged_user(self.client, users["user"])
        ids = [users[u].id_role for u in ("self_user", "noright_user", "associate_user")]

        if mode == "repeat":
            id_role = ids
        elif mode == "comma":
            id_role = ",".join(map(str, ids))
        else:
            id_role = [f"{ids[0]},{ids[1]}", ids[2]]
        response = self.client.get(menu_url(id_role=id_role))

        assert response.status_code == 200
        assert {r["id_role"] for r in response.json} == set(ids)

    def test_id_role_not_in_list(self, users, menu_url):
        # id_role restricts the list, it does not add roles outside of it
        set_logged_user(self.client, users["user"])

        response = self.client.get(
            menu_url(id_role=[users["admin_user"].id_role, users["self_user"].id_role])
        )

        assert response.status_code == 200
        assert [r["id_role"] for r in response.json] == [users["self_user"].id_role]

    def test_id_role_with_nom_complet(self, users, menu_url):
        set_logged_user(self.client, users["user"])

        response = self.client.get(
            menu_url(id_role=[users["self_user"].id_role, users["user"].id_role], nom_complet="bob")
        )

        assert response.status_code == 200
        assert [r["id_role"] for r in response.json] == [users["user"].id_role]

    @pytest.mark.parametrize("id_role", ["abc", "1,abc", ["1", "x"], "1.5"])
    def test_invalid_id_role(self, users, menu_url, id_role):
        set_logged_user(self.client, users["user"])

        response = self.client.get(menu_url(id_role=id_role))

        assert response.status_code == BadRequest.code

    def test_menu_all_lists_nom_complet(self, users, filter_tlist):
        """/menu/ (no id_menu) searches in every list"""
        set_logged_user(self.client, users["user"])

        response = self.client.get(
            url_for("users.get_roles_by_menu_id", nom_complet="sociat", limit=50)
        )

        assert response.status_code == 200
        assert users["associate_user"].id_role in [r["id_role"] for r in response.json]
        assert all("sociat" in r["nom_complet"].lower() for r in response.json)
