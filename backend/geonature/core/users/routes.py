import logging
from flask import Blueprint, request
from sqlalchemy.sql import distinct

from geonature.utils.env import DB
from geonature.core.users.models import VUserslistForallMenu, BibOrganismes, CorRole
from pypnusershub.db.models import User

from geonature.utils.utilssqlalchemy import json_resp
from geonature.core.gn_permissions import decorators as permissions
from geonature.core.gn_meta.models import CorDatasetActor
from geonature.core.gn_meta.repositories import get_datasets_cruved


routes = Blueprint("users", __name__)
log = logging.getLogger()


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
            order_col = getattr(BibOrganismes.__table__.columns, params.pop("orderby"))
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

    datasets = [dataset["id_dataset"] for dataset in get_datasets_cruved(info_role)]
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
            order_col = getattr(BibOrganismes.__table__.columns, params.pop("orderby"))
            q = q.order_by(order_col)
        except AttributeError:
            log.error("the attribute to order on does not exist")
    return [organism.as_dict() for organism in q.all()]

