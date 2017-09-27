# coding: utf8
from __future__ import (unicode_literals, print_function,
                        absolute_import, division)

from flask import Blueprint, request

from flask_sqlalchemy import SQLAlchemy
db = SQLAlchemy()

from .models import VUserslistForallMenu
from ...utils.utilssqlalchemy import json_resp

routes = Blueprint('users', __name__)

@routes.route('/menu/<int:idMenu>', methods=['GET'])
@json_resp
def getRolesByMenuId(idMenu):
    try :
        q = db.session.query(VUserslistForallMenu)\
            .filter_by(id_menu = idMenu)

        data = q.all()
    except:
        db.session.close()
        raise
    if data:
        return [n.as_dict() for n in data]
    return {'message': 'not found'}, 404
