from itertools import groupby

import sqlalchemy as sa
from sqlalchemy.orm import joinedload
from flask import g

from geonature.core.gn_commons.models import TModules
from geonature.core.gn_permissions.models import (
    PermAction,
    PermObject,
    PermScope,
    Permission,
)
from geonature.utils.env import db

from pypnusershub.db.models import User


def _get_user_permissions(id_role):
    default_module = TModules.query.filter_by(module_code="GEONATURE").one()
    default_object = PermObject.query.filter_by(code_object="ALL").one()
    return (
        Permission.query.options(
            joinedload(Permission.action),
        )
        .filter(
            sa.or_(
                # direct permissions
                Permission.id_role == id_role,
                # permissions through group
                Permission.role.has(User.members.any(User.id_role == id_role)),
            ),
        )
        # These ordering ensure groupby is working properly
        .order_by(Permission.id_action)
        # remove duplicate permissions (defined at group and user level, or defined in several groups)
        .distinct(
            Permission.id_action,
            Permission.id_module,
            Permission.id_object,
            *Permission.filters_fields.values(),
        )
        .all()
    )


def _get_user_permissions_by_action(id_role):
    permissions = _get_user_permissions(id_role)
    # This ensures empty permissions list for action without permissions
    permissions_by_action = {action.code_action: [] for action in PermAction.query.all()}
    # Note: groupby require sorted data, which is done at SQL level
    permissions_by_action.update(
        {
            action_code: list(perms)
            for action_code, perms in groupby(permissions, key=lambda p: p.action.code_action)
        }
    )
    return permissions_by_action


def get_user_permissions_by_action(id_role=None):
    """
    This function add caching to _get_user_permissions_by_action
    and use g.current_user as default role.
    """
    if id_role is None:
        id_role = g.current_user.id_role
    if "permissions_by_action" in g:  # before_request have been called
        if id_role not in g.permissions_by_action:
            g.permissions_by_action[id_role] = _get_user_permissions_by_action(id_role)
        return g.permissions_by_action[id_role]
    else:
        return _get_user_permissions_by_action(id_role)


def get_permissions(action_code, id_role=None, module_code=None, object_code=None):
    """
    This function returns a list of all the permissions that match (action_code, id_role, module_code, object_code).
    If module_code is None, it is set as the code of the current module or as "GEONATURE" if no current module found.
    If object_code is None, it is set as the code of the current object or as "ALL" if no current object found.

    :returns : the list of permissions that match, and an empty list if no match
    """
    if module_code is None:
        if hasattr(g, "current_module"):
            module_code = g.current_module.module_code
        else:
            module_code = "GEONATURE"

    if object_code is None:
        if hasattr(g, "current_object"):
            object_code = g.current_object.code_object
        else:
            object_code = "ALL"

    return [
        p
        for p in get_user_permissions_by_action(id_role)[action_code]
        if p.module.module_code == module_code and p.object.code_object == object_code
    ]


def get_scope(action_code, id_role=None, module_code=None, object_code=None):
    """
    This function gets the final scope permission.

    It takes the maximum for all the permissions that match (action_code, id_role, module_code, object_code) and with
    of a "SCOPE" filter type.

    :returns : (int) The scope computed for specified arguments
    """
    permissions = get_permissions(action_code, id_role, module_code, object_code)
    max_scope = 0
    for permission in permissions:
        if permission.has_other_filters_than("SCOPE"):
            continue
        if permission.scope_value is None:
            max_scope = 3
        else:
            max_scope = max(max_scope, permission.scope_value)
    return max_scope


def get_scopes_by_action(id_role=None, module_code=None, object_code=None):
    """
    This function gets the scopes permissions for each one of the 6 actions in "CRUVED",
    that match (id_role, module_code, object_code)

    :returns : (dict) A dict of the scope for each one of the 6 actions (the char in "CRUVED")
    """
    return {
        action_code: get_scope(action_code, id_role, module_code, object_code)
        for action_code in "CRUVED"
    }
