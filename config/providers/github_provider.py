from typing import Union

from authlib.integrations.flask_client import OAuth
from flask import (
    Response,
    current_app,
    url_for,
)
from pypnusershub.auth import Authentication
from pypnusershub.db import models, db
from pypnusershub.routes import insert_or_update_role


oauth = OAuth(current_app)
oauth.register(
    name="github",
    client_id="",
    client_secret="",
    access_token_url="https://github.com/login/oauth/access_token",
    access_token_params=None,
    authorize_url="https://github.com/login/oauth/authorize",
    authorize_params=None,
    api_base_url="https://api.github.com/",
    client_kwargs={"scope": "user:email"},
)


class GitHubAuthProvider(Authentication):
    id_provider = "github"
    label = "GitHub"
    is_uh = False
    login_url = "http://127.0.0.1:8000/auth/login/github"
    logout_url = ""
    logo = '<i class="fa fa-github"></i>'

    def authenticate(self, *args, **kwargs) -> Union[Response, models.User]:
        redirect_uri = url_for("auth.authorize", provider=self.id_provider, _external=True)
        return oauth.github.authorize_redirect(redirect_uri)

    def authorize(self):
        token = oauth.github.authorize_access_token()
        resp = oauth.github.get("user", token=token)
        resp.raise_for_status()
        user_info = resp.json()
        prenom = user_info["name"].split(" ")[0]
        nom = " ".join(user_info["name"].split(" ")[1:])
        new_user = {
            "identifiant": f"{user_info['login'].lower()}",
            "email": user_info["email"],
            "prenom_role": prenom,
            "nom_role": nom,
            "active": True,
            "provider": "github",
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
    GitHubAuthProvider,
]
