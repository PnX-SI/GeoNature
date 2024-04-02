import requests
from flask import request
from werkzeug.exceptions import HTTPException
from sqlalchemy import select

from geonature.utils.env import db
from pypnusershub.auth import Authentication
from pypnusershub.db.models import User


class ExternalGNAuthProvider(Authentication):
    def __init__(self, base_url, id_group):
        super().__init__("gn_ecrins")
        self.base_url = base_url
        self.id_group = id_group

    def authenticate(self):
        params = request.json
        print(self.base_url)
        url = self.base_url + "/api/auth/login"
        login_response = requests.post(
            url,
            json={"login": params.get("login"), "password": params.get("password")},
        )
        if login_response.status_code != 200:
            raise HTTPException("Fail connect")
        return self._get_or_create_user(login_response.json()["user"])

    def _get_or_create_user(self, user):
        db_user = db.session.execute(
            select(User).where(User.identifiant == user["identifiant"])
        ).scalar_one_or_none()
        group = db.session.get(User, self.id_group)
        if not db_user:
            new_user = User(
                identifiant=user["identifiant"],
                nom_role=user["nom_role"],
                prenom_role=user["prenom_role"],
                groups=[group],
            )
            db.session.add(new_user)
            db.session.commit()
            return new_user

        return db_user

    def revoke(self):
        pass
