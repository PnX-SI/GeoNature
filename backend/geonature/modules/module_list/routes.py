import os
import toml
from flask import Blueprint

from geonature.utils.env import DB
from geonature.utils.utilssqlalchemy import json_resp
from geonature.core.users.models import TApplications
from pypnusershub import routes as fnauth

routes = Blueprint('gn_modules', __name__)


def get_mods_enabled():
    mod_list = []
    for root, dirs, files in os.walk("/etc/geonature/mods-enabled"):
        for name in dirs:
            mod_manifest = os.path.join(root, name) + '/manifest.toml'
            toml_config = toml.load(str(mod_manifest))
            temp = {}
            temp['module_name'] = toml_config['module_name']
            temp['mod_label_name'] = toml_config['module_label_name']
            mod_list.append(temp)
    return mod_list


@routes.route('/module_list', methods=['GET'])
@fnauth.check_auth_cruved('R', True)
@json_resp
def get_mod_list(info_role):
    #TODO rajouter le cruved
    all_apps = DB.session.query(TApplications).all()
    mod_with_cruved = []
    for app in all_apps:
        for mod in get_mods_enabled():
            if mod['module_name'] == app.nom_application:
                user_cruved = fnauth.get_cruved(
                    user.id_role,
                    app.id_application
                )
                # TODO: n'afficher que si R >=1
                mod['cruved'] = user_cruved
                mod_with_cruved.append(mod)
    return mod_with_cruved