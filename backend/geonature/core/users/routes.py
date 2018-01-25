from flask import Blueprint, request

from geonature.utils.env import DB
from geonature.core.users.models import (
    VUserslistForallMenu, TRoles,
    BibOrganismes, CorRole
)
from geonature.utils.utilssqlalchemy import json_resp

routes = Blueprint('users', __name__)


@routes.route('/menu/<int:idMenu>', methods=['GET'])
@json_resp
def getRolesByMenuId(idMenu):
    q = DB.session.query(
        VUserslistForallMenu
    ).filter_by(id_menu=idMenu)

    data = q.all()
    return [n.as_dict() for n in data]


@routes.route('/role', methods=['POST'])
@json_resp
def insert_role(user=None):
    if user:
        data = user
    else:
        data = dict(request.get_json())
    user = TRoles(**data)
    if user.id_role is not None:
        exist_user = DB.session.query(TRoles).get(user.id_role)
        if exist_user:
            DB.session.merge(user)
        else:
            DB.session.add(user)
    else:
        DB.session.add(user)
    DB.session.commit()
    DB.session.flush()
    return user.as_dict()

# TODO ajouter test sur les POST de données

@routes.route('/cor_role', methods=['POST'])
@json_resp
def insert_in_cor_role(id_group=None, id_user=None):
    exist_user = DB.session.query(
        CorRole
    ).filter(
        CorRole.id_role_groupe == id_group
    ).filter(
        CorRole.id_role_utilisateur == id_user
    ).all()
    if not exist_user:
        cor_role = CorRole(id_group, id_user)
        DB.session.add(cor_role)
        DB.session.commit()
        DB.session.flush()
        return cor_role.as_dict()
    return {'message': 'cor already exists'}, 500



@routes.route('/organism', methods=['POST'])
@json_resp
def insert_organism(organism):
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
