import logging, json

from flask import current_app, redirect, Response
from werkzeug.exceptions import Unauthorized
from werkzeug.routing import RequestRedirect


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

from geonature.core.gn_permissions.models import VUsersPermissions
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
    Déserialisation du token utilisateur.
    Attrape les exceptions et en retourne de nouvelles qui seront gérées
    par "l'attrapeur" global d'exception (voir backend/geonature/core/errors/routes.py).
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
    Classe permettant de récupérer le CRUVED d'un utilisateur pour un 
    module et un objet données.
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
        """
        Construction de la liste des couples "module_code, object_code"
        a récupérer pour générer le CRUVED.
        append_to_select => Ajout de sélection pour complexifié l'héritage.
        """
        permissions_select = {
            0: [self._module_code, self._object_code],
            10: [self._module_code, self._main_object_code],
            20: [self._main_module_code, self._object_code],
            30: [self._main_module_code, self._main_object_code],
        }

        # Append extra permissions order
        if append_to_select:
            permissions_select = {**permissions_select, **append_to_select}

        # Filter null value
        active_permissions_select = {k: v for k, v in permissions_select.items() if v[0] and v[1]}

        return active_permissions_select

    def _build_query_permission(self, code_action=None):
        """
        Construction de la requête de récupération des permissions.
        Ordre de récupération
            - code_objet et module_code
            - ALL et module_code
            - code_objet et GEONATURE
            - ALL et GEONATURE
        """
        q = (
            VUsersPermissions.query
            .filter(VUsersPermissions.id_role == self._id_role)
            .filter(VUsersPermissions.code_filter_type == self._code_filter_type)
        )
        if code_action:
            q = q.filter(VUsersPermissions.code_action == code_action)

        # List of module_code, object_code couples to select
        ors = []
        for k, (module_code, object_code) in self._permission_select.items():
            ors.append(
                sa.and_(
                    VUsersPermissions.module_code.ilike(module_code),
                    VUsersPermissions.code_object == object_code,
                )
            )
        q = q.filter(sa.or_(*ors))
        return q.all()

    def _build_other_filters_for_max_perm_query(self, gathering):
        """
        Construction de la requête de récupération des "permissions" contenant
        les éventuels autres filtres (différent de self._code_filter_type).
        Ordre de récupération
            - code_objet et module_code
            - ALL et module_code
            - code_objet et GEONATURE
            - ALL et GEONATURE
        """
        q = (
            VUsersPermissions.query
            .filter(VUsersPermissions.code_filter_type != self._code_filter_type)
            .filter(VUsersPermissions.gathering == gathering)
        )
        return q.all()

    def get_actions_codes():
        return UserCruved._cruved_actions

    def get_user_perm_list(self, code_action=None):
        return self._build_query_permission(code_action=code_action)

    def get_max_perm(self, perm_list):
        """
        Retourne la permission possédant la valeur de filtre la plus grande
        parmis une liste d'instances de VUsersPermissions.
        Ce fonctionnement est prévu pour des filtres dont la valeur est numérique.
        Utilisé principalement pour le CRUVED avec le filtre de propriété (=SCOPE).
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
        Retourne la permission avec la valeur la plus haute pour une liste 
        de permission données appartenant à un utilisateur.

        Parameters:
            - user_permissions(list<VUsersPermissions>)
        Return:
            VUsersPermissions
            herited
            herited_object
        """
        # Loop on user permissions.
        # Return the module permission if exist.
        # Otherwise return GEONATURE permission.
        type_of_perm = {}

        # Sort by key the permissions inheritances tests
        permission_keys = sorted(self._permission_select)

        # Filter the GeoNature perm and the module perm in two arrays to make heritage
        for user_permission in user_permissions:
            for k, (module_code, object_code) in self._permission_select.items():
                if (
                    user_permission.code_object == object_code
                    and user_permission.module_code == module_code
                ):
                    type_of_perm.setdefault(k, []).append(user_permission)

        # Take the max of the different permissions
        herited = False
        herited_object = None
        for k in permission_keys:
            if k in type_of_perm and len(type_of_perm[k]) > 0:
                max_perm = self.get_max_perm(type_of_perm[k])

                # If key is not first in list, then inheritance
                if k > permission_keys[0]:
                    herited = True
                    herited_object = self._permission_select[k]
                return max_perm, herited, herited_object

    def get_perm_for_all_actions(self):
        """
        Construction des permissions pour chaque action d'un module/objet données

        Return:
            - herited_cruved : valeur max de la permission pour chaque action du cruved.
            - herited(boolean) : True si hérité, False sinon.
            - herited_object((module_code, object_code)) : si herited
                nom du module/objet pour lequel la valeur du cruved est retourné.

        """
        # Get all user permissions
        user_permissions = self.get_user_perm_list()

        # For each permission, we sort by action
        perm_by_actions = {}
        for perm in user_permissions:
            perm_by_actions.setdefault(perm.code_action, []).append(perm)

        # For each action, we build the permissions
        herited_perm = {}  # List of CRUVED permissions
        is_herited = False
        g_herited_object = None
        for action, perm in perm_by_actions.items():
            herited_perm[action], herited, herited_object = self.build_herited_user_cruved(perm)
            if herited:
                is_herited = True
                g_herited_object = herited_object

        # Set default value to return
        default_value = "0"

        # Prepare output
        herited_cruved = {}
        for action in self._cruved_actions:
            if action in herited_perm:
                herited_cruved[action] = getattr(herited_perm[action], "value_filter")
            else:
                herited_cruved[action] = default_value

        return herited_cruved, is_herited, g_herited_object

    def get_perm_for_one_action(self, action):
        """
        Récupération de la permission héritée avec la valeur la plus grande 
        pour une action donnée.
        """
        permissions = self.get_user_perm_list(action)

        permissions = self.build_herited_user_cruved(permissions)
        if permissions is not None:
            (max_perm, is_inherited_by_module, herited_by) = permissions
            other_filters_permissions = self._build_other_filters_for_max_perm_query(max_perm.gathering)
            return max_perm, is_inherited_by_module, herited_by, other_filters_permissions


def cruved_scope_for_user_in_module(
    id_role=None,
    module_code=None,
    object_code=None,
    get_herited_obj=False,
    append_to_select=None,
):
    """
    Récupère le CRUVED de l'utilisateur pour un module ou un objet.
    Si le CRUVED n'existe pas pour un module, il est récupéré de son module
    parent.
    Le CRUVED d'un module enfant écrase toujours celui de ses parents.

    Params:
        - id_role(int)
        - module_code(str)
        - object_code(str)
        - append_to_select (dict) : dictionnaire contenant des règles 
            d'héritage supplémentaires.

    Return a tuple
    - index 0: le CRUVED sous forme de dictionnaire : {'C': 0, 'R': 2 ...}
    - index 1: un bouleén indiquant si le CRUVED est hérité ou pas.
    """
    herited_cruved, is_herited, herited_object = UserCruved(
        id_role=id_role,
        code_filter_type="SCOPE",
        module_code=module_code,
        object_code=object_code,
        append_to_select=append_to_select,
    ).get_perm_for_all_actions()
    if get_herited_obj:
        is_herited = (is_herited, herited_object)
    return herited_cruved, is_herited


def get_or_fetch_user_cruved(session=None, id_role=None, module_code=None, object_code=None):
    """
    Vérifie la présence du CRUVED en session sinon le récupère depuis la base de données.
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
