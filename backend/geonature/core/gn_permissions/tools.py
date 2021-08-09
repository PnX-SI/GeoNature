import logging, json

from flask import current_app, redirect, Response
from werkzeug.exceptions import Forbidden, Unauthorized
from werkzeug.routing import RequestRedirect


from itsdangerous import (
    TimedJSONWebSignatureSerializer as Serializer,
    SignatureExpired,
    BadSignature,
)

import sqlalchemy as sa
from sqlalchemy.sql.expression import func


from pypnusershub.db.tools import (
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

def log_expiration_warning():
    log.warning("""
        The parameter redirect_on_expiration will be soon removed.
        The redirection will be default to GeoNature login page
        """
    )

def get_user_from_token_and_raise(
    request,
    secret_key=None,
    redirect_on_expiration=None,
    redirect_on_invalid_token=None
):
    """
    Deserialize the token
    catch excetpion and return appropriate Response(403, 302 ...)
    """
    try:
        token = request.cookies["token"]
        return user_from_token(token, secret_key)

    except KeyError:
        if redirect_on_expiration:
            log_expiration_warning()
            raise RequestRedirect(new_url=redirect_on_expiration)
        raise Unauthorized(description='No token.')
    except AccessRightsExpiredError:
        if redirect_on_expiration:
            log_expiration_warning()
            raise RequestRedirect(new_url=redirect_on_expiration)
        raise Unauthorized(description='Token expired.')
    except UnreadableAccessRightsError:
        if redirect_on_invalid_token:
            log_expiration_warning()
            raise RequestRedirect(new_url=redirect_on_invalid_token)
        raise Unauthorized(description='Token corrupted.')
    except Exception as e:
        trap_all_exceptions = current_app.config.get("TRAP_ALL_EXCEPTIONS", True)
        if not trap_all_exceptions:
            raise
        log.critical(e)
        raise Unauthorized(description=repr(e))


class UserCruved:
    """
    Classe permettant de récupérer le cruved d'un utilisateur
        pour un module et un objet données

    """

    _main_module_code = "GEONATURE"
    _main_object_code = "ALL"
    _cruved_actions = ["C", "R", "U", "V", "E", "D"]

    def __init__(
        self, id_role, code_filter_type, module_code=None, object_code=None, append_to_select=None
    ):

        self._id_role = id_role
        self._code_filter_type = code_filter_type
        self._module_code = module_code
        self._object_code = object_code
        self._permission_select = self._build_permission_select_list(append_to_select)

    def _build_permission_select_list(self, append_to_select):

        # Construction de la liste des couples module_code, object_code
        #   a récupérer pour générer le cruved
        #   append_to_select => Ajout de selection pour complexifié l'héritage
        permissions_select = {
            0: [self._module_code, self._object_code],
            10: [self._module_code, self._main_object_code],
            20: [self._main_module_code, self._object_code],
            30: [self._main_module_code, self._main_object_code],
        }

        # append_to_select
        if append_to_select:
            permissions_select = {**permissions_select, **append_to_select}

        # filter null value
        active_permissions_select = {k: v for k, v in permissions_select.items() if v[0] and v[1]}

        return active_permissions_select

    def _build_query_permission(self, code_action=None):
        """
        Construction de la requete de récupération des permissions
        Ordre de récupération
            - code_objet et module_code
            - ALL et module_code
            - code_objet et GEONATURE
            - ALL et GEONATURE
        """
        q = VUsersPermissions.query.filter(VUsersPermissions.id_role == self._id_role).filter(
            VUsersPermissions.code_filter_type == self._code_filter_type
        )
        if code_action:
            q = q.filter(VUsersPermissions.code_action == code_action)

        # Liste des couples module_code, object_code à sélectionner
        ors = []
        for k, (module_code, object_code) in self._permission_select.items():
            ors.append(
                sa.and_(
                    VUsersPermissions.module_code.ilike(module_code),
                    VUsersPermissions.code_object == object_code,
                )
            )

        return q.filter(sa.or_(*ors)).all()

    def get_user_perm_list(self, code_action=None):
        return self._build_query_permission(code_action=code_action)

    def get_max_perm(self, perm_list):
        """
        Return the max filter_code from a list of VUsersPermissions instance
        get_max_perm return a list of VUsersPermissions from its group or himself
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

    def build_herited_user_cruved(self, user_permissions):
        """
            Construction des permissions pour un utilisateur
                pour une liste de permission données

        Parameters:
            - user_permissions(list<VUsersPermissions>)
        Return:
            VUsersPermissions
            herited
            herited_object
        """
        # loop on user permissions
        # return the module permission if exist
        # otherwise return GEONATURE permission
        type_of_perm = {}

        # Liste des clés des paramètres de of select trié
        permission_keys = sorted(self._permission_select)

        # filter the GeoNature perm and the module perm in two
        # arrays to make heritage
        for user_permission in user_permissions:
            for k, (module_code, object_code) in self._permission_select.items():
                if (
                    user_permission.code_object == object_code
                    and user_permission.module_code == module_code
                ):
                    type_of_perm.setdefault(k, []).append(user_permission)

        # take the max of the different permissions
        herited = False
        herited_object = None
        for k in permission_keys:
            if k in type_of_perm and len(type_of_perm[k]) > 0:
                #  Si la clé n'est pas le première de la liste
                # Alors héritage
                if k > permission_keys[0]:
                    herited = True
                    herited_object = self._permission_select[k]
                return self.get_max_perm(type_of_perm[k]), herited, herited_object

    def get_herited_user_cruved(self):
        user_permissions = self.get_user_perm_list()
        return self.build_herited_user_cruved(user_permissions)

    def get_perm_for_all_actions(self, get_id):
        """
        Construction des permissions pour
            chaque action d'un module/objet données

        Parameters:
            - get_id(boolean) : indique si la valeur de la permission retournée
                correspond au code (False) ou à son identifiant (True)
        Return:
            - herited_cruved : valeur max de la permission pour chaque action du cruved
            - herited(boolean) : True si hérité, False sinon
            - herited_object((module_code, object_code)) : si herited
                nom du module/objet pour lequel la valeur du cruved est retourné

        """
        # Récupération de l'ensemble des permissions
        user_permissions = self.get_user_perm_list()
        perm_by_actions = {}

        # Pour chaque permission tri en fonction de son action
        for perm in user_permissions:
            perm_by_actions.setdefault(perm.code_action, []).append(perm)

        # Récupération de la valeur par défaut qui doit être retournée
        if get_id:
            default_value = (
                DB.session.query(TFilters.id_filter).filter(TFilters.value_filter == "0").one()[0]
            )
            select_col = "id_filter"
        else:
            default_value = "0"
            select_col = "value_filter"

        herited_perm = {}  # Liste des permissions du cruved
        is_herited = False
        g_herited_object = None

        # Pour chaque action construction des permissions
        for action, perm in perm_by_actions.items():
            herited_perm[action], herited, herited_object = self.build_herited_user_cruved(perm)
            if herited:
                is_herited = True
                g_herited_object = herited_object

        # Mise en forme
        herited_cruved = {}
        for action in self._cruved_actions:
            if action in herited_perm:
                herited_cruved[action] = getattr(herited_perm[action], select_col)
            else:
                herited_cruved[action] = default_value

        return herited_cruved, is_herited, g_herited_object

    def get_herited_user_cruved_by_action(self, action):
        """
        Récupération des permissions par action
        """
        permissions = self._build_query_permission(action)
        return self.build_herited_user_cruved(permissions)


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
    user_cruved = UserCruved(
        id_role=user["id_role"],
        code_filter_type=code_filter_type,
        module_code=module_code,
        object_code=code_object,
    ).get_user_perm_list(code_action=code_action)
    object_for_error = None

    try:
        assert len(user_cruved) > 0
        return user_cruved
    except AssertionError:
        object_for_error = ",".join(filter(None, (code_object, module_code)))
        raise Forbidden(
            f"User {user['id_role']} cannot '{code_action}' in module/app/object {object_for_error}"
        )


# def build_cruved_dict(cruved, get_id):
#     """
#         function utils to build a dict like {'C':'3', 'R':'2'}...
#         from Array<VUsersPermissions>
#         NOT USE => TODO DELETE
#     """
#     cruved_dict = {}
#     for action_scope in cruved:
#         if get_id:
#             cruved_dict[action_scope[0]] = action_scope[2]
#         else:
#             cruved_dict[action_scope[0]] = action_scope[1]
#     return cruved_dict


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
    get_herited_obj=False,
    append_to_select=None,
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
    herited_cruved, is_herited, herited_object = UserCruved(
        id_role=id_role,
        code_filter_type="SCOPE",
        module_code=module_code,
        object_code=object_code,
        append_to_select=append_to_select,
    ).get_perm_for_all_actions(get_id)
    if get_herited_obj:
        is_herited = (is_herited, herited_object)
    return herited_cruved, is_herited


def get_scopes_by_action(id_role, module_code=None, object_code=None):
    cruved = UserCruved(id_role=id_role, code_filter_type="SCOPE",
                        module_code=module_code, object_code=object_code)
    return { action: int(scope) for action, scope in cruved.get_perm_for_all_actions(get_id=False)[0].items() }


def get_or_fetch_user_cruved(session=None, id_role=None, module_code=None, object_code=None):
    """
    Check if the cruved is in the session
    if not, get the cruved from the DB with
    cruved_for_user_in_app()
    """
    if module_code in session and "user_cruved" in session[module_code]:
        # FIXME object_code is not checked!
        return session[module_code]["user_cruved"]
    else:
        user_cruved = cruved_scope_for_user_in_module(
            id_role=id_role, module_code=module_code, object_code=object_code
        )[0]
        session[module_code] = {}
        session[module_code]["user_cruved"] = user_cruved
    return user_cruved