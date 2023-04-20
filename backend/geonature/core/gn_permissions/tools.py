from itertools import groupby

import sqlalchemy as sa
from sqlalchemy.orm import joinedload
from flask import g

from geonature.core.gn_commons.models import TModules
from geonature.core.gn_permissions.models import (
    CorRoleActionFilterModuleObject,
    TFilters,
    TActions,
    TObjects,
)
from geonature.utils.env import db

from pypnusershub.db.models import User


def _get_user_permissions(id_role):
    default_module = TModules.query.filter_by(module_code="GEONATURE").one()
    default_object = TObjects.query.filter_by(code_object="ALL").one()
    return (
        CorRoleActionFilterModuleObject.query.options(
            joinedload(CorRoleActionFilterModuleObject.action),
            joinedload(CorRoleActionFilterModuleObject.filter).joinedload(TFilters.filter_type),
        )
        .filter(
            sa.or_(
                # direct permissions
                CorRoleActionFilterModuleObject.id_role == id_role,
                # permissions through group
                CorRoleActionFilterModuleObject.role.has(
                    User.members.any(User.id_role == id_role)
                ),
            ),
        )
        # These ordering ensure groupby is working properly, as well as allows module / object inheritance
        .order_by(
            CorRoleActionFilterModuleObject.id_action,
            # ensure GEONATURE module is the last
            db.case(
                [
                    (CorRoleActionFilterModuleObject.id_module == default_module.id_module, -1),
                ],
                else_=CorRoleActionFilterModuleObject.id_module,
            ).desc(),
            # ensure ALL object is the last
            db.case(
                [
                    (CorRoleActionFilterModuleObject.id_object == default_object.id_object, -1),
                ],
                else_=CorRoleActionFilterModuleObject.id_object,
            ).desc(),
        )
        .all()
    )


def _get_user_permissions_by_action(id_role):
    permissions = _get_user_permissions(id_role)
    # This ensure empty permissions list for action without permissions
    permissions_by_action = {action.code_action: [] for action in TActions.query.all()}
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
    This function ensure module and object inheritance.
    Permissions have been sorted (which is required for using groupby) by module_code and object_code,
    with insurance GEONATURE module and ALL object are latest.
    We return first list of permissions found.
    """
    if module_code is None and hasattr(g, "current_module"):
        module_code = g.current_module.module_code

    if object_code is None and hasattr(g, "current_object"):
        object_code = g.current_object.code_object

    permissions = get_user_permissions_by_action(id_role)[action_code]
    for _module_code, _permissions in groupby(permissions, key=lambda p: p.module.module_code):
        if _module_code not in [module_code, "GEONATURE"]:
            continue
        for _object_code, __permissions in groupby(
            _permissions, key=lambda p: p.object.code_object
        ):
            if _object_code not in [object_code, "ALL"]:
                continue
            return list(__permissions)
    return []


def get_scope(action_code, id_role=None, module_code=None, object_code=None):
    """
    Note: we filter permissions by scope *after* module / object inheritance.
    This means we get null scope if there are non-scope permissions at module level
    but scope permissions at GEONATURE level.
    If we want to inherite scope without others permissions types considered,
    we should filter non-scope permissions *before* inheritance.
    """
    permissions = get_permissions(action_code, id_role, module_code, object_code)
    max_scope = 0
    for permission in permissions:
        if permission.filter.filter_type.code_filter_type != "SCOPE":
            continue
        max_scope = max(max_scope, int(permission.filter.value_filter))
    return max_scope


def get_scopes_by_action(id_role=None, module_code=None, object_code=None):
    return {
        action_code: get_scope(action_code, id_role, module_code, object_code)
        for action_code in "CRUVED"
    }
