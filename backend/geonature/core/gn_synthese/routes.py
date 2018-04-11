import json
import logging
from flask import Blueprint, request

from sqlalchemy import distinct, func
from sqlalchemy.sql import text
from geojson import FeatureCollection

from geonature.utils.env import DB

from geonature.core.gn_synthese.models import (
    Synthese, TSources, CorAreaSynthese, DefaultsNomenclaturesValue
)
from pypnusershub import routes as fnauth
from geonature.utils.utilssqlalchemy import json_resp, testDataType
from geonature.core.gn_meta import mtd_utils


routes = Blueprint('gn_synthese', __name__)

# get the root logger
log = logging.getLogger()


@routes.route('/list/sources', methods=['GET'])
@json_resp
def get_sources_list():
    q = DB.session.query(TSources)
    data = q.all()

    return [
        d.as_dict(columns=('id_source', 'desc_source')) for d in data
    ]


@routes.route('/sources', methods=['GET'])
@json_resp
def get_sources():
    q = DB.session.query(TSources)
    data = q.all()

    return [n.as_dict() for n in data]


@routes.route('/defaultsNomenclatures', methods=['GET'])
@json_resp
def getDefaultsNomenclatures():
    params = request.args
    group2_inpn = '0'
    regne = '0'
    organism = 0
    if 'group2_inpn' in params:
        group2_inpn = params['group2_inpn']
    if 'regne' in params:
        regne = params['regne']
    if 'organism' in params:
        organism = params['organism']
    types = request.args.getlist('id_type')

    q = DB.session.query(
        distinct(DefaultsNomenclaturesValue.id_type),
        func.gn_synthese.get_default_nomenclature_value(
            DefaultsNomenclaturesValue.id_type,
            organism,
            regne,
            group2_inpn
        )
    )
    if len(types) > 0:
        q = q.filter(DefaultsNomenclaturesValue.id_type.in_(tuple(types)))
    try:
        data = q.all()
    except Exception:
        DB.session.rollback()
        raise
    if not data:
        return {'message': 'not found'}, 404
    return {d[0]: d[1] for d in data}


@routes.route('/synthese', methods=['POST'])
@json_resp
def get_synthese():
    filters = dict(request.get_json())
    print(filters)
    q = DB.session.query(Synthese)
    if 'observers' in filters:
        q = q.filter(Synthese.observers.ilike('%'+filters.pop('observers')+'%'))
        print(q)
        print(filters)

    for colname, value in filters.items():
        if value is not None:
            col = getattr(Synthese.__table__.columns, colname)
            testT = testDataType(value, col.type, colname)
            if testT:
                return {'error': testT}, 500
            q = q.filter(col == value)
    data = q.all()
    return FeatureCollection([d.get_geofeature() for d in data])


@routes.route('/synthese/<synthese_id>', methods=['GET'])
@json_resp
def get_one_synthese(synthese_id):
    q = DB.session.query(Synthese)
    q = q.filter(Synthese.id_synthese == synthese_id)

    data = q.all()
    return [d.as_dict() for d in data]
