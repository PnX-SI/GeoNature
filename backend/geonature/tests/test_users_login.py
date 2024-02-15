import pytest

from flask import g, url_for

from geonature.utils.env import db

from pypnusershub.db.models import User, Application, AppUser, UserApplicationRight, Profils
from sqlalchemy import select

from . import *
from .utils import logged_user_headers


@pytest.mark.usefixtures("client_class", "temporary_transaction")
class TestUsersLogin:
    @pytest.fixture
    def user(self, app):
        with db.session.begin_nested():
            user = User(groupe=False, active=True, identifiant="user", password="password")
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
        with app.test_request_context(headers=logged_user_headers(user)):
            app.preprocess_request()
            assert g.current_user == user

    def test_public_user(self, app, user, monkeypatch):
        monkeypatch.setitem(app.config, "PUBLIC_ACCESS_USERNAME", user.identifiant)
        response = self.client.post(url_for("auth.public_login"))
        assert response.status_code == 200
