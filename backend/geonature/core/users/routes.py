from flask import Blueprint, request

from geonature.utils.env import DB
from geonature.core.users.models import (
    VUserslistForallMenu,
    BibOrganismes, CorRole
)
from pypnusershub.db.models import User

from geonature.utils.utilssqlalchemy import json_resp

routes = Blueprint('users', __name__)


@routes.route('/menu/<int:id_menu>', methods=['GET'])
@json_resp
def getRolesByMenuId(id_menu):
    '''
        Retourne la liste des roles associés à un menu

        Parameters
        ----------
         - nom_complet : début du nom complet du role
    '''
    q = DB.session.query(
        VUserslistForallMenu
    ).filter_by(id_menu=id_menu)

    parameters = request.args
    if parameters.get('nom_complet'):
        q = q.filter(
            VUserslistForallMenu.nom_complet.ilike(
                '{}%'.format(parameters.get('nom_complet'))
            )
        )
    data = q.order_by(VUserslistForallMenu.nom_complet.asc()).all()
    return [n.as_dict() for n in data]


@routes.route('/role/<int:id_role>', methods=['GET'])
@json_resp
def get_role(id_role):
    '''
        Retourne le détail d'un role
    '''
    user = DB.session.query(
        User
    ).filter_by(id_role=id_role).one()
    return user.as_dict()


@routes.route('/role', methods=['POST'])
@json_resp
def insert_role(user=None):
    '''
        Insert un role
        @TODO : Ne devrait pas être là mais dans UserHub
    '''
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


@routes.route('/cor_role', methods=['POST'])
@json_resp
def insert_in_cor_role(id_group=None, id_user=None):
    '''
        Insert une correspondante role groupe
        c-a-d permet d'attacher un role à un groupe
       # TODO ajouter test sur les POST de données
    '''
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
    '''
        Insert un organisme
    '''
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


@routes.route('/roles', methods=['GET'])
@json_resp
def get_roles():
    '''
        Retourne tous les roles
    '''
    users = DB.session.query(TRoles).all()
    return [user.as_dict() for user in users]


@routes.route('/organisms', methods=['GET'])
@json_resp
def get_organismes():
    '''
        Retourne tous les organismes
    '''
    organisms = DB.session.query(BibOrganismes).all()
    return [organism.as_dict() for organism in organisms]
