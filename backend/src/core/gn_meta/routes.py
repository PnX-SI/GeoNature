# coding: utf8
from __future__ import (unicode_literals, print_function,
                        absolute_import, division)

from flask import Blueprint, request
from flask_sqlalchemy import SQLAlchemy

from sqlalchemy import or_

from .models import TPrograms, TDatasets, TParameters, CorDatasetsActor, TAcquisitionFramework
from ...utils.utilssqlalchemy import json_resp

import requests
from xml.etree import ElementTree

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

@routes.route('/cadre_acquision_mtd', methods=['POST'])
@json_resp
def cadre_acquision_ministere():
    """ Routes pour ajouter des cadres d'acquision à partir
    du web service MTD"""
    r = requests.get("https://preprod-inpn.mnhn.fr/mtd/cadre/export/xml/GetRecordById?id=4A9DDA1F-B601-3E13-E053-2614A8C02B7C")
    if r.status_code == 200:
        root = ET.fromstring(r.content)
        attrib = root.attrib
        namespace = attrib['{http://www.w3.org/2001/XMLSchema-instance}schemaLocation'].split()[0]
        namespace = '{'+namespace+'}'
        # tous les cadres d'acquisition
        for ca in root.findall('.//'+namespace+'CadreAcquisition'):
            ca_uuid = ca.find(''+namespace+'identifiantCadre').text
            ca_name = ca.find(''+namespace+'libelle').text
            ca_desc = ca.find(''+namespace+'description').text
            ca_start_date = ca.find('.//'+namespace+'dateLancement').text
            ca_end_date = ca.find('.//'+namespace+'dateCloture').text
            cadre = TAcquisitionFramework(
                #mettre un serial
                #id_acquisition_framework = 3,
                unique_acquisition_framework_id = ca_uuid,
                acquisition_framework_name = ca_name,
                acquisition_framework_desc = ca_desc,
                acquisition_framework_start_date = ca_start_date,
                acquisition_framework_end_date = ca_end_date
            )
            #TODO: 
            #- ecrire dans cor_acquisition_framework_actor
            #- gérer les merge si UUID existe déja
        try:
            db.session.add(cadre)
            db.session.commit()
        except Exception as e:
            db.session.rollback()
            raise
        return {'message': 'add with success'}
    else:
        return {'message': 'not found'}, 404