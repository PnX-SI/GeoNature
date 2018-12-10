from flask import Blueprint, current_app, session

from geonature.utils.utilssqlalchemy import json_resp
from geonature.utils.env import get_id_module

# import des fonctions utiles depuis le sous-module d'authentification
from geonature.core.gn_permissions import decorators as permissions
from geonature.core.gn_permissions.tools import get_or_fetch_user_cruved

blueprint = Blueprint('<MY_MODULE_NAME>', __name__)


# Exemple d'une route simple
@blueprint.route('/test', methods=['GET'])
@json_resp
def get_view():
    q = DB.session.query(MySQLAModel)
    data = q.all()
    return [d.as_dict() for d in data]


# Exemple d'une route protégée le CRUVED du sous module d'authentification
@blueprint.route('/test_cruved', methods=['GET'])
@permissions.check_cruved_scope('R', module_code="MY_MODULE_CODE")
@json_resp
def get_sensitive_view(info_role):
    # Récupérer l'id de l'utilisateur qui demande la route
    id_role = info_role.id_role
    # Récupérer la portée autorisée à l'utilisateur pour l'acton 'R' (read)
    read_scope = info_role.value_filter

    #récupérer le CRUVED complet de l'utilisateur courant
    user_cruved = get_or_fetch_user_cruved(
        session=session,
        id_role=info_role.id_role,
        module_code='MY_MODULE_CODE',
    )
    q = DB.session.query(MySQLAModel)
    data = q.all()
    return [d.as_dict() for d in data]