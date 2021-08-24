import json

from flask import url_for, current_app
from werkzeug.http import dump_cookie

from pypnusershub.db.tools import user_to_token


def login(client, username='admin', password=None):
    data = {
        "login": username,
        "password": password if password else username,
        "id_application": client.application.config["ID_APPLICATION_GEONATURE"],
    }
    response = client.post(url_for("auth.login"), json=data)
    assert response.status_code == 200


def post_json(client, url, json_dict, query_string=None):
    """Send dictionary json_dict as a json to the specified url """
    return client.post(
        url,
        data=json.dumps(json_dict),
        content_type="application/json",
        query_string=query_string,
    )


def logged_user_headers(user, headers={}):
    cookie = dump_cookie('token', user_to_token(user))
    headers.update({
        'COOKIE': cookie,
    })
    return headers
