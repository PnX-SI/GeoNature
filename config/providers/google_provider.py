import os
from typing import Any, Union

from authlib.integrations.flask_client import OAuth
from flask import (
    Response,
    current_app,
    jsonify,
    make_response,
    redirect,
    render_template,
    request,
    url_for,
)
from geonature.core.auth.providers import ExternalGNAuthProvider
from geonature.utils.config import config
from pypnusershub.auth import Authentication
from pypnusershub.db import models, db
from pypnusershub.db.models import User
from pypnusershub.routes import insert_or_update_role
import sqlalchemy as sa

current_app.config["GOOGLE_CLIENT_ID"] = ""

current_app.config["GOOGLE_CLIENT_SECRET"] = ""

oauth = OAuth(current_app)
CONF_URL = "https://accounts.google.com/.well-known/openid-configuration"
oauth.register(
    name="google", server_metadata_url=CONF_URL, client_kwargs={"scope": "openid email profile"}
)


class GoogleAuthProvider(Authentication):
    id_provider = "google"
    label = "Google"
    is_uh = False
    login_url = ""
    logout_url = ""
    logo = '<i class="fa fa-google"></i>'

    def authenticate(self, *args, **kwargs) -> Union[Response, models.User]:
        redirect_uri = url_for("auth.authorize", provider=self.id_provider, _external=True)
        return oauth.google.authorize_redirect(redirect_uri)

    def authorize(self):
        token = oauth.google.authorize_access_token()
        user_info = token["userinfo"]
        new_user = {
            "identifiant": f"{user_info['given_name'].lower()}{user_info['family_name'].lower()}",
            "email": user_info["email"],
            "prenom_role": user_info["given_name"],
            "nom_role": user_info["family_name"],
            "active": True,
            "provider": "google",
        }
        user_info = insert_or_update_role(new_user)
        user = db.session.get(models.User, user_info["id_role"])
        if not user.groups:
            group = db.session.get(models.User, 2)  # ADMIN for test
            user.groups.append(group)
        db.session.commit()
        return user


# Accueil : https://ginco2-preprod.mnhn.fr/ (URL publique) + http://ginco2-preprod.patnat.mnhn.fr/ (URL privée)


AUTHENTICATION_CLASS = [
    GoogleAuthProvider,
]
