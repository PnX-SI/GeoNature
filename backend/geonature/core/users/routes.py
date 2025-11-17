import json
import logging
from functools import wraps

import requests
from flask import (
    Blueprint,
    Response,
    current_app,
    g,
    render_template,
    request,
)
from geonature.core.gn_meta.models import CorDatasetActor, TDatasets
from geonature.core.gn_permissions import decorators as permissions
from geonature.core.users.models import CorRole, VUserslistForallMenu
from geonature.core.users.register_post_actions import (
    execute_actions_after_validation,
    send_email_for_recovery,
    validate_temp_user,
)
from geonature.utils.config import config
from geonature.utils.env import DB, db
from pypnusershub.auth.subscribe import (
    change_password,
    create_cor_role_token,
    create_temp_user,
    valid_temp_user,
)
from pypnusershub.db.models import Application, Organisme, User, UserList

from sqlalchemy import and_, select
from sqlalchemy.sql import and_
from utils_flask_sqla.response import json_resp
from werkzeug.exceptions import BadRequest, Forbidden, InternalServerError, NotFound

routes = Blueprint("users", __name__, template_folder="templates")
log = logging.getLogger()
s = requests.Session()


user_fields = {
    "id_role",
    "identifiant",
    "nom_role",
    "prenom_role",
    "nom_complet",
    "id_organisme",
    "groupe",
    "active",
    "remarques",
}
organism_fields = {
    "id_organisme",
    "uuid_organisme",
    "nom_organisme",
}


@routes.route("/menu/<int:id_menu>", methods=["GET"])
@json_resp
def get_roles_by_menu_id(id_menu):
    """
    Returns the list of roles associated with a menu

    Parameters
    ----------
    id_menu : int
        The id of user list (utilisateurs.bib_list)
    nom_complet : str, optional
        Beginning of complete name of the role

    Returns
    -------
    list of dict
        List of roles associated with the menu
    """
    query = select(VUserslistForallMenu).filter_by(id_menu=id_menu)

    parameters = request.args
    nom_complet = parameters.get("nom_complet")
    if nom_complet:
        query = query.where(VUserslistForallMenu.nom_complet.ilike(f"{nom_complet}%"))

    data = DB.session.scalars(query.order_by(VUserslistForallMenu.nom_complet.asc())).all()
    return [n.as_dict() for n in data]


@routes.route("/menu_from_code/<string:code_liste>", methods=["GET"])
@json_resp
def get_roles_by_menu_code(code_liste):
    """
    Returns the list of roles associated with a user list (identified by its code)

    Parameters
    ----------
    code_liste : str
        The code of user list (utilisateurs.t_lists)
    nom_complet : str, optional
        Beginning of complete name of the role, default None

    Returns
    -------
    list
        A list of roles associated with the user list
    """

    query = select(VUserslistForallMenu).join(
        UserList,
        and_(
            UserList.id_liste == VUserslistForallMenu.id_menu,
            UserList.code_liste == code_liste,
        ),
    )

    parameters = request.args
    if parameters.get("nom_complet"):
        query = query.where(
            VUserslistForallMenu.nom_complet.ilike("{}%".format(parameters.get("nom_complet")))
        )
    data = DB.session.scalars(query.order_by(VUserslistForallMenu.nom_complet.asc())).all()
    return [n.as_dict() for n in data]


@routes.route("/listes", methods=["GET"])
@json_resp
def get_listes():
    query = select(UserList)
    lists = DB.session.scalars(query).all()
    return [l.as_dict() for l in lists]


@routes.route("/role/<int:id_role>", methods=["GET"])
@permissions.login_required
@json_resp
def get_role(id_role):
    """
    Get role detail

    Parameters
    ----------
    id_role : int
        the id user

    Returns
    -------
    dict
        A dictionary containing the role detail
    """
    user = DB.get_or_404(User, id_role)
    fields = user_fields.copy()
    if g.current_user == user:
        fields.add("email")
    return user.as_dict(fields=fields)


@routes.route("/roles", methods=["GET"])
@permissions.login_required
@json_resp
def get_roles():
    """
    Get all roles

    .. :quickref: User;
    """
    params = request.args.to_dict()
    query = select(User)
    if "group" in params:
        query = query.where(User.groupe == params["group"])
    if "orderby" in params:
        try:
            order_col = getattr(User.__table__.columns, params.pop("orderby"))
            query = query.order_by(order_col)
        except AttributeError:
            raise BadRequest("the attribute to order on does not exist")
    return [user.as_dict(fields=user_fields) for user in DB.session.scalars(query).all()]


@routes.route("/organisms", methods=["GET"])
@permissions.login_required
@json_resp
def get_organismes():
    """
    Get all organisms

    .. :quickref: User;
    """
    params = request.args.to_dict()
    q = select(Organisme)
    if "orderby" in params:
        try:
            order_col = getattr(Organisme.__table__.columns, params.pop("orderby"))
            q = q.order_by(order_col)
        except AttributeError:
            raise BadRequest("the attribute to order on does not exist")
    return [organism.as_dict(fields=organism_fields) for organism in DB.session.scalars(q).all()]


@routes.route("/organisms_dataset_actor", methods=["GET"])
@permissions.login_required
@json_resp
def get_organismes_jdd():
    """
    Get all organisms and the JDD where there are actor and where
    the current user hase autorization with its cruved

    .. :quickref: User;
    """
    params = request.args.to_dict()
    datasets = DB.session.scalars(TDatasets.filter_by_readable()).unique().all()
    datasets = [d.id_dataset for d in datasets]
    query = (
        select(Organisme)
        .join(CorDatasetActor, Organisme.id_organisme == CorDatasetActor.id_organism)
        .where(CorDatasetActor.id_dataset.in_(datasets))
        .distinct()
    )
    if "orderby" in params:
        try:
            order_col = getattr(Organisme.__table__.columns, params.pop("orderby"))
            query = query.order_by(order_col)
        except AttributeError:
            raise BadRequest("the attribute to order on does not exist")
    return [
        organism.as_dict(fields=organism_fields)
        for organism in DB.session.scalars(query).unique().all()
    ]


###################################
### ACCOUNT_MANAGEMENT ROUTES #####
###################################


def check_sign_up_enabled(key):
    """
    Decorator to check if a user management feature is enabled.

    Parameters
    ----------
    key : str
        The key of the feature. Must be one of:
        ENABLE_SIGN_UP, ENABLE_ACCOUNT_MANAGEMENT, AUTO_ACCOUNT_CREATION
    """

    def decorator(f):
        @wraps(f)
        def decorated_function(*args, **kwargs):
            valid_keys = ["ENABLE_SIGN_UP", "ENABLE_USER_MANAGEMENT", "AUTO_ACCOUNT_CREATION"]
            if key not in valid_keys:
                raise KeyError(f"{key} is not a valid feature key. Must be one of {valid_keys}")

            if not current_app.config["ACCOUNT_MANAGEMENT"].get(key, False):
                raise NotFound("Page not found")

            return f(*args, **kwargs)

        return decorated_function

    return decorator


@routes.route("/inscription", methods=["POST"])
@check_sign_up_enabled("ENABLE_SIGN_UP")
def inscription():
    """
    Add a user to temporary users table from the GeoNature interface
    Works according to the 'ENABLE_SIGN_UP' authorization in the config.
    """

    data = request.get_json()
    # ajout des valeurs non présentes dans le form
    data["id_application"] = (
        DB.session.execute(
            select(Application).filter_by(code_application=current_app.config["CODE_APPLICATION"])
        )
        .scalar_one()
        .id_application
    )
    data["groupe"] = False

    try:
        token_data = create_temp_user(data)
        validate_temp_user(token_data)
    except Exception as e:
        raise BadRequest(str(e))

    return {"message": "Subscription created"}, 200


@routes.route("/login/recovery", methods=["POST"])
@check_sign_up_enabled("ENABLE_USER_MANAGEMENT")
def login_recovery():
    """
    Send an email with the user login and a link to reset its password
    Only works if 'ENABLE_SIGN_UP' is enabled
    """

    if not current_app.config.get("ACCOUNT_MANAGEMENT").get("ENABLE_USER_MANAGEMENT", False):
        raise NotFound("Page not found")

    data = request.get_json()
    try:
        create_cor_role_token(data["email"])
        user = db.session.execute(
            select(User).where(User.email == data["email"]),
        ).scalar_one()
        send_email_for_recovery(user)
    except Exception as e:
        raise BadRequest(str(e))
    return {"message": "Token created"}, 200


@routes.route("/confirmation", methods=["GET"])
@check_sign_up_enabled("ENABLE_SIGN_UP")
def confirmation():
    """
    Validate a user account after a request (this action is triggered by the link in the email)
    Create a personal JDD as post_action if the parameter AUTO_DATASET_CREATION is set to True
    """

    token = request.args.get("token", None)
    if token is None:
        raise BadRequest("Token not found")

    data = {
        "token": token,
        "id_application": DB.session.execute(
            select(Application).filter_by(code_application=current_app.config["CODE_APPLICATION"])
        )
        .scalar_one()
        .id_application,
    }
    try:
        user_data = valid_temp_user(data)
        execute_actions_after_validation(user_data)
    except Exception as e:
        raise BadRequest(str(e))

    return {"message": "Account validated"}, 200


@routes.route("/role", methods=["PUT"])
@permissions.login_required
@json_resp
@check_sign_up_enabled("ENABLE_USER_MANAGEMENT")
def update_role():
    """
    Modify the role of the user associated with the current token.
    """
    data = dict(request.get_json())

    user = g.current_user

    if user.is_public:
        raise Forbidden

    attliste = [k for k in data]
    for att in attliste:
        if not getattr(User, att, False):
            data.pop(att)

    # liste des attributs qui ne doivent pas être modifiable par l'user
    black_list_att_update = [
        "active",
        "date_insert",
        "date_update",
        "groupe",
        "id_organisme",
        "id_role",
        "pass_plus",
        "pn",
        "uuid_role",
    ]
    for key, value in data.items():
        if key not in black_list_att_update:
            setattr(user, key, value)

    DB.session.merge(user)
    DB.session.commit()
    DB.session.flush()
    return user.as_dict()


@routes.route("/password/change", methods=["PUT"])
@permissions.login_required
@json_resp
@check_sign_up_enabled("ENABLE_USER_MANAGEMENT")
def change_password_route():
    """
    Change the password of the connected user
    """
    user = g.current_user
    data = request.get_json()

    init_password = data.get("init_password", None)

    if not init_password:
        if not data.get("token", None):
            raise BadRequest("No Token was found")
    else:
        if not user.check_password(data.get("init_password", None)):
            raise BadRequest("Initial password is incorrect")

        try:
            new_token = create_cor_role_token(user.email)["token"]
        except Exception as e:
            raise InternalServerError(f"Error when creating a new token: {str(e)}")
        data["token"] = new_token

    required_fields = ["password", "password_confirmation", "token"]
    if not all(field in data for field in required_fields):
        raise InternalServerError("Missing required fields for password change")

    try:
        change_password(data.get("token"), data.get("password"), data.get("password_confirmation"))
    except Exception as e:
        raise BadRequest("An error occurred while changing the password")

    return {"message": "Password changed with success"}, 200


@routes.route("/password/new", methods=["PUT"])
@json_resp
@check_sign_up_enabled("ENABLE_USER_MANAGEMENT")
def new_password():
    """
    Changes the password of a user after they requested a password recovery
    Requires a token sent by mail to the user
    """

    data = dict(request.get_json())
    if not data.get("token", None):
        raise BadRequest("No token provided")
    try:
        change_password(data.get("token"), data.get("password"), data.get("password_confirmation"))
    except Exception as e:
        raise BadRequest(str(e))
    return {"message": "Password changed with success"}, 200
