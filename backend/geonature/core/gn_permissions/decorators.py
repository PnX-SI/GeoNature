"""
Decorators to protects routes with permissions
"""
import json

from flask import redirect, request, Response, current_app, g, Response

from functools import wraps

from pypnusershub.db.tools import InsufficientRightsError

from geonature.core.gn_permissions.tools import (
    get_user_permissions,
    get_user_from_token_and_raise,
    get_max_perm,
    UserCruved,
)


def check_cruved_scope(
    action,
    get_role=False,
    module_code=None,
    object_code=None,
    redirect_on_expiration=None,
    redirect_on_invalid_token=None,
):
    """
    Decorator to protect routes with SCOPE CRUVED
    The decorator first check if the user is conected and have a corect token (get_user_from_token_and_raise)
    and then return the max user SCOPE permission for the action in parameter
    The decorator manage herited CRUVED from user's group and parent module (GeoNature)
    Return a VUsersPermissions as kwargs of the decorated function as 'info_role' parameter

    Parameters:
        action(string): the requested action of the route <'C', 'R', 'U', 'V', 'E', 'D'>
        get_role(boolean): is the decorator should retour the VUsersPermissions object as kwargs
        module_code(string): the code of the module (gn_commons.t_modules) ('OCCTAX') for the requested permission
        object_code(string): the code of the object (gn_permissions.t_object) for the requested permission ('PERMISSIONS')
        redirect_on_expiration(string): url where we redirect on token expiration
        redirect_on_invalid_token(string): url where we redirect on token invalid token
    """

    def _check_cruved_scope(fn):
        @wraps(fn)
        def __check_cruved_scope(*args, **kwargs):
            user = get_user_from_token_and_raise(
                request, action, redirect_on_expiration, redirect_on_invalid_token
            )
            # If user not a dict: its a token issue
            # return the appropriate Response from get_user_from_token_and_raise
            if not isinstance(user, dict):
                return user
            user_with_highter_perm = None
            user_permissions = get_user_permissions(
                user, "SCOPE", action, module_code, object_code
            )
            user_cruved_obj = UserCruved()
            user_with_highter_perm = user_cruved_obj.build_herited_user_cruved(user_permissions, module_code, object_code)

            # if get_role = True : set info_role as kwargs
            if get_role:
                kwargs["info_role"] = user_with_highter_perm
            # if no perm or perm = 0 -> raise 403
            if user_with_highter_perm is None or (
                user_with_highter_perm is not None and user_with_highter_perm.value_filter == "0"
            ):  
                if object_code:
                    message = f"""User {user_with_highter_perm.id_role} cannot "{user_with_highter_perm.code_action}" {object_code}"""
                else:
                    message = f"""User {user_with_highter_perm.id_role}" cannot "{user_with_highter_perm.code_action}" in {user_with_highter_perm.module_code}"""
                raise InsufficientRightsError(message, 403)
            g.user = user_with_highter_perm
            return fn(*args, **kwargs)

        return __check_cruved_scope

    return _check_cruved_scope

