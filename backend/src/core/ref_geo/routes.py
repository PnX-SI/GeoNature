# coding: utf8
from __future__ import (unicode_literals, print_function,
                        absolute_import, division)

from flask import Blueprint, request
from flask_sqlalchemy import SQLAlchemy
from sqlalchemy.sql import text

from ...utils.utilssqlalchemy import json_resp, serializeQuery

from geojson import Feature, FeatureCollection, dumps
from shapely.geometry import asShape
from geoalchemy2.shape import to_shape, from_shape

db = SQLAlchemy()

routes = Blueprint('ref_geo', __name__)

@routes.route('/info', methods=['POST'])
@json_resp
def getGeoInfo():
    data = dict(request.get_json())
    print(data)
    print(data['geometry'])
    shape = asShape(data['geometry'])
    geom_4326 =from_shape(shape, srid=4326)

    sql = text('SELECT (ref_geographique.fct_get_municipality_intersection(st_setsrid(ST_GeomFromGeoJSON(:geom),4326))).*')
    result = db.engine.execute(sql, geom = str(data['geometry']))
    municipality = []
    for row in result:
        municipality.append({"code" : row[0], "name" : row[1]})

    sql = text('SELECT (ref_geographique.fct_get_altitude_intersection(st_setsrid(ST_GeomFromGeoJSON(:geom),4326))).*')
    result = db.engine.execute(sql, geom = str(data['geometry']))
    alt = []
    for row in result:
        alt.append({"altitude_min" : row[0], "altitude_max" : row[1]})

    return {'municipality': municipality, 'altitude':alt}
    # return {'message': 'not found'}, 404
