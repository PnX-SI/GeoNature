# coding: utf8
from __future__ import (unicode_literals, print_function,
                        absolute_import, division)

from flask import Blueprint, request
from flask_sqlalchemy import SQLAlchemy

from sqlalchemy import or_

from .models import TPrograms, TDatasets, TParameters, CorDatasetsActor
from ...utils.utilssqlalchemy import json_resp

db = SQLAlchemy()

routes = Blueprint('gn_meta', __name__)


@routes.route('/list/programs', methods=['GET'])
@json_resp
def getProgramsList():
    q = db.session.query(TPrograms)
    try:
        data = q.all()
    except Exception as e:
        db.session.rollback()
        raise
    if data:
        return [
            d.as_dict(columns=('id_program', 'program_desc')) for d in data
        ]
    return {'message': 'not found'}, 404


@routes.route('/programs', methods=['GET'])
@json_resp
def getPrograms():
    q = db.session.query(TPrograms)
    try:
        data = q.all()
    except Exception as e:
        db.session.rollback()
        raise
    if data:
        return ([n.as_dict(False) for n in data])
    return {'message': 'not found'}, 404


@routes.route('/programswithdatasets', methods=['GET'])
@json_resp
def getProgramsWithDatasets():
    q = db.session.query(TPrograms)
    try:
        data = q.all()
    except Exception as e:
        db.session.rollback()
        raise
    if data:
        return ([n.as_dict(True) for n in data])
    return {'message': 'not found'}, 404


@routes.route('/list/datasets', methods=['GET'])
@json_resp
def getDatasetsList():
    q = db.session.query(TDatasets)
    try:
        data = q.all()
    except Exception as e:
        db.session.rollback()
        raise
    if data:
        return [
            d.as_dict(columns=('id_dataset', 'dataset_name')) for d in data
        ]
    return {'message': 'not found'}, 404


@routes.route('/datasets', methods=['GET'])
@json_resp
def getDatasets():
    """
        Retourne la liste des datasets

        Parameters
        ----------------------
        organism: int
            id de l'organisme du dataset
    """
    parameters = request.args
    q = db.session.query(TDatasets)

    if 'organism' in parameters:
        q = q.join(CorDatasetsActor,
        CorDatasetsActor.id_dataset == TDatasets.id_dataset
        ).filter(
            CorDatasetsActor.id_actor == int(parameters.get('organism')))
    try:
        data = q.all()
    except Exception as e:
        db.session.rollback()
        raise
    results = []
    if data:
        return [d.as_dict(True) for d in data]
    return {'message': 'not found'}, 404


@routes.route('/list/parameters', methods=['GET'])
@json_resp
def getParametersList():
    q = db.session.query(TParameters)
    try:
        data = q.all()
    except Exception as e:
        db.session.rollback()
        raise
    if data:
        return [d.as_dict() for d in data]
    return {'message': 'not found'}, 404


@routes.route('/parameters/<param_name>', methods=['GET'])
@routes.route('/parameters/<param_name>/<int:id_org>', methods=['GET'])
@json_resp
def getOneParameter(param_name, id_org=None):
    q = db.session.query(TParameters)
    q = q.filter(TParameters.parameter_name == param_name)
    if id_org:
        q = q.filter(TParameters.id_organism == id_org)

    try:
        data = q.all()
    except Exception as e:
        db.session.rollback()
        raise
    if data:
        return [d.as_dict() for d in data]
    return {'message': 'not found'}, 404
