import pytest

from flask import g, url_for

from geonature.utils.env import db

from pypnusershub.db.models import User, Application, AppUser, UserApplicationRight, Profils

from . import *
from .utils import logged_user_headers


@pytest.mark.usefixtures("client_class", "temporary_transaction")
class TestUsersLogin:
    @pytest.fixture
    def user(self, app):
        id_app = app.config["ID_APP"]
        with db.session.begin_nested():
            user = User(groupe=False, active=True, identifiant="user", password="password")
            db.session.add(user)
            application = Application.query.get(id_app)
            profil = Profils.query.filter(Profils.applications.contains(application)).first()
            right = UserApplicationRight(
                role=user, id_profil=profil.id_profil, id_application=application.id_application
            )
            db.session.add(right)
        return user

    def test_current_user(self, app, user):
        with app.test_request_context(headers=logged_user_headers(user)):
            app.preprocess_request()
            assert g.current_user == user
