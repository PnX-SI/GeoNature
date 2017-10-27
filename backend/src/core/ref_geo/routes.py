# coding: utf8
from __future__ import (unicode_literals, print_function,
                        absolute_import, division)

from flask import Blueprint, request
from flask_sqlalchemy import SQLAlchemy
from sqlalchemy.sql import text

from ...utils.utilssqlalchemy import json_resp, serializeQuery
from .models import BibAreasTypes

from geojson import Feature, FeatureCollection, dumps
from shapely.geometry import asShape
from geoalchemy2.shape import to_shape, from_shape

db = SQLAlchemy()

routes = Blueprint('ref_geo', __name__)


@routes.route('/info', methods=['POST'])
@json_resp
def getGeoInfo():
    data = dict(request.get_json())
    sql = text('SELECT (ref_geo.fct_get_area_intersection(st_setsrid(ST_GeomFromGeoJSON(:geom),4326), 101)).*')
    try:
        result = db.engine.execute(sql, geom=str(data['geometry']))
    except Exception as e:
        db.session.rollback()
        raise

    municipality = []
    for row in result:
        municipality.append({"id_area": row[0], "id_type": row[1], "area_code": row[2], "area_name": row[3]})

    sql = text('SELECT (ref_geo.fct_get_altitude_intersection(st_setsrid(ST_GeomFromGeoJSON(:geom),4326))).*')
    try:
        result = db.engine.execute(sql, geom=str(data['geometry']))
    except Exception as e:
        db.session.rollback()
        raise
    alt = {}
    for row in result:
        alt = {"altitude_min": row[0], "altitude_max": row[1]}

    return {'municipality': municipality, 'altitude': alt}


@routes.route('/areas', methods=['POST'])
@json_resp
def getAreasIntersection():
    data = dict(request.get_json())

    if 'id_type' in data:
        id_type = data['id_type']
    else:
        id_type = None

    sql = text('SELECT (ref_geo.fct_get_area_intersection(st_setsrid(ST_GeomFromGeoJSON(:geom),4326),:type)).*')

    try:
        result = db.engine.execute(sql, geom=str(data['geometry']), type=id_type)
    except Exception as e:
        db.session.rollback()
        raise

    areas = []
    for row in result:
        areas.append({"id_area": row[0], "id_type": row[1], "area_code": row[2], "area_name": row[3]})

    bibtypesliste = [a['id_type'] for a in areas]
    try:
        bibareatype = db.session.query(BibAreasTypes).filter(BibAreasTypes.id_type.in_(bibtypesliste)).all()
    except Exception as e:
        db.session.rollback()
        raise
    data = {}
    for b in bibareatype:
        data[b.id_type] = b.as_dict(columns=('type_name', 'type_code'))
        data[b.id_type]['areas'] = [a for a in areas if a['id_type'] == b.id_type]

    return data
