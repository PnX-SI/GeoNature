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
from sqlalchemy import select
from utils_flask_sqla.response import json_resp

from pypnusershub.db.models import User, Organisme, Application
from pypnusershub.db.tools import encode_token
from pypnusershub.routes import insert_or_update_organism, insert_or_update_role
from geonature.utils import utilsrequests
from geonature.utils.errors import CasAuthentificationError
from geonature.utils.env import db


routes = Blueprint("gn_auth", __name__, template_folder="templates")
log = logging.getLogger()


@routes.route("/login_cas", methods=["GET", "POST"])
def loginCas():
    """
    Login route with the INPN CAS

    .. :quickref: User;
    """
    config_cas = current_app.config["CAS"]
    params = request.args
    if "ticket" in params:
        base_url = current_app.config["API_ENDPOINT"] + "/gn_auth/login_cas"
        url_validate = "{url}?ticket={ticket}&service={service}".format(
            url=config_cas["CAS_URL_VALIDATION"],
            ticket=params["ticket"],
            service=base_url,
        )

        response = utilsrequests.get(url_validate)
        data = None
        xml_dict = xmltodict.parse(response.content)
        resp = xml_dict["cas:serviceResponse"]
        if "cas:authenticationSuccess" in resp:
            data = resp["cas:authenticationSuccess"]["cas:user"]
        if data:
            ws_user_url = "{url}/{user}/?verify=false".format(
                url=config_cas["CAS_USER_WS"]["URL"], user=data
            )
            try:
                response = utilsrequests.get(
                    ws_user_url,
                    (
                        config_cas["CAS_USER_WS"]["ID"],
                        config_cas["CAS_USER_WS"]["PASSWORD"],
                    ),
                )
                assert response.status_code == 200
            except AssertionError:
                log.error("Error with the inpn authentification service")
                raise CasAuthentificationError(
                    "Error with the inpn authentification service", status_code=500
                )
            info_user = response.json()
            data = insert_user_and_org(info_user, update_user_organism=False)
            db.session.commit()

            # creation de la Response
            response = make_response(redirect(current_app.config["URL_APPLICATION"]))
            cookie_exp = datetime.datetime.utcnow()
            expiration = current_app.config["COOKIE_EXPIRATION"]
            cookie_exp += datetime.timedelta(seconds=expiration)
            data["id_application"] = (
                db.session.execute(
                    select(Application).filter_by(
                        code_application=current_app.config["CODE_APPLICATION"]
                    )
                )
                .scalar_one()
                .id_application
            )
            token = encode_token(data)
            response.set_cookie("token", token, expires=cookie_exp)

            # User cookie
            organism_id = info_user["codeOrganisme"]
            if not organism_id:
                organism_id = (
                    db.session.execute(
                        select(Organisme).filter_by(nom_organisme="Autre"),
                    )
                    .scalar_one()
                    .id_organisme,
                )
            current_user = {
                "user_login": data["identifiant"],
                "id_role": data["id_role"],
                "id_organisme": organism_id,
            }
            response.set_cookie("current_user", str(current_user), expires=cookie_exp)
            return response
        else:
            log.info("Erreur d'authentification lié au CAS, voir log du CAS")
            log.error("Erreur d'authentification lié au CAS, voir log du CAS")
            return render_template(
                "cas_login_error.html",
                cas_logout=current_app.config["CAS_PUBLIC"]["CAS_URL_LOGOUT"],
                url_geonature=current_app.config["URL_APPLICATION"],
            )
    return jsonify({"message": "Authentification error"}, 500)


@routes.route("/logout_cruved", methods=["GET"])
@json_resp
def logout_cruved():
    """
    Route to logout with cruved
    To avoid multiples server call, we store the cruved in the session
    when the user logout we need clear the session to get the new cruved session

    .. :quickref: User;
    """
    copy_session_key = copy(session)
    for key in copy_session_key:
        session.pop(key)
    return "Logout", 200


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
