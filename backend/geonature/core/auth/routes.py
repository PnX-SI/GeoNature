
"""
    Module d'identificiation provisoire pour test du CAS INPN
"""

import datetime
import xmltodict
import logging

from flask import (
    Blueprint, request, make_response,
    redirect, current_app, jsonify, render_template
)
from itsdangerous import TimedJSONWebSignatureSerializer as Serializer

from geonature.core.users import routes as users
from geonature.utils import utilsrequests
from geonature.utils.errors import CasAuthentificationError


routes = Blueprint('auth_cas', __name__, template_folder="templates")
log = logging.getLogger()
gunicorn_error_logger = logging.getLogger('gunicorn.error')


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
            ws_user_url = "{url}/{user}/?verify=false".format(
                url=config_cas['CAS_USER_WS']['URL'],
                user=user
            )
            try:
                response = utilsrequests.get(
                    ws_user_url,
                    (
                        config_cas['CAS_USER_WS']['ID'],
                        config_cas['CAS_USER_WS']['PASSWORD']
                    )
                )
                assert response.status_code == 200
            except AssertionError:
                log.error("Error with the inpn authentification service")
                raise CasAuthentificationError(
                    'Error with the inpn authentification service',
                    status_code=500
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
                assert user_id is not None and user_login is not None
            except AssertionError:
                log.error(
                    "'CAS ERROR: no ID or LOGIN provided'"
                )
                raise CasAuthentificationError(
                    'CAS ERROR: no ID or LOGIN provided',
                    status_code=500
                )
            # Reconciliation avec base GeoNature
            if organism_id:
                organism = {
                    "id_organisme": organism_id,
                    "nom_organisme": organism_name
                }
                resp = users.insert_organism(organism)

            user = {
                "id_role": user_id,
                "identifiant": user_login,
                "nom_role": info_user['nom'],
                "prenom_role": info_user['prenom'],
                "id_organisme": organism_id,
            }
            try:
                resp = users.insert_role(user)
            except Exception as e:
                gunicorn_error_logger.info(e)
                log.error(e)
            # push the user in the right group
            try:
                if not current_app.config['CAS']['USERS_CAN_SEE_ORGANISM_DATA']:
                    # group socle 1
                    users.insert_in_cor_role(current_app.config['BDD']['ID_USER_SOCLE_1'], user['id_role'])
                elif organism_id is None:
                    # group socle 1
                    users.insert_in_cor_role(current_app.config['BDD']['ID_USER_SOCLE_1'], user['id_role'])
                else:
                    # group socle 2
                    users.insert_in_cor_role(current_app.config['BDD']['ID_USER_SOCLE_2'], user['id_role'])
                user['id_application'] = current_app.config['ID_APPLICATION_GEONATURE']
            except Exception as e:
                gunicorn_error_logger.info(e)
                log.error(e)

            # creation de la Response
            response = make_response(
                redirect(current_app.config['URL_APPLICATION'])
            )
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
                'user_login': user_login,
                'id_role': user_id,
                'id_organisme': organism_id if organism_id else -1
            }
            response.set_cookie(
                'current_user',
                str(current_user),
                expires=cookie_exp
            )
            return response
        else:
            gunicorn_error_logger.info(
                "Erreur d'authentification lié au CAS, voir log du CAS"
            )
            log.error(
                "Erreur d'authentification lié au CAS, voir log du CAS"
            )
            return render_template(
                'cas_login_error.html',
                cas_logout=current_app.config['CAS_PUBLIC']['CAS_URL_LOGOUT'],
                url_geonature=current_app.config['URL_APPLICATION']
            )
    return jsonify({'message': 'Authentification error'}, 500)
