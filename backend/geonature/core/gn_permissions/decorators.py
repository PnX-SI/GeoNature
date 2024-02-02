"""
Decorators to protects routes with permissions
"""

from functools import wraps
from warnings import warn

from flask import request, g
from werkzeug.exceptions import Unauthorized, Forbidden

from geonature.core.gn_permissions.tools import get_permissions, get_scopes_by_action


# use login_required from flask_login
from flask_login import login_required


def _forbidden_message(action, module_code, object_code):
    message = f"User {g.current_user.id_role} has no permissions to {action}"
    if module_code:
        message += f" in {module_code}"
    if object_code:
        message += f" on {object_code}"
    return message


def check_cruved_scope(
    action,
    module_code=None,
    object_code=None,
    *,
    get_scope=False,
):
    """
    Decorator to protect routes with SCOPE CRUVED
    The decorator first check if the user is connected
    and then return the max user SCOPE permission for the action in parameter
    The decorator manages herited CRUVED from user's group and parent module (GeoNature)

    Parameters
    ----------
    action : str
        the requested action of the route <'C', 'R', 'U', 'V', 'E', 'D'>
    module_code : str, optional
        the code of the module (gn_commons.t_modules) (e.g. 'OCCTAX') for the requested permission, by default None
    object_code : str, optional
        the code of the object (gn_permissions.t_object) for the requested permission (e.g. 'PERMISSIONS'), by default None
    get_scope : bool, optional
        does the decorator should add the scope to view kwargs, by default False
    """

    def _check_cruved_scope(view_func):
        @wraps(view_func)
        def decorated_view(*args, **kwargs):
            if not g.current_user.is_authenticated:
                raise Unauthorized
            scope = get_scopes_by_action(module_code=module_code, object_code=object_code)[action]
            if not scope:
                raise Forbidden(description=_forbidden_message(action, module_code, object_code))
            if get_scope:
                kwargs["scope"] = scope
            return view_func(*args, **kwargs)

        return decorated_view

    return _check_cruved_scope


def permissions_required(
    action,
    module_code=None,
    object_code=None,
):
    def _permission_required(view_func):
        @wraps(view_func)
        def decorated_view(*args, **kwargs):
            if not g.current_user.is_authenticated:
                raise Unauthorized
            permissions = get_permissions(action, module_code=module_code, object_code=object_code)
            if not permissions:
                raise Forbidden(description=_forbidden_message(action, module_code, object_code))
            kwargs["permissions"] = permissions
            return view_func(*args, **kwargs)

        return decorated_view

    return _permission_required
