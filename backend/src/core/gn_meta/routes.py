# coding: utf8
from __future__ import (unicode_literals, print_function,
                        absolute_import, division)

from flask import Blueprint

from .models import TProgrammes, TDatasets
from ...utils.utilssqlalchemy import json_resp


routes = Blueprint('gn_meta', __name__)

@routes.route('/programmes', methods=['GET'])
@json_resp
def getProgrammes():
    q = TProgrammes.query
    data = q.all()
    if data:
        return ([n.as_dict(False) for n in data])
    return {'message': 'not found'}, 404

@routes.route('/programmeswithdatasets', methods=['GET'])
@json_resp
def getProgrammesWithDatasets():
    q = TProgrammes.query
    data = q.all()
    if data:
        return ([n.as_dict(True) for n in data])
    return {'message': 'not found'}, 404

@routes.route('/datasets', methods=['GET'])
@json_resp
def getDatasets():
    q = TDatasets.query
    data = q.all()
    results = []
    if data:
        return [d.as_dict(True) for d in data]
    return {'message': 'not found'}, 404
