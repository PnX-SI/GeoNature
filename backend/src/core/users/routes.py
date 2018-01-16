# coding: utf8
from __future__ import (unicode_literals, print_function,
                        absolute_import, division)

from flask import Blueprint, request

from .models import VUserslistForallMenu, TRoles, BibOrganismes, CorRole
from ...utils.utilssqlalchemy import json_resp

from pypnusershub import routes as fnauth

from flask_sqlalchemy import SQLAlchemy
db = SQLAlchemy()

routes = Blueprint('users', __name__)


@routes.route('/menu/<int:idMenu>', methods=['GET'])
@json_resp
def getRolesByMenuId(idMenu):
    q = db.session.query(VUserslistForallMenu)\
            .filter_by(id_menu=idMenu)
    try:
        data = q.all()
    except Exception as e:
        db.session.rollback()
        raise
    if data:
        return [n.as_dict() for n in data]
    return {'message': 'not found'}, 404

@routes.route('/role', methods=['POST'])
@json_resp
def insertRole(user = None):
    if user:
        data = user
    else:
        data = dict(request.get_json())
    user = TRoles(**data)
    if user.id_role:
        exist_user = db.session.query(TRoles).get(user.id_role)
        if exist_user:
            db.session.merge(user)
        else:
            db.session.add(user)
    else:
        db.session.add(user)
    db.session.commit()
    db.session.flush()
    return user.as_dict()

@routes.route('/cor_role', methods=['POST'])
@json_resp
def insert_in_cor_role(id_group=None, id_user=None):
    exist_user = db.session.query(CorRole
        ).filter(CorRole.id_role_groupe == id_group
        ).filter(CorRole.id_role_utilisateur == id_user
        ).all()
    if not exist_user:
        cor_role = CorRole(id_group, id_user)
        db.session.add(cor_role)
        db.session.commit()
        db.session.flush()
        return cor_role.as_dict()
    return {'message': 'cor already exists'}, 500





@routes.route('/organism', methods=['POST'])
@json_resp
def insertOrganism(organism):
    if organism:
        data = organism
    else: 
        data = dict(request.get_json())
    organism = BibOrganismes(**data)
    if organism.id_organisme:
        exist_org = db.session.query(BibOrganismes).get(organism.id_organisme)
        if exist_org:
            db.session.merge(organism)
        else:
            db.session.add(organism)
    else:
        db.session.add(organism)
    db.session.commit()
    db.session.flush()
    return organism.as_dict()

