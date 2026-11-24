import pytest

from flask import g, url_for

from geonature.utils.env import db

from pypnusershub.db.models import User, Application, AppUser, UserApplicationRight, Profils
from sqlalchemy import select

from . import *
from .utils import logged_user_headers


@pytest.mark.usefixtures("client_class")
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

    def test_public_user_unknown(self, app, monkeypatch):
        """
        A PUBLIC_ACCESS_USERNAME matching no user must not raise a server error
        """
        monkeypatch.setitem(app.config, "PUBLIC_ACCESS_USERNAME", "unknown-public-user")
        response = self.client.post(url_for("auth.public_login"))
        assert response.status_code == 403

    def test_inactive_user_not_authenticated(self, app, user):
        """
        An inactive user with a valid token must be treated as anonymous
        """
        user.active = False
        db.session.flush()
        with app.test_request_context(headers=logged_user_headers(user)):
            app.preprocess_request()
            assert not g.current_user.is_authenticated

    def test_public_user_inactive(self, app, user, monkeypatch):
        """
        An inactive PUBLIC_ACCESS_USERNAME must not be able to log in
        """
        user.active = False
        db.session.flush()
        monkeypatch.setitem(app.config, "PUBLIC_ACCESS_USERNAME", user.identifiant)
        response = self.client.post(url_for("auth.public_login"))
        assert response.status_code == 403

    def test_group_cannot_login(self, app, user):
        """
        A group (even with a password) must not be able to log in
        """
        user.groupe = True
        db.session.flush()
        response = self.client.post(
            url_for("auth.login"), json={"login": user.identifiant, "password": "password"}
        )
        assert response.status_code == 401
