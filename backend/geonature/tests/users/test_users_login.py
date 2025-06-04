import pytest

from flask import g, url_for
from werkzeug.exceptions import Unauthorized

from geonature.utils.env import db

from pypnusershub.db.models import User, Application, AppUser, UserApplicationRight, Profils
from sqlalchemy import select
from geonature.tests.fixtures import *
from pypnusershub.tests.utils import set_logged_user

from geonature.tests import *
from geonature.tests.utils import logged_user_headers


@pytest.mark.usefixtures("client_class", "temporary_transaction")
class TestUsersLogin:
    @pytest.fixture
    def user(self, app):
        """
        Create a user for testing.

        Parameters
        ----------
        app : pytest.FixtureDef
            geonature app fixture

        Returns
        -------
        pytest.FixtureDef
            fake user fixture
        """
        with db.session.begin_nested():
            user = User(groupe=False, active=True, identifiant="bob", password="password")
            db.session.add(user)
            application = db.session.scalars(
                select(Application).filter_by(code_application=app.config["CODE_APPLICATION"])
            ).one()
            profil = db.session.scalars(
                select(Profils).where(Profils.applications.contains(application)).limit(1)
            ).first()
            right = UserApplicationRight(
                role=user, id_profil=profil.id_profil, id_application=application.id_application
            )
            db.session.add(right)
        return user

    def test_current_user(self, app, user):
        """
        Test if the desired user logged in is the one available in the `g.current_user` global variable.

        Parameters
        ----------
        app : pytest.FixtureDef
            geonature app fixture
        users : pytest.FixtureDef
            user fixture
        """
        with app.test_request_context(headers=logged_user_headers(user)):
            app.preprocess_request()
            assert g.current_user == user

    def test_public_user(self, app, user, monkeypatch):
        """
        Test if the public access is working

        Parameters
        ----------
        app : pytest.FixtureDef
            geonature app fixture
        users : pytest.FixtureDef
            user fixture
        monkeypatch : pytest.FixtureDef
            pytest fixture to patch/set environment variables
        """
        monkeypatch.setitem(app.config, "PUBLIC_ACCESS_USERNAME", user.identifiant)
        response = self.client.post(url_for("auth.public_login"))
        assert response.status_code == 200


@pytest.mark.usefixtures("client_class", "temporary_transaction")
class TestApiUsersLogin:
    def test_connect_api_user(self, users):
        user = users["self_user"]
        api_key, api_secret = user.generate_api_secret()
        assert User.check_api_key(api_key, api_secret) == user
        assert User.check_api_key(api_key, "RANDOM SECRET") is None

    def test_gen_api_secret_route(self, users):
        user = users["self_user"]
        url = url_for("users.get_api_secret")
        r = self.client.get(url)
        assert r.status_code == Unauthorized.code
        set_logged_user(self.client, user)
        r = self.client.get(url)
        assert r.status_code == 200
        data = r.json
        assert "api_key" in data
        assert "api_secret" in data
        assert data["api_key"] == user.api_key
