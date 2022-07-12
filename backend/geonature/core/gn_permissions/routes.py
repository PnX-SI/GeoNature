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
