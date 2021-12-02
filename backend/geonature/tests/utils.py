import json

from flask import url_for, current_app
from werkzeug.http import dump_cookie
from werkzeug.datastructures import Headers

from pypnusershub.db.models import AppUser
from pypnusershub.db.tools import user_to_token


def login(client, username='admin', password=None):
    data = {
        "login": username,
        "password": password if password else username,
        "id_application": client.application.config["ID_APPLICATION_GEONATURE"],
    }
    response = client.post(url_for("auth.login"), json=data)
    assert response.status_code == 200


def set_logged_user_cookie(client, user):
    app_user = AppUser.query.filter_by(
                                id_role=user.id_role,
                                id_application=current_app.config['ID_APP'],
    ).one()
    client.set_cookie('*', 'token', user_to_token(app_user))


def logged_user_headers(user, headers=Headers()):
    app_user = AppUser.query.filter_by(
                                id_role=user.id_role,
                                id_application=current_app.config['ID_APP'],
    ).one()
    cookie = dump_cookie('token', user_to_token(app_user))
    headers.extend({
        'Cookie': cookie,
    })
    return headers
