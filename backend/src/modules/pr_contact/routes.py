# coding: utf8
from __future__ import (unicode_literals, print_function,
                        absolute_import, division)

from flask import Blueprint, request
from flask_sqlalchemy import SQLAlchemy

from .models import TRelevesContact, TOccurrencesContact, CorCountingContact
from ...utils.utilssqlalchemy import json_resp
from ...core.users.models import TRoles
from pypnusershub import routes as fnauth

from geojson import Feature, FeatureCollection, dumps
from shapely.geometry import asShape
from geoalchemy2.shape import to_shape, from_shape

routes = Blueprint('pr_contact', __name__)

db = SQLAlchemy()

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
                contact.countingContact.append(countingContact)
            releve.occurrences.append(contact)

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
