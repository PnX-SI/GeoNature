from flask import Blueprint, current_app, session

from geonature.utils.utilssqlalchemy import json_resp
from geonature.utils.env import get_id_module

# import des fonctions utiles depuis le sous-module d'authentification
from pypnusershub import routes as fnauth
from pypnusershub.db.tools import get_or_fetch_user_cruved

blueprint = Blueprint('<MY_MODULE_NAME>', __name__)

# Récupérer l'ID du module
ID_MODULE = get_id_module(current_app, '<MY_MODULE_NAME>')


# Exemple d'une route simple
@blueprint.route('/test', methods=['GET'])
@json_resp
def get_view():
    q = DB.session.query(MySQLAModel)
    data = q.all()
    return [d.as_dict() for d in data]


# Exemple d'une route protégée le CRUVED du sous module d'authentification
@blueprint.route('/test_cruved', methods=['GET'])
@fnauth.check_auth_cruved('R', True, id_app=ID_MODULE)
@json_resp
def get_sensitive_view(info_role):
    # Récupérer l'id de l'utilisateur qui demande la route
    id_role = info_role.id_role
    # Récupérer la portée autorisée à l'utilisateur pour l'acton 'R' (read)
    read_scope = info_role.tag_object_code

    #récupérer le CRUVED complet de l'utilisateur courant
    user_cruved = get_or_fetch_user_cruved(
        session=session,
        id_role=info_role.id_role,
        id_application=ID_MODULE,
        id_application_parent=current_app.config['ID_APPLICATION_GEONATURE']
    )
    q = DB.session.query(MySQLAModel)
    data = q.all()
    return [d.as_dict() for d in data]