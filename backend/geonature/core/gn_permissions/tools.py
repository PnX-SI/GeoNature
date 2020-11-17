import logging, json

from flask import current_app, redirect, Response

from itsdangerous import (
    TimedJSONWebSignatureSerializer as Serializer,
    SignatureExpired,
    BadSignature,
)

import sqlalchemy as sa
from sqlalchemy.sql.expression import func


from pypnusershub.db.tools import (
    InsufficientRightsError,
    AccessRightsExpiredError,
    UnreadableAccessRightsError,
)

from geonature.core.gn_permissions.models import VUsersPermissions, TFilters
from geonature.utils.env import DB

log = logging.getLogger(__name__)


def user_from_token(token, secret_key=None):
    secret_key = secret_key or current_app.config["SECRET_KEY"]

    try:
        s = Serializer(current_app.config["SECRET_KEY"])
        user = s.loads(token)
        return user

    except SignatureExpired:
        raise AccessRightsExpiredError("Token expired")

    except BadSignature:
        raise UnreadableAccessRightsError("Token BadSignature", 403)


def get_user_from_token_and_raise(
    request, secret_key=None, redirect_on_expiration=None, redirect_on_invalid_token=None,
):
    """
    Deserialize the token
    catch excetpion and return appropriate Response(403, 302 ...)
    """
    try:
        token = request.cookies["token"]
        return user_from_token(token, secret_key)

    except AccessRightsExpiredError:
        if redirect_on_expiration:
            res = redirect(redirect_on_expiration, code=302)
        else:
            res = Response("Token Expired", 403)
        res.set_cookie("token", expires=0)
        return res
    except InsufficientRightsError as e:
        log.info(e)
        if redirect_on_expiration:
            res = redirect(redirect_on_expiration, code=302)
        else:
            res = Response("Forbidden", 403)
        return res
    except KeyError as e:
        if redirect_on_expiration:
            return redirect(redirect_on_expiration, code=302)
        return Response("No token", 403)

    except UnreadableAccessRightsError:
        log.info("Invalid Token : BadSignature")
        # invalid token
        if redirect_on_invalid_token:
            res = redirect(redirect_on_invalid_token, code=302)
        else:
            res = Response("Token BadSignature", 403)
        res.set_cookie("token", expires=0)
        return res

    except Exception as e:
        trap_all_exceptions = current_app.config.get("TRAP_ALL_EXCEPTIONS", True)
        if not trap_all_exceptions:
            raise
        log.critical(e)
        msg = json.dumps({"type": "Exception", "msg": repr(e)})
        return Response(msg, 403)


class UserCruved:
    def __init__(self,):
        self.is_herited = False

    def build_herited_user_cruved(self, user_permissions, module_code, object_code):
        """
        Parameters:
            - user_permissions(list<VUsersPermissions>)
            - module_code(str)
            - object_code(str)
        Return:
            VUsersPermissions

        """
        # loop on user permissions
        # return the module permission if exist
        # otherwise return GEONATURE permission
        object_permissions = []
        module_permissions = []
        geonature_permission = []
        # filter the GeoNature perm and the module perm in two
        # arrays to make heritage
        for user_permission in user_permissions:
            if user_permission.code_object == object_code:
                object_permissions.append(user_permission)
            elif user_permission.module_code == module_code:
                module_permissions.append(user_permission)
            else:
                geonature_permission.append(user_permission)

        # take the max of the different permissions
        if len(object_permissions) > 0:
            return get_max_perm(object_permissions)
        elif len(object_permissions) == 0 and len(module_permissions) > 0:
            if object_code:
                self.is_herited = True
            return get_max_perm(module_permissions)
        # if no module permission take the max of GN perm
        elif len(module_permissions) == 0:
            if module_code != "GEONATURE":
                self.is_herited = True
            return get_max_perm(geonature_permission)


def query_user_perm(
    id_role, code_filter_type, code_action=None, module_code=None, object_code=None
):

    ors = [VUsersPermissions.module_code.ilike("GEONATURE")]

    q = VUsersPermissions.query.filter(VUsersPermissions.id_role == id_role).filter(
        VUsersPermissions.code_filter_type == code_filter_type
    )
    if code_action:
        q = q.filter(VUsersPermissions.code_action == code_action)
    if module_code:
        ors.append(VUsersPermissions.module_code.ilike(module_code))
    if object_code:
        ors.append(VUsersPermissions.code_object == object_code)
    # if object code is None, only take ALL
    else:
        q = q.filter(VUsersPermissions.code_object == "ALL")
    return q.filter(sa.or_(*ors)).all()


def get_user_permissions(
    user, code_filter_type, code_action=None, module_code=None, code_object=None
):
    """
        Get all the permissions of a user for an action, a module (or an object) and a filter_type
        Users permissions could be multiples because of user's group. The view mapped by VUsersPermissions does not take the
        max because some filter type could be not quantitative
        
        Parameters:
            user(dict)
            code_filter_type(str): <SCOPE, GEOGRAPHIC ...>
            code_action(str): <C,R,U,V,E,D> or None if all actions wanted
            module_code(str): 'GEONATURE', 'OCCTAX'
            code_object(str): 'PERMISSIONS', 'DATASET' (table gn_permissions.t_oject)
        Return:
            Array<VUsersPermissions>
    """
    user_cruved = query_user_perm(
        id_role=user["id_role"],
        code_filter_type=code_filter_type,
        code_action=code_action,
        object_code=code_object,
    )
    object_for_error = None
    if code_object:
        object_for_error = code_object
    if module_code:
        object_for_error = f"{object_for_error} , {module_code}"
    try:
        assert len(user_cruved) > 0
        return user_cruved
    except AssertionError:
        raise InsufficientRightsError(
            f"User {user['id_role']} cannot '{code_action}' in module/app/object {object_for_error}"
        )


def get_max_perm(perm_list):
    """
        Return the max filter_code from a list of VUsersPermissions instance
        get_user_permissions return a list of VUsersPermissions from its group or himself
    """
    user_with_highter_perm = perm_list[0]
    max_code = user_with_highter_perm.value_filter
    i = 1
    while i < len(perm_list):
        if int(perm_list[i].value_filter) >= int(max_code):
            max_code = perm_list[i].value_filter
            user_with_highter_perm = perm_list[i]
        i = i + 1
    return user_with_highter_perm


def build_cruved_dict(cruved, get_id):
    """
        function utils to build a dict like {'C':'3', 'R':'2'}...
        from Array<VUsersPermissions>
    """
    cruved_dict = {}
    for action_scope in cruved:
        if get_id:
            cruved_dict[action_scope[0]] = action_scope[2]
        else:
            cruved_dict[action_scope[0]] = action_scope[1]
    return cruved_dict


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
    id_role=None, module_code=None, object_code=None, get_id=False
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
    Return a tuple 
    - index 0: the cruved as a dict : {'C': 0, 'R': 2 ...}
    - index 1: a boolean which say if its an herited cruved
    """
    user_cruved = UserCruved()
    user_perm = query_user_perm(
        id_role=id_role, code_filter_type="SCOPE", module_code=module_code, object_code=object_code
    )
    # order permissions by ACTION
    perm_by_actions = {}
    for perm in user_perm:
        if perm.code_action in perm_by_actions:
            perm_by_actions[perm.code_action].append(perm)
        else:
            perm_by_actions[perm.code_action] = [perm]
    if get_id:
        id_scope_no_data = (
            DB.session.query(TFilters.id_filter).filter(TFilters.value_filter == "0").one()[0]
        )
    herited_perm = {}

    for action, perm in perm_by_actions.items():
        herited_perm[action] = user_cruved.build_herited_user_cruved(
            perm, module_code=module_code, object_code=object_code
        )
    cruved_actions = ["C", "R", "U", "V", "E", "D"]

    herited_cruved = {}
    # TODO: is herited ?
    for action in cruved_actions:
        if action in herited_perm:
            if get_id:
                herited_cruved[action] = herited_perm[action].id_filter
            else:
                herited_cruved[action] = herited_perm[action].value_filter
        else:
            if get_id:
                herited_cruved[action] = id_scope_no_data
            else:
                herited_cruved[action] = "0"
    return herited_cruved, user_cruved.is_herited

    # user_cruved = build_herited_user_cruved(user_perm)

    # if object not ALL, no heritage
    # if object_code != "ALL":
    #     object_cruved = q.all()

    #     cruved_dict = build_cruved_dict(object_cruved, get_id)
    #     update_cruved = {}
    #     for action in cruved_actions:
    #         if action in cruved_dict:
    #             update_cruved[action] = cruved_dict[action]
    #         else:
    #             update_cruved[action] = "0"
    #     return update_cruved, False

    # get max scope cruved for module GEONATURE
    # parent_cruved_data = q.filter(VUsersPermissions.module_code.ilike("GEONATURE")).all()
    # parent_cruved = {}
    # build a dict like {'C':'0', 'R':'2' ...} if get_id = False or
    # {'C': 1, 'R':3 ...} if get_id = True

    # parent_cruved = build_cruved_dict(parent_cruved_data, get_id)

    # get max scope cruved for module passed in parameter
    # user_cruved = {}
    # if module_code:
    #     ors.append(VUsersPermissions.module_code.ilike(module_code))
    # module_cruved_data = q.filter(VUsersPermissions.module_code.ilike(module_code)).all()
    # module_cruved = build_cruved_dict(module_cruved_data, get_id)
    # for the module
    # for action_scope in cruved_data:
    #     if action_scope[3] != module_code or action_scope[4] != object_code:
    #         herited = True
    #     if get_id:
    #         user_cruved[action_scope[0]] = action_scope[2]
    #     else:
    #         user_cruved[action_scope[0]] = action_scope[1]
    # # get the id for code 0

    return herited_cruved, herited


def get_or_fetch_user_cruved(session=None, id_role=None, module_code=None, object_code=None):
    """
        Check if the cruved is in the session
        if not, get the cruved from the DB with 
        cruved_for_user_in_app()
    """
    if module_code in session and "user_cruved" in session[module_code]:
        return session[module_code]["user_cruved"]
    else:
        user_cruved = cruved_scope_for_user_in_module(
            id_role=id_role, module_code=module_code, object_code=object_code
        )[0]
        session[module_code] = {}
        session[module_code]["user_cruved"] = user_cruved
    return user_cruved

