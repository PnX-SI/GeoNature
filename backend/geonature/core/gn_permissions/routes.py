"""
Routes of the gn_permissions blueprint
"""

from copy import copy

from flask import Blueprint, Response, session
from geonature.core.gn_commons.models.base import TModules
import sqlalchemy as sa

from geonature.utils.env import db
from sqlalchemy.exc import NoResultFound
from sqlalchemy.orm import joinedload
from geonature.core.gn_permissions.models import PermAction, PermissionAvailable, TObjects
from geonature.core.gn_permissions.schemas import PermissionAvailableSchema
from geonature.core.gn_permissions.decorators import login_required
from geonature.core.gn_permissions.commands import supergrant
from werkzeug.exceptions import NotFound


routes = Blueprint(
    "gn_permissions", __name__, cli_group="permissions", template_folder="./templates"
)

routes.cli.add_command(supergrant)


# @TODO delete
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


@routes.route("/availables", methods=["GET"])
@login_required
def list_permissions_availables():
    pa = db.session.execute(sa.select(PermissionAvailable)).scalars()
    schema = PermissionAvailableSchema(only=["action", "module", "object"])
    return schema.dump(pa, many=True)


@routes.route("/availables/<module_code>/<code_object>/<code_action>", methods=["GET"])
@login_required
def get_permission_available(module_code, code_object, code_action):
    try:
        pa = db.session.execute(
            sa.select(PermissionAvailable).where(
                PermissionAvailable.module.has(TModules.module_code == module_code),
                PermissionAvailable.object.has(TObjects.code_object == code_object),
                PermissionAvailable.action.has(PermAction.code_action == code_action),
            )
        ).scalar_one()
    except NoResultFound:
        raise NotFound
    schema = PermissionAvailableSchema(only=["action", "module", "object"])
    return schema.dump(pa)
