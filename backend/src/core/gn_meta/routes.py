# coding: utf8
from __future__ import (unicode_literals, print_function,
                        absolute_import, division)

from flask import Blueprint
from flask_sqlalchemy import SQLAlchemy

from .models import TPrograms, TDatasets
from ...utils.utilssqlalchemy import json_resp

db = SQLAlchemy()

routes = Blueprint('gn_meta', __name__)


@routes.route('/list/programs', methods=['GET'])
@json_resp
def getProgramsList():
    q = TPrograms.query
    data = q.all()
    if data:
         return [d.as_dict(columns=('id_program','program_desc')) for d in data]
    return {'message': 'not found'}, 404

@routes.route('/programs', methods=['GET'])
@json_resp
def getPrograms():
    q = TPrograms.query
    data = q.all()
    if data:
        return ([n.as_dict(False) for n in data])
    return {'message': 'not found'}, 404

@routes.route('/programswithdatasets', methods=['GET'])
@json_resp
def getProgramsWithDatasets():
    q = TPrograms.query
    data = q.all()
    if data:
        return ([n.as_dict(True) for n in data])
    return {'message': 'not found'}, 404


@routes.route('/list/datasets', methods=['GET'])
@json_resp
def getDatasetsList():
    q = TDatasets.query
    data = q.all()
    if data:
         return [d.as_dict(columns=('id_dataset','dataset_name')) for d in data]
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
