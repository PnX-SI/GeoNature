'''
Routes of the gn_permissions blueprint
'''

import json

from flask import Blueprint, request, Response, render_template

from geonature.utils.env import DB
from geonature.core.gn_permissions import decorators as permissions
from geonature.core.gn_permissions.tools import cruved_scope_for_user_in_module
from geonature.core.gn_permissions.forms import CruvedScope
from geonature.core.gn_permissions.models import TFilters, BibFiltersType

routes = Blueprint('gn_permissions', __name__, template_folder='templates')

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
    )
    return Response(json.dumps(cruved), 200)

@routes.route('', methods=["POST", "GET"])
def permission_form():
    form = CruvedScope()
    filters_scope = DB.session.query(TFilters.id_filter, TFilters.description_filter).join(
        BibFiltersType,BibFiltersType.id_filter_type == TFilters.id_filter_type
    ).filter(
        BibFiltersType.code_filter_type == 'SCOPE'
    ).all()

    form.create_scope.choices = filters_scope
    form.read_scope.choices = filters_scope
    form.update_scope.choices = filters_scope
    form.validate_scope.choices = filters_scope
    form.export_scope.choices = filters_scope
    form.delete_scope.choices = filters_scope


    return render_template('cruved_scope_form.html',form=form)   
