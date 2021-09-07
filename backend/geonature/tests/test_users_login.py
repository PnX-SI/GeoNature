import pytest

from flask import g, url_for, current_app

from geonature.utils.env import db

from pypnusershub.db.models import User, Application, AppUser, UserApplicationRight, ProfilsForApp

from . import login, temporary_transaction
from .utils import logged_user_headers


@pytest.mark.usefixtures("client_class", "temporary_transaction")
class TestUsersLogin:
    @pytest.fixture
    def user(self, app):
        id_app = app.config['ID_APP']
        with db.session.begin_nested():
            user = User(groupe=False, active=True, identifiant='user', password='password')
            db.session.add(user)
            application = Application.query.get(id_app)
            profil = ProfilsForApp.query.filter_by(id_application=application.id_application) \
                                        .order_by(ProfilsForApp.id_profil.desc()).first().profil
            right = UserApplicationRight(role=user, id_profil=profil.id_profil, id_application=application.id_application)
            db.session.add(right)
        return user

    @pytest.fixture
    def app_user(self, app, user):
        return AppUser.query.filter_by(id_role=user.id_role, id_application=app.config['ID_APP']).one()


    def test_current_user(self, app, user, app_user):
        with app.test_request_context(headers=logged_user_headers(app_user)):
            app.preprocess_request()
            assert(g.current_user == user)
