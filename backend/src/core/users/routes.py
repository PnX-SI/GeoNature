# coding: utf8
from __future__ import (unicode_literals, print_function,
                        absolute_import, division)

from flask import Blueprint, request

from .models import VUserslistForallMenu, TRoles, BibOrganismes
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
def insertRole():
    try:
        test = request.get_json()
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
    except:
        db.session.rollback()
        raise



@routes.route('/organism', methods=['POST'])
@json_resp
def insertOrganism():
    try:
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
    except:
        db.session.rollback()
        raise
