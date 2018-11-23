'''
Decorators to protects routes with permissions
'''
import json

from flask import redirect, request, Response, current_app, g, Response

from functools import wraps

from geonature.core.permissions.tools import get_user_permissions, get_user_from_token_and_raise

def check_cruved_scope(
    action,
    get_role=False,
    module_code=None,
    redirect_on_expiration=None,
    redirect_on_invalid_token=None,
):
    def _check_cruved_scope(fn):
        @wraps(fn)
        def __check_cruved_scope(*args, **kwargs):
            user = get_user_from_token_and_raise(
                request,
                action,
                redirect_on_expiration,
                redirect_on_invalid_token,
            )
            # If user is Response: its a token issue
            # return the appropriate Response from get_user_from_token_and_raise
            if isinstance(user, Response):
                return user

            if get_role:
                user_permissions = get_user_permissions(
                    user,
                    action,
                    'SCOPE',
                    module_code
                )
                # loop on user permissions
                # return the module permission if exist
                # otherwise return GEONATURE permission
                module_permissions = []
                geonature_permission = []
                # user_permissions is a array of at least 1 permission
                # get the user from the first element of the array
                user_with_highter_perm = None
                for user_permission in user_permissions:
                    if user_permission.module_code == module_code:
                        module_permissions.append(user_permission)
                    else:
                        geonature_permission.append(user_permission)
                # take the max of the different permissions
                if len(module_permissions) == 0:
                    user_with_highter_perm = get_max_perm(geonature_permission)
                else:
                    user_with_highter_perm = get_max_perm(module_permissions)
            
                kwargs['info_role'] = user_with_highter_perm

            g.user = user_with_highter_perm
            return fn(*args, **kwargs)
        return __check_cruved_scope
    return _check_cruved_scope



def get_max_perm(perm_list):
    user_with_highter_perm = perm_list[0]
    max_code = user_with_highter_perm.code_filter
    i = 1
    while i > len(perm_list):
        if perm_list[i].code_filter >= int(max_code):
            max_code = perm_list[i].code_filter
            user_with_highter_perm = perm_list[i]
    return user_with_highter_perm