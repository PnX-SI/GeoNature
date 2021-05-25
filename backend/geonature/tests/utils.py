from flask import url_for


def login(client, username='admin', password=None):
    data = {
        "login": username,
        "password": password if password else username,
        "id_application": client.application.config["ID_APPLICATION_GEONATURE"],
    }
    response = client.post(url_for("auth.login"), json=data)
    assert response.status_code == 200
