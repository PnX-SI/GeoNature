import logging, json
from itertools import groupby

import sqlalchemy as sa
from sqlalchemy.orm import joinedload
from sqlalchemy.sql.expression import func
from flask import current_app, redirect, Response, g
from werkzeug.exceptions import Forbidden, Unauthorized
from werkzeug.routing import RequestRedirect
from authlib.jose.errors import ExpiredTokenError, JoseError

from geonature.core.gn_commons.models import TModules
from geonature.core.gn_permissions.models import (
    CorRoleActionFilterModuleObject,
    TFilters,
    TActions,
    TObjects,
)
from geonature.utils.env import db, DB

from pypnusershub.db.models import User

log = logging.getLogger(__name__)


def beautifulize_cruved(actions, cruved):
    """
    Build more readable the cruved dict with the actions label
    Params:
        actions: dict action {'C': 'Action de créer'}
        cruved: dict of cruved
    Return:
        Array<dict> [{'label': 'Action de Lire', 'value': '3'}]
    """
    cruved_beautiful = []
    for key, value in cruved.items():
        temp = {}
        temp["label"] = actions.get(key)
        temp["value"] = value
        cruved_beautiful.append(temp)
    return cruved_beautiful


def cruved_scope_for_user_in_module(
    id_role=None,
    module_code=None,
    object_code=None,
    get_id=False,
):
    """
    get the user cruved for a module or object
    if no cruved for a module, the cruved parent module is taken
    Child app cruved alway overright parent module cruved
    Params:
        - id_role(int)
        - module_code(str)
        - object_code(str)
        - get_id(bool): if true return the id_scope for each action
            if false return the filter_value for each action
        - append_to_select (dict) : dict of extra select module object for heritage
    Return a tuple
    - index 0: the cruved as a dict : {'C': 0, 'R': 2 ...}
    - index 1: a boolean which say if its an herited cruved
    """
    cruved = {}
    herited_object = None
    for action_code in "CRUVED":
        permissions, _module_code, _object_code = _get_permissions(
            action_code, id_role, module_code, object_code
        )
        if (_module_code != module_code) or (_object_code != (object_code or "ALL")):
            herited_object = [_module_code, _object_code]
        max_scope = 0
        max_permission = None
        for permission in permissions:
            if permission.filter.filter_type.code_filter_type != "SCOPE":
                continue
            scope = int(permission.filter.value_filter)
            if scope >= max_scope:
                max_scope = scope
                max_permission = permission
        cruved[action_code] = max_permission.filter.id_filter if get_id else str(max_scope)
    return cruved, herited_object is not None, herited_object


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
    if "permissions_by_action" not in g:
        g.permissions_by_action = dict()
    if id_role not in g.permissions_by_action:
        g.permissions_by_action[id_role] = _get_user_permissions_by_action(id_role)
    return g.permissions_by_action[id_role]


def _get_permissions(action_code, id_role, module_code, object_code):
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
            return list(__permissions), _module_code, _object_code
    return [], None, None


def get_permissions(action_code, id_role=None, module_code=None, object_code=None):
    return _get_permissions(action_code, id_role, module_code, object_code)[0]


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
