import logging
import requests
import json


from flask import Blueprint, request, current_app, Response, redirect, g, render_template
from sqlalchemy.sql import distinct, and_
from sqlalchemy import distinct, and_, select, exists
from werkzeug.exceptions import NotFound, BadRequest, Forbidden

from geonature.utils.env import DB
from geonature.core.gn_permissions import decorators as permissions
from geonature.core.gn_meta.models import CorDatasetActor, TDatasets
from geonature.core.users.models import (
    VUserslistForallMenu,
    CorRole,
)
from geonature.utils.config import config
from pypnusershub.db.models import Organisme, User, UserList
from geonature.core.users.register_post_actions import (
    validate_temp_user,
    execute_actions_after_validation,
    send_email_for_recovery,
)

from pypnusershub.env import REGISTER_POST_ACTION_FCT
from pypnusershub.db.models import User, Application
from pypnusershub.db.models_register import TempUser
from pypnusershub.routes_register import bp as user_api
from utils_flask_sqla.response import json_resp


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
}
organism_fields = {
    "id_organisme",
    "uuid_organisme",
    "nom_organisme",
}

# configuration of post_request actions for registrations
REGISTER_POST_ACTION_FCT.update(
    {
        "create_temp_user": validate_temp_user,
        "valid_temp_user": execute_actions_after_validation,
        "create_cor_role_token": send_email_for_recovery,
    }
)


@routes.route("/menu/<int:id_menu>", methods=["GET"])
@json_resp
def get_roles_by_menu_id(id_menu):
    """
    Retourne la liste des roles associés à un menu

    .. :quickref: User;

    :param id_menu: the id of user list (utilisateurs.bib_list)
    :type id_menu: int
    :query str nom_complet: begenning of complet name of the role
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
    Retourne la liste des roles associés à une liste (identifiée par son code)

    .. :quickref: User;

    :param code_liste: the code of user list (utilisateurs.t_lists)
    :type code_liste: string
    :query str nom_complet: begenning of complet name of the role
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

    .. :quickref: User;

    :param id_role: the id user
    :type id_role: int
    """
    user = DB.get_or_404(User, id_role)
    fields = user_fields.copy()
    if g.current_user == user:
        fields.add("email")
        fields.add("champs_addi")
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
    q = select(User)
    if "group" in params:
        q = q.where(User.groupe == params["group"])
    if "orderby" in params:
        try:
            order_col = getattr(User.__table__.columns, params.pop("orderby"))
            q = q.order_by(order_col)
        except AttributeError:
            raise BadRequest("the attribute to order on does not exist")
    return [user.as_dict(fields=user_fields) for user in DB.session.scalars(q).all()]


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


#########################
### ACCOUNT_MANAGEMENT ROUTES #####
#########################


# TODO: let frontend call UsersHub directly?
@routes.route("/inscription", methods=["POST"])
def inscription():
    """
    Ajoute un utilisateur à utilisateurs.temp_user à partir de l'interface geonature
    Fonctionne selon l'autorisation 'ENABLE_SIGN_UP' dans la config.
    Fait appel à l'API UsersHub
    """
    # test des droits
    if not config["ACCOUNT_MANAGEMENT"].get("ENABLE_SIGN_UP", False):
        return {"message": "Page introuvable"}, 404

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
    data["confirmation_url"] = config["API_ENDPOINT"] + "/users/after_confirmation"

    r = s.post(
        url=config["API_ENDPOINT"] + "/pypn/register/post_usershub/create_temp_user",
        json=data,
    )

    return Response(r), r.status_code


# TODO supprimer si non utilisé
@routes.route("/login/recovery", methods=["POST"])
def login_recovery():
    """
    Call UsersHub API to create a TOKEN for a user
    A post_action send an email with the user login and a link to reset its password
    Work only if 'ENABLE_SIGN_UP' is set to True
    """
    # test des droits
    if not current_app.config.get("ACCOUNT_MANAGEMENT").get("ENABLE_USER_MANAGEMENT", False):
        return {"msg": "Page introuvable"}, 404

    data = request.get_json()

    r = s.post(
        url=config["API_ENDPOINT"] + "/pypn/register/post_usershub/create_cor_role_token",
        json=data,
    )

    return Response(r), r.status_code


@routes.route("/confirmation", methods=["GET"])
def confirmation():
    """
    Validate a account after a demande (this action is triggered by the link in the email)
    Create a personnal JDD as post_action if the parameter AUTO_DATASET_CREATION is set to True
    Fait appel à l'API UsersHub
    """
    # test des droits
    if not config["ACCOUNT_MANAGEMENT"].get("ENABLE_SIGN_UP", False):
        return {"message": "Page introuvable"}, 404

    token = request.args.get("token", None)
    if token is None:
        return {"message": "Token introuvable"}, 404

    data = {
        "token": token,
        "id_application": DB.session.execute(
            select(Application).filter_by(code_application=current_app.config["CODE_APPLICATION"])
        )
        .scalar_one()
        .id_application,
    }

    r = s.post(
        url=config["API_ENDPOINT"] + "/pypn/register/post_usershub/valid_temp_user",
        json=data,
    )

    if r.status_code != 200:
        if r.json() and r.json().get("msg"):
            return r.json().get("msg"), r.status_code
        return Response(r), r.status_code

    new_user = r.json()
    return render_template(
        "account_created.html", user=new_user, redirect_url=config["URL_APPLICATION"]
    )


@routes.route("/after_confirmation", methods=["POST"])
def after_confirmation():
    data = dict(request.get_json())
    type_action = "valid_temp_user"
    after_confirmation_fn = REGISTER_POST_ACTION_FCT.get(type_action, None)
    result = after_confirmation_fn(data)
    if result != 0 and result["msg"] != "ok":
        msg = f"Problem in GeoNature API after confirmation {type_action} : {result['msg']}"
        return json.dumps({"msg": msg}), 500
    else:
        return json.dumps(result)


@routes.route("/role", methods=["PUT"])
@permissions.login_required
@json_resp
def update_role():
    """
    Modifie le role de l'utilisateur du token en cours
    """
    if not current_app.config["ACCOUNT_MANAGEMENT"].get("ENABLE_USER_MANAGEMENT", False):
        return {"message": "Page introuvable"}, 404

    data = dict(request.get_json())

    user = g.current_user

    # Prevent public-access user from updating its own information
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
def change_password():
    """
    Modifie le mot de passe de l'utilisateur connecté et de son ancien mdp
    Fait appel à l'API UsersHub
    """
    if not current_app.config["ACCOUNT_MANAGEMENT"].get("ENABLE_USER_MANAGEMENT", False):
        return {"message": "Page introuvable"}, 404

    user = g.current_user
    data = request.get_json()

    init_password = data.get("init_password", None)
    # if not init_passwork provided(passwork forgotten) -> check if token exist
    if not init_password:
        if not data.get("token", None):
            return {"msg": "Erreur serveur"}, 500
    else:
        if not user.check_password(data.get("init_password", None)):
            return {"msg": "Le mot de passe initial est invalide"}, 400

        # recuperation du token usershub API
        # send request to get the token (enable_post_action = False to NOT sent email)
        resp = s.post(
            url=config["API_ENDPOINT"] + "/pypn/register/post_usershub/create_cor_role_token",
            json={"email": user.email, "enable_post_action": False},
        )
        if resp.status_code != 200:
            # comme concerne le password, on explicite pas le message
            return {"msg": "Erreur lors de la génération du token"}, 500

        data["token"] = resp.json()["token"]

    if (
        not data.get("password", None)
        or not data.get("password_confirmation", None)
        or not data.get("token", None)
    ):
        return {"msg": "Erreur serveur"}, 500
    r = s.post(
        url=config["API_ENDPOINT"] + "/pypn/register/post_usershub/change_password",
        json=data,
    )

    if r.status_code != 200:
        # comme concerne le password, on explicite pas le message
        return {"msg": "Erreur serveur"}, 500
    return {"msg": "Mot de passe modifié avec succès"}, 200


@routes.route("/password/new", methods=["PUT"])
@json_resp
def new_password():
    """
    Modifie le mdp d'un utilisateur apres que celui-ci ai demander un renouvelement
    Necessite un token envoyer par mail a l'utilisateur
    """
    if not current_app.config["ACCOUNT_MANAGEMENT"].get("ENABLE_USER_MANAGEMENT", False):
        return {"message": "Page introuvable"}, 404

    data = dict(request.get_json())
    if not data.get("token", None):
        return {"msg": "Erreur serveur"}, 500

    r = s.post(
        url=config["API_ENDPOINT"] + "/pypn/register/post_usershub/change_password",
        json=data,
    )

    if r.status_code != 200:
        # comme concerne le password, on explicite pas le message
        return {"msg": "Erreur serveur"}, 500
    return {"msg": "Mot de passe modifié avec succès"}, 200
