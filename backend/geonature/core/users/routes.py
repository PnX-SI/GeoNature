import logging
import requests

from flask import Blueprint, request
from sqlalchemy.sql import distinct, and_

from flask import Blueprint, request, current_app, Response, redirect

from geonature.utils.env import DB
from geonature.core.users.models import VUserslistForallMenu, BibOrganismes, CorRole, TListes
from pypnusershub.db.models import User
from pypnusershub.db.models_register import TempUser
from pypnusershub.routes_register import bp as user_api
from pypnusershub.routes import check_auth

from utils_flask_sqla.response import json_resp
from geonature.core.gn_permissions import decorators as permissions
from geonature.core.gn_meta.models import CorDatasetActor, TDatasets
from geonature.core.gn_meta.repositories import get_datasets_cruved
from geonature.core.users.register_post_actions import function_dict

routes = Blueprint("users", __name__, template_folder="templates")
log = logging.getLogger()
s = requests.Session()
config = current_app.config

# configuration of post_request actions for registrations


current_app.config["after_USERSHUB_request"] = function_dict


@routes.route("/menu/<int:id_menu>", methods=["GET"])
@json_resp
def getRolesByMenuId(id_menu):
    """
    Retourne la liste des roles associés à un menu

    .. :quickref: User;

    :param id_menu: the id of user list (utilisateurs.bib_list)
    :type id_menu: int
    :query str nom_complet: begenning of complet name of the role
    """
    q = DB.session.query(VUserslistForallMenu).filter_by(id_menu=id_menu)

    parameters = request.args
    if parameters.get("nom_complet"):
        q = q.filter(
            VUserslistForallMenu.nom_complet.ilike(
                "{}%".format(parameters.get("nom_complet"))
            )
        )
    data = q.order_by(VUserslistForallMenu.nom_complet.asc()).all()
    return [n.as_dict() for n in data]


@routes.route("/menu_from_code/<string:code_liste>", methods=["GET"])
@json_resp
def getRolesByMenuCode(code_liste):
    """
    Retourne la liste des roles associés à une liste (identifiée par son code)

    .. :quickref: User;

    :param code_liste: the code of user list (utilisateurs.t_lists)
    :type code_liste: string
    :query str nom_complet: begenning of complet name of the role
    """

    q = DB.session.query(VUserslistForallMenu).join(
        TListes, and_(TListes.id_liste == VUserslistForallMenu.id_menu,
                      TListes.code_liste == code_liste
                      )
    )

    parameters = request.args
    if parameters.get("nom_complet"):
        q = q.filter(
            VUserslistForallMenu.nom_complet.ilike(
                "{}%".format(parameters.get("nom_complet"))
            )
        )
    data = q.order_by(VUserslistForallMenu.nom_complet.asc()).all()
    return [n.as_dict() for n in data]


@routes.route("/role/<int:id_role>", methods=["GET"])
@json_resp
def get_role(id_role):
    """
    Get role detail

    .. :quickref: User;

    :param id_role: the id user
    :type id_role: int
    """
    user = DB.session.query(User).filter_by(id_role=id_role).one()
    return user.as_dict()


@routes.route("/role", methods=["POST"])
@json_resp
def insert_role(user=None):
    """
        Insert un role

        .. :quickref: User;

        @TODO : Ne devrait pas être là mais dans UserHub
        Utilisé dans l'authentification du CAS INPN
    """
    if user:
        data = user
    else:
        data = dict(request.get_json())
    user = User(**data)
    if user.id_role is not None:
        exist_user = DB.session.query(User).get(user.id_role)
        if exist_user:
            DB.session.merge(user)
        else:
            DB.session.add(user)
    else:
        DB.session.add(user)
    DB.session.commit()
    DB.session.flush()
    return user.as_dict()


@routes.route("/cor_role", methods=["POST"])
@json_resp
def insert_in_cor_role(id_group=None, id_user=None):
    """
    Insert a user in a group

    .. :quickref: User;

    :param id_role: the id user
    :type id_role: int    
    :param id_group: the id group
    :type id_group: int
        # TODO ajouter test sur les POST de données
    """
    exist_user = (
        DB.session.query(CorRole)
        .filter(CorRole.id_role_groupe == id_group)
        .filter(CorRole.id_role_utilisateur == id_user)
        .all()
    )
    if not exist_user:
        cor_role = CorRole(id_group, id_user)
        DB.session.add(cor_role)
        DB.session.commit()
        DB.session.flush()
        return cor_role.as_dict()
    return {"message": "cor already exists"}, 500


@routes.route("/organism", methods=["POST"])
@json_resp
def insert_organism(organism):
    """
    Insert a organism

    .. :quickref: User;
    """
    if organism is not None:
        data = organism
    else:
        data = dict(request.get_json())
    organism = BibOrganismes(**data)
    if organism.id_organisme:
        exist_org = DB.session.query(BibOrganismes).get(organism.id_organisme)
        if exist_org:
            DB.session.merge(organism)
        else:
            DB.session.add(organism)
    else:
        DB.session.add(organism)
    DB.session.commit()
    DB.session.flush()
    return organism.as_dict()


@routes.route("/roles", methods=["GET"])
@json_resp
def get_roles():
    """
    Get all roles

    .. :quickref: User;
    """
    params = request.args.to_dict()
    q = DB.session.query(User)
    if "group" in params:
        q = q.filter(User.groupe == params["group"])
    if "orderby" in params:
        try:
            order_col = getattr(User.__table__.columns, params.pop("orderby"))
            q = q.order_by(order_col)
        except AttributeError:
            log.error("the attribute to order on does not exist")
    return [user.as_dict() for user in q.all()]


@routes.route("/organisms", methods=["GET"])
@json_resp
def get_organismes():
    """
        Get all organisms

        .. :quickref: User;
    """
    params = request.args.to_dict()
    q = DB.session.query(BibOrganismes)
    if "orderby" in params:
        try:
            order_col = getattr(
                BibOrganismes.__table__.columns, params.pop("orderby"))
            q = q.order_by(order_col)
        except AttributeError:
            log.error("the attribute to order on does not exist")
    return [organism.as_dict() for organism in q.all()]


@routes.route("/organisms_dataset_actor", methods=["GET"])
@permissions.check_cruved_scope("R", True)
@json_resp
def get_organismes_jdd(info_role):
    """
    Get all organisms and the JDD where there are actor and where 
    the current user hase autorization with its cruved

    .. :quickref: User;
    """
    params = request.args.to_dict()

    datasets = [dataset["id_dataset"]
                for dataset in get_datasets_cruved(info_role)]
    q = (
        DB.session.query(BibOrganismes)
        .join(
            CorDatasetActor, BibOrganismes.id_organisme == CorDatasetActor.id_organism
        )
        .filter(CorDatasetActor.id_dataset.in_(datasets))
        .distinct()
    )
    if "orderby" in params:
        try:
            order_col = getattr(
                BibOrganismes.__table__.columns, params.pop("orderby"))
            q = q.order_by(order_col)
        except AttributeError:
            log.error("the attribute to order on does not exist")
    return [organism.as_dict() for organism in q.all()]


#########################
### ACCOUNT_MANAGEMENT ROUTES #####
#########################


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
    data["id_application"] = current_app.config["ID_APPLICATION_GEONATURE"]
    data["groupe"] = False
    data["url_confirmation"] = config["API_ENDPOINT"] + "/users/confirmation"

    r = s.post(
        url=config["API_ENDPOINT"] +
        "/pypn/register/post_usershub/create_temp_user",
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
    if not current_app.config.get("ACCOUNT_MANAGEMENT").get(
        "ENABLE_USER_MANAGEMENT", False
    ):
        return {"msg": "Page introuvable"}, 404

    data = request.get_json()

    r = s.post(
        url=config["API_ENDPOINT"]
        + "/pypn/register/post_usershub/create_cor_role_token",
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

    data = {"token": token,
            "id_application": config["ID_APPLICATION_GEONATURE"]}

    r = s.post(
        url=config["API_ENDPOINT"] +
        "/pypn/register/post_usershub/valid_temp_user",
        json=data,
    )

    if r.status_code != 200:
        return Response(r), r.status_code

    return redirect(config["URL_APPLICATION"], code=302)


@routes.route("/role", methods=["PUT"])
@permissions.check_cruved_scope("R", True)
@json_resp
def update_role(info_role):
    """
        Modifie le role de l'utilisateur du token en cours
    """
    if not current_app.config["ACCOUNT_MANAGEMENT"].get(
        "ENABLE_USER_MANAGEMENT", False
    ):
        return {"message": "Page introuvable"}, 404
    data = dict(request.get_json())

    user = DB.session.query(User).get(info_role.id_role)

    if user is None:
        return {"message": "Droit insuffisant"}, 403

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
@check_auth(1, True)
@json_resp
def change_password(id_role):
    """
        Modifie le mot de passe de l'utilisateur connecté et de son ancien mdp 
        Fait appel à l'API UsersHub
    """
    if not current_app.config["ACCOUNT_MANAGEMENT"].get("ENABLE_USER_MANAGEMENT", False):
        return {"message": "Page introuvable"}, 404

    user = DB.session.query(User).get(id_role)
    if not user:
        return {"msg": "Droit insuffisant"}, 403
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
            url=config["API_ENDPOINT"]
            + "/pypn/register/post_usershub/create_cor_role_token",
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
        url=config["API_ENDPOINT"] +
        "/pypn/register/post_usershub/change_password",
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
    if not current_app.config["ACCOUNT_MANAGEMENT"].get(
        "ENABLE_USER_MANAGEMENT", False
    ):
        return {"message": "Page introuvable"}, 404

    data = dict(request.get_json())
    if not data.get("token", None):
        return {"msg": "Erreur serveur"}, 500

    r = s.post(
        url=config["API_ENDPOINT"] +
        "/pypn/register/post_usershub/change_password",
        json=data,
    )

    if r.status_code != 200:
        # comme concerne le password, on explicite pas le message
        return {"msg": "Erreur serveur"}, 500
    return {"msg": "Mot de passe modifié avec succès"}, 200
