# coding: utf8
from __future__ import (unicode_literals, print_function,
                        absolute_import, division)

from flask import Blueprint, request
from flask_sqlalchemy import SQLAlchemy
from sqlalchemy import exc

from .models import TRelevesContact, TOccurrencesContact, CorCountingContact, VReleveContact, VReleveList, corRoleRelevesContact
from ...utils.utilssqlalchemy import json_resp, testDataType
from ...core.users.models import TRoles
from ...core.ref_geo.models import LAreasWithoutGeom

from pypnusershub import routes as fnauth

from geojson import Feature, FeatureCollection, dumps
from shapely.geometry import asShape
from geoalchemy2.shape import to_shape, from_shape

routes = Blueprint('pr_contact', __name__)

db = SQLAlchemy()

from flask import g
def get_db():
    db = getattr(g, '_database', None)
    if db is None:
        db = g._database = connect_to_database()
    return db

@routes.route('/releves', methods=['GET'])
@json_resp
def getReleves():
    q = TRelevesContact.query
    data = q.all()
    if data:
        return FeatureCollection([n.get_geofeature() for n in data])
    return {'message': 'not found'}, 404

@routes.route('/occurrences', methods=['GET'])
@json_resp
def getOccurrences():
    q = TOccurrencesContact.query
    data = q.all()
    if data:
        return ([n.as_dict() for n in data])
    return {'message': 'not found'}, 404

@routes.route('/releve/<int:id_releve>', methods=['GET'])
@json_resp
def getOneReleve(id_releve):
    data = TRelevesContact.query.get(id_releve)
    if data:
        return data.get_geofeature()
    return {'message': 'not found'}, 404

# @routes.route('/nbOccurrences', methods=['GET'])
# @json_resp
# def getNbCounting():
#     q = TOccurrencesContact.query.count()
#     return q

@routes.route('/vrelevecontact', methods=['GET'])
@json_resp
def getViewReleveContact():
    q = db.session.query(VReleveContact)

    parameters = request.args

    nbResultsWithoutFilter = db.session.query(VReleveContact).count()

    limit = int(parameters.get('limit')) if parameters.get('limit') else 100
    page = int(parameters.get('offset')) if parameters.get('offset') else 0

    #Filters
    for param in parameters:
        if param in VReleveContact.__table__.columns:
            col = getattr( VReleveContact.__table__.columns,param)
            q = q.filter(col == parameters[param])

    #Order by
    if 'orderby' in parameters:
        if parameters.get('orderby') in VReleveContact.__table__.columns:
             orderCol =  getattr(VReleveContact.__table__.columns,parameters['orderby'])
        else:
            orderCol = getattr(VReleveContact.__table__.columns,'occ_meta_create_date')

        if 'order' in parameters:
            if (parameters['order'] == 'desc'):
                orderCol = orderCol.desc()

        q= q.order_by(orderCol)

    try :
        data = q.limit(limit).offset(page*limit).all()
    except:
        db.session.rollback()
        raise
    if data:
        return {'items': FeatureCollection([n.get_geofeature() for n in data]), 'total': nbResultsWithoutFilter}
    return {'message': 'not found'}, 404


@routes.route('/vreleve', methods=['GET'])
@json_resp
def getViewReleveList():
    q = db.session.query(VReleveList)

    parameters = request.args

    try :
        nbResultsWithoutFilter = VReleveList.query.count()
    except :
        db.session.rollback()

    limit = int(parameters.get('limit')) if parameters.get('limit') else 100
    page = int(parameters.get('offset')) if parameters.get('offset') else 0
    #Specific Filters
    if 'cd_nom' in parameters:
        testT = testDataType(parameters.get('cd_nom'), db.Integer, 'cd_nom')
        if testT:
            return {'error':testT},500
        q = q.join(TOccurrencesContact, TOccurrencesContact.id_releve_contact == VReleveList.id_releve_contact)\
                .filter(TOccurrencesContact.cd_nom == int(parameters.get('cd_nom')))

    if 'observer' in parameters:
        q = q.join(corRoleRelevesContact, corRoleRelevesContact.columns.id_releve_contact == VReleveList.id_releve_contact)\
            .filter(corRoleRelevesContact.columns.id_role.in_(parameters.getlist('observer')))

    if 'date_up' in parameters:
        testT = testDataType(parameters.get('date_up'), db.DateTime, 'date_up')
        if testT:
            return {'error':testT},500
        q = q.filter(VReleveList.date_min >= parameters.get('date_up'))
    if 'date_low' in parameters:
        testT = testDataType(parameters.get('date_low'), db.DateTime, 'date_low')
        if testT:
            return {'error':testT},500
        q = q.filter(VReleveList.date_max <= parameters.get('date_low'))
    if 'date_eq' in parameters:
        testT = testDataType(parameters.get('date_eq'), db.DateTime, 'date_eq')
        if testT:
            return {'error':testT},500
        q = q.filter(VReleveList.date_min == parameters.get('date_eq'))

    #Generic Filters
    for param in parameters:
        if param in VReleveList.__table__.columns:
            col = getattr( VReleveList.__table__.columns,param)
            testT = testDataType(parameters[param], col.type, param)
            if testT:
                return {'error':testT},500
            q = q.filter(col == parameters[param])
    try:
        nbResults = q.count()
    except:
        db.session.rollback()
        raise

    #Order by
    if 'orderby' in parameters:
        if parameters.get('orderby') in VReleveList.__table__.columns:
             orderCol =  getattr(VReleveList.__table__.columns,parameters['orderby'])
        else:
            orderCol = getattr(VReleveList.__table__.columns,'occ_meta_create_date')

        if 'order' in parameters:
            if (parameters['order'] == 'desc'):
                orderCol = orderCol.desc()

        q= q.order_by(orderCol)

    try :
        data = q.limit(limit).offset(page*limit).all()
    except exc.IntegrityError as e:
        db.session.rollback()
    except:
        print('roollback')
        db.session.rollback()
        raise

    return {
        'total': nbResultsWithoutFilter,
        'total_filtered': nbResults ,
        'page': page,
        'limit': limit,
        'items': FeatureCollection([n.get_geofeature() for n in data])
    }


@routes.route('/releve', methods=['POST'])
@json_resp
def insertOrUpdateOneReleve():
    try:
        data = dict(request.get_json())

        if data['properties']['t_occurrences_contact']:
            occurrences_contact = data['properties']['t_occurrences_contact']
            data['properties'].pop('t_occurrences_contact')

        if data['properties']['observers']:
            observersList =  data['properties']['observers']
            data['properties'].pop('observers')

        releve = TRelevesContact(**data['properties'])
        shape = asShape(data['geometry'])
        releve.geom_4326 =from_shape(shape, srid=4326)

        observers = db.session.query(TRoles).filter(TRoles.id_role.in_(observersList)).all()
        for o in observers :
            releve.observers.append(o)


        for occ in occurrences_contact :
            if occ['cor_counting_contact']:
                cor_counting_contact = occ['cor_counting_contact']
                occ.pop('cor_counting_contact')

            contact = TOccurrencesContact(**occ)
            for cnt in cor_counting_contact :
                countingContact = CorCountingContact(**cnt)
                contact.cor_counting_contact.append(countingContact)
            releve.t_occurrences_contact.append(contact)

        try:
            if releve.id_releve_contact :
                db.session.merge(releve)
            else :
                db.session.add(releve)
            db.session.commit()
            db.session.flush()
        except Exception as e:
            raise

        return releve.get_geofeature()

    except Exception as e:

        db.session.rollback()
        raise
