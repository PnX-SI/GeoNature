'''
    Route permettant de manipuler les fichiers
    contenus dans gn_media
'''

from flask import Blueprint, request, current_app

from geonature.core.gn_commons.repositories import TMediaRepository
from geonature.core.gn_commons.models import TModules, TParameters
from geonature.utils.env import DB
from geonature.utils.utilssqlalchemy import json_resp
from pypnusershub import routes as fnauth
from pypnusershub.db.tools import cruved_for_user_in_app

routes = Blueprint('gn_commons', __name__)


@routes.route('/modules', methods=['GET'])
@fnauth.check_auth_cruved('R', True)
@json_resp
def get_modules(info_role):
    '''
    Return the allowed modules of user from its cruved
    '''
    modules = DB.session.query(TModules).all()
    allowed_modules = []
    for mod in modules:
        app_cruved = cruved_for_user_in_app(
            id_role=info_role.id_role,
            id_application=mod.id_module,
            id_application_parent=current_app.config['ID_APPLICATION_GEONATURE']
        )
        if app_cruved['R'] != '0':
            module = mod.as_dict()
            module['cruved'] = app_cruved
            if mod.active_frontend:
                module['module_url'] = '{}/#/{}'.format(
                    current_app.config['URL_APPLICATION'],
                    mod.module_path
                )
            else:
                module['module_url'] = mod.module_external_url
            allowed_modules.append(module)
    return allowed_modules


@routes.route('/media/<int:id_media>', methods=['GET'])
@json_resp
def get_media(id_media):
    '''
        Retourne un media
    '''
    m = TMediaRepository(id_media=id_media).media
    if m:
        return m.as_dict()


@routes.route('/media', methods=['POST', 'PUT'])
@routes.route('/media/<int:id_media>', methods=['POST', 'PUT'])
@json_resp
def insert_or_update_media(id_media=None):
    '''
        Insertion ou mise à jour d'un média
        avec prise en compte des fichiers joints
    '''
    if request.files:
        file = request.files['file']
    else:
        file = None

    data = {}
    if request.form:
        formData = dict(request.form)
        for key in formData:
            data[key] = formData[key][0]
    else:
        data = request.get_json(silent=True)

    m = TMediaRepository(
        data=data, file=file, id_media=id_media
    ).create_or_update_media()
    return m.as_dict()


@routes.route('/media/<int:id_media>', methods=['DELETE'])
@json_resp
def delete_media(id_media):
    '''
        Suppression d'un media
    '''
    TMediaRepository(id_media=id_media).delete()
    return {"resp": "media {} deleted".format(id_media)}


# Parameters

@routes.route('/list/parameters', methods=['GET'])
@json_resp
def get_parameters_list():
    q = DB.session.query(TParameters)
    data = q.all()

    return [d.as_dict() for d in data]


@routes.route('/parameters/<param_name>', methods=['GET'])
@routes.route('/parameters/<param_name>/<int:id_org>', methods=['GET'])
@json_resp
def get_one_parameter(param_name, id_org=None):
    q = DB.session.query(TParameters)
    q = q.filter(TParameters.parameter_name == param_name)
    if id_org:
        q = q.filter(TParameters.id_organism == id_org)

    data = q.all()
    return [d.as_dict() for d in data]
