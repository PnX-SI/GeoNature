'''
Routes of the gn_permissions blueprint
'''

import json

from flask import Blueprint, request, Response, render_template

from geonature.utils.env import DB
from geonature.core.gn_permissions import decorators as permissions
from geonature.core.gn_permissions.tools import cruved_scope_for_user_in_module


routes = Blueprint('gn_permissions', __name__)

@routes.route('/cruved', methods=['GET'])
@permissions.check_cruved_scope('R', True)
def get_cruved(info_role):
    """ return the cruved for a user
    
    Params:
        user: (User): the user who ask the route, auto kwargs via @check_cruved_scope

    Returns
        - dict of the CRUVED
    """
    cruved = cruved_scope_for_user_in_module(
        id_role=info_role.id_role,
        module_code=request.args.get('module_code', None),
    )[0]
    return Response(json.dumps(cruved), 200)


