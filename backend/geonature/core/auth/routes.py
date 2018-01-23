
"""
    Module d'identificiation provisoire pour test du CAS INPN
"""

import datetime
import xmltodict

from flask import (
    Blueprint, request, make_response,
    redirect, current_app, jsonify
)

from itsdangerous import TimedJSONWebSignatureSerializer as Serializer

from geonature.utils.env import DB

from ..gn_meta import routes as gn_meta
from ..users import routes as users
from ...utils.utilssqlalchemy import json_resp
from ...utils import utilsrequests


routes = Blueprint('auth_cas', __name__)


@routes.route('/login', methods=['GET', 'POST'])
def loginCas():
    config_cas = current_app.config['CAS']
    params = request.args
    if 'ticket' in params:
        base_url = current_app.config['API_ENDPOINT'] + "/auth_cas/login"
        url_validate = "{url}?ticket={ticket}&service={service}".format(
            url=config_cas['CAS_URL_VALIDATION'],
            ticket=params['ticket'],
            service=base_url
        )

        response = utilsrequests.get(url_validate)
        user = None
        xml_dict = xmltodict.parse(response.content)
        resp = xml_dict['cas:serviceResponse']
        if 'cas:authenticationSuccess' in resp:
            user = resp['cas:authenticationSuccess']['cas:user']
        if user:
            ws_user_url = "{}/{}/?verify=false".format(
                config_cas['USER_WS']['URL'], user
            )

            response = utilsrequests.get(
                ws_user_url,
                (
                    config_cas['USER_WS']['ID'],
                    config_cas['USER_WS']['PASSWORD']
                )
            )

            info_user = response.json()
            organism_id = info_user['codeOrganisme']

            if info_user['libelleLongOrganisme'] is not None:
                organism_name = info_user['libelleLongOrganisme']
            else:
                organism_name = 'Autre'

            user_login = info_user['login']
            user_id = info_user['id']
            try:
                assert user_id is not None or user_login is not None
            except AssertionError:
                return 'CAS ERROR: no ID or LOGIN provided'
                raise
            # Reconciliation avec base GeoNature
            if organism_id:
                organism = {
                    "id_organisme": organism_id,
                    "nom_organisme": organism_name
                }
                resp = users.insertOrganism(organism)

            user = {
                "id_role": user_id,
                "identifiant": user_login,
                "nom_role": info_user['nom'],
                "prenom_role": info_user['prenom'],
                "id_organisme": organism_id,
            }
            resp = users.insertRole(user)
            # push the user in the right group
            if organism_id is None:
                # group socle 1
                users.insert_in_cor_role(20003, user['id_role'])
            else:
                # group socle 2
                users.insert_in_cor_role(20001, user['id_role'])
            user["id_application"] = current_app.config['ID_APPLICATION_GEONATURE']

            # Creation of datasets
            gn_meta.post_jdd_from_user_id(user_id, organism_id)

            # creation de la Response
            response = make_response(redirect(current_app.config['URL_APPLICATION']))
            cookie_exp = datetime.datetime.utcnow()
            expiration = current_app.config['COOKIE_EXPIRATION']
            cookie_exp += datetime.timedelta(seconds=expiration)
            # generation d'un token
            s = Serializer(current_app.config['SECRET_KEY'], expiration)
            token = s.dumps(user)
            response.set_cookie('token',
                                token,
                                expires=cookie_exp)
            # User cookie

            current_user = {
                'userName': user_login,
                'user_id': user_id,
                'organism_id': organism_id if organism_id else -1
            }
            response.set_cookie(
                'current_user',
                str(current_user),
                expires=cookie_exp
            )
            return response
        else:
            # redirect to inpn sss
            return """<p> Echec de l'authentification. <p>
             <p> Deconnectez-vous du service INPN avant de retenter une connexion à GeoNature </p>
             <p> <a target="_blank" href="""+current_app.config['CAS']['CAS_URL_LOGOUT']+"""> Deconnexion </a> </p>
             <p> <a target="_blank" href="""+current_app.config['URL_APPLICATION']+"""> Retour vers GeoNature </a> </p>
             """
    return jsonify({'message': 'Authentification error'}, 500)
