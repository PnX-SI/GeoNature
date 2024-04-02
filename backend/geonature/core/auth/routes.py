"""
    Module d'identificiation provisoire pour test du CAS INPN
"""

import datetime
import xmltodict
import logging
from copy import copy


from flask import (
    Blueprint,
    request,
    make_response,
    redirect,
    current_app,
    jsonify,
    render_template,
    session,
    Response,
)
from flask_login import login_user
import sqlalchemy as sa
from sqlalchemy import select
from utils_flask_sqla.response import json_resp

from pypnusershub.db import models
from pypnusershub.db.models import User, Organisme, Application
from pypnusershub.db.tools import encode_token
from pypnusershub.routes import insert_or_update_organism, insert_or_update_role
from geonature.utils import utilsrequests
from geonature.utils.errors import CasAuthentificationError
from geonature.utils.env import db


routes = Blueprint("gn_auth", __name__, template_folder="templates")
log = logging.getLogger()


@routes.route("/providers", methods=["GET"])
def get_providers():
    property_name = ["id_provider", "is_geonature", "logo", "label", "login_url"]
    return [
        {getattr(provider, _property) for _property in property_name}
        for _, provider in current_app.auth_manager.provider_authentication_cls.items()
    ]
    return list(current_app.auth_manager.provider_authentication_cls.keys())


def get_user_from_id_inpn_ws(id_user):
    URL = f"https://inpn.mnhn.fr/authentication/rechercheParId/{id_user}"
    config_cas = current_app.config["CAS"]
    try:
        response = utilsrequests.get(
            URL,
            (
                config_cas["CAS_USER_WS"]["ID"],
                config_cas["CAS_USER_WS"]["PASSWORD"],
            ),
        )
        assert response.status_code == 200
        return response.json()
    except AssertionError:
        log.error("Error with the inpn authentification service")


def insert_user_and_org(info_user, update_user_organism: bool = True):
    organism_id = info_user["codeOrganisme"]
    organism_name = info_user.get("libelleLongOrganisme", "Autre")
    user_login = info_user["login"]
    user_id = info_user["id"]

    try:
        assert user_id is not None and user_login is not None
    except AssertionError:
        log.error("'CAS ERROR: no ID or LOGIN provided'")
        raise CasAuthentificationError("CAS ERROR: no ID or LOGIN provided", status_code=500)

    # Reconciliation avec base GeoNature
    if organism_id:
        organism = {"id_organisme": organism_id, "nom_organisme": organism_name}
        insert_or_update_organism(organism)

    # Retrieve user information from `info_user`
    user_info = {
        "id_role": user_id,
        "identifiant": user_login,
        "nom_role": info_user["nom"],
        "prenom_role": info_user["prenom"],
        "id_organisme": organism_id,
        "email": info_user["email"],
        "active": True,
    }

    # If not updating user organism and user already exists, retrieve existing user organism information rather than information from `info_user`
    existing_user = User.query.get(user_id)
    if not update_user_organism and existing_user:
        user_info["id_organisme"] = existing_user.id_organisme

    # Insert or update user
    user_info = insert_or_update_role(user_info)

    # Associate user to a default group if the user is not associated to any group
    user = existing_user or db.session.get(User, user_id)
    if not user.groups:
        if current_app.config["CAS"]["USERS_CAN_SEE_ORGANISM_DATA"] and organism_id:
            # group socle 2 - for a user associated to an organism if users can see data from their organism
            group_id = current_app.config["BDD"]["ID_USER_SOCLE_2"]
        else:
            # group socle 1
            group_id = current_app.config["BDD"]["ID_USER_SOCLE_1"]
        group = db.session.get(User, group_id)
        user.groups.append(group)

    return user_info
