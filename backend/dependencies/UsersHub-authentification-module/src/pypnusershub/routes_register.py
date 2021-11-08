# coding: utf8
# Fichier contenant les route pour faire des appels à UsersHub
#
# - en se connectant en tant que qu'adminisatrateur de l'application courante
# --  qui est utilisateur de USERSHUB avec des droits suffisants pour creer des utilisateurs
# --  pour cela il faut renseigner dans la configuration
# --
#
# - pour creer des nouveaux utilisateurs
#
# - pour changer les mots de passe
#
# - pour éditer les droits des utilisateurs
#
# - etc..

import json

import requests

from flask import (
    Blueprint,
    request,
    session,
)

from functools import wraps

from .db.models import Application, UserApplicationRight, AppUser, db
from .env import REGISTER_POST_ACTION_FCT

from flask import current_app

# from .utils_register import connect_usershub, req_json_or_text
# from .routes import check_auth


s = requests.Session()

bp = Blueprint('register', __name__)


def get_json_request(r):
    '''
        r : retour de la requete requests

        fonction pour recuperer la reponse json sans lever d'erreur
    '''
    try:
        r_json = r.json()
    except Exception:
        r_json = None

    return r_json


def req_json_or_text(r, msg_pypn=""):
    '''
        r : retour de la requete requests
        msg_pypn : message supplementaire rajouté a la reponse

        revoie un tuple avec la réponse de la requete en json r.json si possible
        {'msg': r.text} sinon
        et status_code


    '''
    r_json = get_json_request(r)

    if not r_json and r.text:

        r_json = {"msg": r.text}

    if not r_json and not r.text:

        r_json = {"msg": "empty message"}

    if msg_pypn:

        r_json['msg_pypn'] = msg_pypn

    return json.dumps(r_json), r.status_code


def connect_admin():
    '''
        decorateur pour la connexion de l'admin a une appli
        ici url config['URL_USERSHUB'] sans / à la fin
    '''
    def _connect_admin(f):
        @wraps(f)
        def __connect_admin(*args, **kwargs):
            # connexion à usershub
            id_app_usershub = db.session.query(
                Application.id_application
            ).filter(Application.code_application == 'UH').first()

            if not id_app_usershub:
                return json.dumps({"msg": "Pas d'id app USERSHUB"}), 500

            id_app_usershub = id_app_usershub[0]

            # test si on est déjà connecté
            try:
                r = s.post(current_app.config['URL_USERSHUB'] +
                           "/api_register/test_connexion")
                b_connexion = (r.status_code == 200)
            except requests.ConnectionError:
                return json.dumps({"msg": "Erreur de connexion a l'application USERSHUB (causes possibles : url erronee, application USERSHUB ne fonctionne pas, ..;)"}), 500

            # si on est pas connecté on se connecte
            if not b_connexion:
                # connexion à usershub
                r = s.post(
                    current_app.config['URL_USERSHUB'] + "/" + "pypn/auth/login",
                    json={
                        'login': current_app.config['ADMIN_APPLICATION_LOGIN'],
                        'password': current_app.config['ADMIN_APPLICATION_PASSWORD'],
                        'id_application': id_app_usershub
                    }
                )

            # si echec de connexion
            if r.status_code != 200:
                return req_json_or_text(r, "Problème de connexion à UsersHub")

            return f(*args, **kwargs)

        return __connect_admin

    return _connect_admin


@bp.route('test_uh', methods=['GET'])
@connect_admin()
def test():
    '''
        route pour tester le décorateur connect_admin
        ainsi que les paramètres de connexion à USERSHUB:
            - config['ADMIN_APPLICATION_LOGIN']
            - config['ADMIN_APPLICATION_PASSWORD']
    '''

    r = s.post(current_app.config['URL_USERSHUB'] + "/api_register/test_connexion")

    return req_json_or_text(r, "Test pypn")


@bp.route("post_usershub/<string:type_action>", methods=['POST'])
@connect_admin()
def post_usershub(type_action):
    '''
        route generique pour appeler les routes UsersHub en tant qu'administrateur de l'appli en cours
        ex : post_usershub/test_connexion appelle la route URL_USERSHUB/api_register/test_connexion
    '''
    # attribution des droits pour les actions
    dict_type_action_droit = {
        'test_connexion': 0,
        'valid_temp_user': 0,
        'create_temp_user': 0,
        'change_password': 0,
        'create_cor_role_token': 0,
        'add_application_right_to_role': 0,
        'login_recovery': 0,
        'password_recovery': 0,
        'update_user': 1,
        'change_application_right': 4,
    }
    params = request.args
    id_droit = 0

    if session.get('current_user', None):

        id_role = session['current_user']['id_role']

        q = (db.session.query(AppUser.id_droit_max)
             .filter(AppUser.id_role == id_role)
             .filter(AppUser.id_application == current_app.config['ID_APP']))
        id_droit = q.one()[0]

    # si pas de droit definis pour cet action, alors les droits requis sont à 7 => action impossible
    if id_droit < dict_type_action_droit.get(type_action, 7):

        return json.dumps({"msg": "Droits insuffisant pour la requête UsersHub : " + type_action}), 403

    # les test de paramètres seront faits dans UsersHub
    data = request.get_json()
    url = current_app.config['URL_USERSHUB'] + "/" + "api_register/" + type_action
    r_usershub = s.post(url, json=data)

    # after request definir route dans app
    # par ex. pour l'envoi de mails
    # lancer uniquement si enable_post_action n'est pas = False dans le body de la requête
    if r_usershub.status_code == 200 and data.get('enable_post_action', True):
        out_after = after_request(type_action, get_json_request(r_usershub))

        # 0 = pas d'action definie dans current_app.config['after_USERSHUB_request'][type_action]
        if out_after != 0:

            if out_after['msg'] != "ok":

                return json.dumps({'msg': 'Problème after request pour post_usershub ' + type_action + ':' + out_after['msg']}), 500

    return req_json_or_text(r_usershub)


def after_request(type_action, data, *args, **kwargs):
    '''
        lorsqu'une fonction est definie dans REGISTER_POST_ACTION_FCT[type_action]
        elle est executée avec les données fournies en retour de la requete USERSHUB
    '''
    if not REGISTER_POST_ACTION_FCT:
        return 0
    f = REGISTER_POST_ACTION_FCT.get(type_action, None)

    if not f:
        return 0
    return f(data)
