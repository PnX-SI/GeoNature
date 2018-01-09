# coding: utf8
from __future__ import (unicode_literals, print_function,
                        absolute_import, division)

from flask import Blueprint, request, jsonify
from flask_sqlalchemy import SQLAlchemy

from sqlalchemy import or_
from sqlalchemy.sql import text

from .models import TPrograms, TDatasets, TParameters, CorDatasetsActor, TAcquisitionFramework, CorAcquisitionFrameworkActor
from ..users.models import TRoles
from pypnusershub import routes as fnauth
from ...utils.utilssqlalchemy import json_resp
import ast

from . import mtd_utils

import requests
from xml.etree import ElementTree as ET

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
@fnauth.check_auth_cruved('R', True)
@json_resp
def getDatasets(info_role):
    """
        Retourne la liste des datasets

    """
    q = db.session.query(TDatasets)
    user, data_scope = info_role
    if int(data_scope) <= 2:
        q = q.join(CorDatasetsActor,
        CorDatasetsActor.id_dataset == TDatasets.id_dataset
        ).filter(or_(
            CorDatasetsActor.id_organism == user.id_organisme,
            CorDatasetsActor.id_role == user.id_role
            ))
    try:
        data = q.all()
    except Exception as e:
        db.session.rollback()
        raise
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

def getCdNomenclature(id_type, cd_nomenclature):
    query = 'SELECT ref_nomenclatures.get_id_nomenclature(:id_type, :cd_nomencl)'
    result = db.engine.execute(text(query), id_type=id_type, cd_nomencl=cd_nomenclature).first()
    value = None
    if len(result) >= 1:
        value = result[0]
    return value


@routes.route('/aquisition_framework_mtd/<uuid_af>', methods=['POST'])
def post_acquisition_framwork_mtd(uuid=None, id_user=None, id_organism=None):
    """ Post an acquisition framwork from MTD XML"""

    xml_af = mtd_utils.get_acquisition_framework(uuid)
    if xml_af:
        acquisition_framwork = mtd_utils.parse_acquisition_framwork_xml(xml_af)

        new_af = TAcquisitionFramework(**acquisition_framwork)

        actor = CorAcquisitionFrameworkActor(
                id_role = id_user,
                id_nomenclature_actor_role = 393
            )
        new_af.cor_af_actor.append(actor)
        if id_organism:
            organism = CorAcquisitionFrameworkActor(
                id_role = id_organism,
                id_nomenclature_actor_role = 393
            )
            new_af.cor_af_actor.append(actor)
        # check if exist
        id_acquisition_framework = TAcquisitionFramework.get_id(uuid)
        if id_acquisition_framework:
            new_af.id_acquisition_framework = id_acquisition_framework
            db.session.merge(new_af)
        else:
            db.session.add(new_af)
            db.session.commit()
        # return new_af.as_dict()
        return new_af.as_dict()

    return {'message': 'Not found'}, 404
    



@routes.route('/dataset_mtd/<id_user>', methods=['POST'])
@json_resp
def post_jdd_from_user_id(id_user=None, id_organism=None):
    """ Post a jdd from the mtd XML"""
    xml_jdd = mtd_utils.get_jdd_by_user_id(id_user)
    
    if xml_jdd:
        dataset_list = mtd_utils.parse_jdd_xml(xml_jdd)
        dataset_list_model = []
        for ds in dataset_list:
            new_af = post_acquisition_framwork_mtd(
                uuid = ds['uuid_acquisition_framework'],
                id_user = id_user,
                id_organism = id_organism
            )
            new_af = new_af.get_data()
            new_af = json.loads(new_af)
            print('###########################')
            print(dir(new_af))
            print(new_af.response)
            print(new_af.data)
            
            ds.pop('uuid_acquisition_framework')
            ds['id_acquisition_framework'] = new_af['id_acquisition_framework']
            id_dataset = TDatasets.get_id(ds['unique_dataset_id'])
            ds['id_dataset'] = id_dataset

            dataset = TDatasets(**ds)

            # id_role in cor_dataset_actor
            actor = CorDatasetsActor(
                id_role = id_user,
                id_nomenclature_actor_role = 393
            )
            dataset.cor_datasets_actor.append(actor)
            # id_organism in cor_dataset_actor
            if id_organism:
                actor = CorDatasetsActor(
                    id_organism = id_organism,
                    id_nomenclature_actor_role = 393
                )
                dataset.cor_datasets_actor.append(actor)
            
            dataset_list_model.append(dataset)
            if id_dataset:
                db.session.merge(dataset)
            else:
                db.session.add(dataset)

            db.session.commit()
            db.session.flush()

            
        return [d.as_dict() for d in dataset_list_model]
    return {'message': 'Not found'}, 404




## Private fonction
def get_allowed_datasets(user):
    """ return all dataset id allowed for a user"""
    q = db.session.query(
                    CorDatasetsActor,
                    CorDatasetsActor.id_dataset
                    ).filter(or_(
                        CorDatasetsActor.id_organism == user.id_organisme,
                        CorDatasetsActor.id_role == user.id_role
                    ))
    try:
        return [d.id_dataset for d in q.all()]
    except:
        db.session.rollback()
        raise


    


#### TEST 
@routes.route('/test', methods=['GET'])
@json_resp
def test():
    from flask import current_app
    print(current_app.config['PASS_METHOD'])

    #post_jdd_from_user_id(10991, None)
    # print(test)

    # xml = mtd_utils.get_acquisition_framework("60DAC805-2562-13EB-E053-2614A8C0D040")
    # parse = mtd_utils.parse_acquisition_framwork_xml(xml)

    # xml = mtd_utils.get_jdd_by_user_id(9188)
    # parsed = mtd_utils.parse_jdd_xml(xml)

    #print(parsed)
    return 'la'
