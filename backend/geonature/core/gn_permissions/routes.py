'''
Routes of the gn_permissions blueprint
'''

import json

from flask import Blueprint, request, Response, render_template

from geonature.utils.env import DB
from geonature.utils.utilssqlalchemy import json_resp
from geonature.core.gn_commons.models import TModules
from geonature.core.gn_permissions.models import TObjects, CorObjectModule
from geonature.core.gn_permissions import decorators as permissions
from geonature.core.gn_permissions.tools import cruved_scope_for_user_in_module


routes = Blueprint('gn_permissions', __name__)

@routes.route('/cruved', methods=['GET'])
@permissions.check_cruved_scope('R', True)
@json_resp
def get_cruved(info_role):
    """ return the cruved for a user
    
    Params:
        user: (User): the user who ask the route, auto kwargs via @check_cruved_scope
        module_code (str): the code of the requested module - as querystring

    Returns
        - dict of the CRUVED
    """
    params = dict(request.args)

    # get modules
    q = DB.session.query(TModules)
    if 'module_code' in params:
        q = q.filter(TModules.module_code.in_(params['module_code']))
    modules = q.all()

    # for each modules get its cruved
    # then get its related object and their cruved
    modules_with_cruved = []
    for mod in modules:
        mod_as_dict = mod.as_dict()
        # get mod objects
        module_objects = DB.session.query(TObjects).join(
            CorObjectModule, CorObjectModule.id_object == TObjects.id_object
        ).filter_by(id_module=mod_as_dict['id_module']).all()

        module_cruved, herited = cruved_scope_for_user_in_module(
                id_role=info_role.id_role,
                module_code=mod_as_dict['module_code'],
            )
        mod_as_dict['cruved'] = module_cruved

        module_objects_as_dict = {}
        # get cruved for each object
        for _object in module_objects:
            object_as_dict = _object.as_dict()
            object_cruved, herited = cruved_scope_for_user_in_module(
                id_role=info_role.id_role,
                module_code=mod_as_dict['module_code'],
                object_code=_object.code_object
            )
            object_as_dict['cruved'] = object_cruved
            module_objects_as_dict[object_as_dict['code_object']] = object_as_dict

            mod_as_dict['module_objects'] = module_objects_as_dict

        modules_with_cruved.append(mod_as_dict)

    return modules_with_cruved


