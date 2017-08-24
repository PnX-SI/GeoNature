# coding: utf8
from __future__ import (unicode_literals, print_function,
                        absolute_import, division)

from flask import Blueprint, request

from .models import VUserslistForallMenu
from ..utils.utilssqlalchemy import json_resp

routes = Blueprint('users', __name__)

@routes.route('/menu/<int:idMenu>', methods=['GET'])
@json_resp
def getRolesByMenuId(idMenu):
    q = VUserslistForallMenu.query\
        .filter_by(id_menu = idMenu)

    data = q.all()
    if data:
        return [n.as_dict() for n in data]
    return {'message': 'not found'}, 404
