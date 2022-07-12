"""
Routes of the gn_permissions blueprint
"""

import json
from copy import copy

from flask import Blueprint, request, Response, render_template, session

from geonature.utils.env import DB
from sqlalchemy.orm import joinedload
from utils_flask_sqla.response import json_resp
from geonature.core.gn_commons.models import TModules
from geonature.core.gn_permissions import decorators as permissions
from geonature.core.gn_permissions.tools import cruved_scope_for_user_in_module


routes = Blueprint("gn_permissions", __name__)


@routes.route("/cruved", methods=["GET"])
@permissions.check_cruved_scope("R", True)
@json_resp
def get_cruved(info_role):
    """
    Get the cruved for a user

    .. :quickref: Permissions;

    Params:
    :param user: the user who ask the route, auto kwargs via @check_cruved_scope
    :type user: User
    :param module_code: the code of the requested module - as querystring
    :type module_code: str

    :returns: dict of the CRUVED
    """
    params = request.args.to_dict()

    # get modules
    q = DB.session.query(TModules).options(joinedload(TModules.objects))
    if "module_code" in params:
        q = q.filter(TModules.module_code == params["module_code"])
    modules = q.all()

    # for each modules get its cruved
    # then get its related object and their cruved
    modules_with_cruved = {}
    for mod in modules:
        mod_as_dict = mod.as_dict(fields=["objects"])
        module_cruved, herited = cruved_scope_for_user_in_module(
            id_role=info_role.id_role,
            module_code=mod_as_dict["module_code"],
        )
        mod_as_dict["cruved"] = module_cruved

        module_objects_as_dict = {}
        # # get cruved for each object
        for _object in mod_as_dict.get("objects", []):
            object_cruved, herited = cruved_scope_for_user_in_module(
                id_role=info_role.id_role,
                module_code=mod_as_dict["module_code"],
                object_code=_object["code_object"],
            )
            _object["cruved"] = object_cruved
            module_objects_as_dict[_object["code_object"]] = _object

            mod_as_dict["module_objects"] = module_objects_as_dict

        modules_with_cruved[mod_as_dict["module_code"]] = mod_as_dict

    return modules_with_cruved


@routes.route("/logout_cruved", methods=["GET"])
def logout():
    """
    Route to logout with cruved

    .. :quickref: Permissions;

    To avoid multiples server call, we store the cruved in the session
    when the user logout we need clear the session to get the new cruved session
    """
    copy_session_key = copy(session)
    for key in copy_session_key:
        session.pop(key)
    return Response("Logout", 200)
