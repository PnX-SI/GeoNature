from itertools import groupby, permutations

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
    return (
        Permission.query.join(Permission.module)
        .join(Permission.object)
        .join(Permission.action)
        .filter(
            sa.or_(
                # direct permissions
                Permission.id_role == id_role,
                # permissions through group
                Permission.role.has(User.members.any(User.id_role == id_role)),
            ),
        )
        # remove duplicate permissions (defined at group and user level, or defined in several groups)
        .order_by(Permission.id_module, Permission.id_object, Permission.id_action)
        .distinct(
            Permission.id_module,
            Permission.id_object,
            Permission.id_action,
            *Permission.filters_fields.values(),
        )
        .all()
    )


def get_user_permissions(id_role=None):
    if id_role is None:
        id_role = g.current_user.id_role
    if id_role not in g._permissions_by_user:
        g._permissions_by_user[id_role] = _get_user_permissions(id_role)
    return g._permissions_by_user[id_role]


def _get_permissions(id_role, module_code, object_code, action_code):
    permissions = {
        p
        for p in get_user_permissions(id_role)
        if p.module.module_code == module_code
        and p.object.code_object == object_code
        and p.action.code_action == action_code
    }

    # Remove all permissions supersed by another permission
    for p1, p2 in permutations(permissions, 2):
        if p1 in permissions and p1 <= p2:
            permissions.remove(p1)

    return permissions


def get_permissions(action_code, id_role=None, module_code=None, object_code=None):
    """
    This function returns a set of all the permissions that match (action_code, id_role, module_code, object_code).
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

    ident = (id_role, module_code, object_code, action_code)
    if ident not in g._permissions:
        g._permissions[ident] = _get_permissions(*ident)
    return g._permissions[ident]


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
