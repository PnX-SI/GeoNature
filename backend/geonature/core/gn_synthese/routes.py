import json
import logging
from flask import Blueprint, request, session, current_app

from sqlalchemy import distinct, func
from sqlalchemy.orm import exc
from sqlalchemy.sql import text
from geojson import FeatureCollection
from shapely.geometry import asShape
from geoalchemy2.shape import from_shape


from geonature.utils.env import DB
from geonature.utils.errors import GeonatureApiError
from geonature.utils.utilsgeometry import circle_from_point

from geonature.core.gn_synthese.models import (
    Synthese,
    TSources,
    CorAreaSynthese,
    DefaultsNomenclaturesValue,
    VSyntheseForWebApp,
    VSyntheseDecodeNomenclatures,
    VSyntheseForWebAppBis
)
from geonature.core.gn_synthese.repositories import filter_query_with_cruved

from geonature.core.gn_meta.models import (
    TDatasets,
    TAcquisitionFramework
)
from geonature.core.ref_geo.models import (
    LiMunicipalities
)
from pypnusershub import routes as fnauth
from pypnusershub.db.tools import (
    InsufficientRightsError,
    get_or_fetch_user_cruved,
    cruved_for_user_in_app
)
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


@routes.route('', methods=['POST'])
@fnauth.check_auth_cruved('R', True)
@json_resp
def get_synthese(info_role):
    """
        return synthese row(s) filtered by form params
        Params must have same synthese fields names
        'observers' param (string) is filtered with ilike clause
    """
    filters = dict(request.get_json())
    result_limit = filters.pop('limit', 10000)
    from .models import Taxref, TSources, CorRoleSynthese

    q = (
        DB.session.query(Synthese, Taxref, TSources, TDatasets)
        .join(
            Taxref, Taxref.cd_nom == Synthese.cd_nom
        ).join(
            TSources, TSources.id_source == Synthese.id_source
        ).join(
            TDatasets, TDatasets.id_dataset == Synthese.id_dataset
        )
    )

    user_cruved = get_or_fetch_user_cruved(
        session=session,
        id_role=info_role.id_role,
        id_application_parent=14
    )
    from geonature.core.users.models import UserRigth
    print(info_role.nom_role)
    user = UserRigth(
        id_role=info_role.id_role,
        tag_object_code='2',
        tag_action_code="R",
        id_organisme=info_role.id_organisme,
        nom_role='Administrateur',
        prenom_role='test'
    )

    allowed_datasets = TDatasets.get_user_datasets(info_role)
    q = filter_query_with_cruved(q, user, allowed_datasets)

    if 'observers' in filters:
        q = q.filter(Synthese.observers.ilike('%'+filters.pop('observers')+'%'))

    if 'date_min' in filters:
        q = q.filter(Synthese.date_min >= filters.pop('date_min'))

    if 'date_max' in filters:
        q = q.filter(Synthese.date_min <= filters.pop('date_max'))

    if 'id_acquisition_frameworks' in filters:
        # print(dir(q))
        joined_tables = [mapper.class_ for mapper in q._join_entities]
        print(joined_tables)
        q = q.join(
            TAcquisitionFramework,
            TDatasets.id_dataset == TAcquisitionFramework.id_acquisition_framework
        )

        q = q.filter(TAcquisitionFramework.id_acquisition_framework.in_(filters.pop('id_acquisition_frameworks')))

    if 'municipalities' in filters:
        q = q.filter(Synthese.id_municipality.in_([com['insee_com'] for com in filters['municipalities']]))
        filters.pop('municipalities')

    if 'geoIntersection' in filters:
        # Insersect with the geom send from the map
        geom_wkt = asShape(filters['geoIntersection']['geometry'])
        # if the geom is a circle
        if 'radius' in filters['geoIntersection']['properties']:
            radius = filters['geoIntersection']['properties']['radius']
            geom_wkt = circle_from_point(geom_wkt, radius)
        geom_wkb = from_shape(geom_wkt, srid=4326)
        q = q.filter(Synthese.the_geom_4326.ST_Intersects(geom_wkb))
        filters.pop('geoIntersection')
        # print(q)

    # generic filters
    for colname, value in filters.items():
        if colname.startswith('area'):
            q = q.join(
                CorAreaSynthese,
                CorAreaSynthese.id_synthese == Synthese.id_synthese
            )
            q = q.filter(CorAreaSynthese.id_area.in_(
                [a['id_area'] for a in value]
            ))
        else:
            col = getattr(Synthese.__table__.columns, colname)
            q = q.filter(col.in_(value))

    q = q.order_by(
        Synthese.date_min.desc()
    )

    data = q.limit(result_limit)

    features = []
    for d in data:
        feature = d[0].get_geofeature(columns=['date_min', 'observers', 'id_synthese'])
        cruved = d[0].get_synthese_cruved(info_role, user_cruved, allowed_datasets)
        feature['properties']['cruved'] = cruved
        feature['properties']['taxon'] = d[1].as_dict()
        feature['properties']['sources'] = d[2].as_dict(columns=['entity_source_pk_field', 'url_source'])
        feature['properties']['dataset'] = d[3].as_dict(columns=['dataset_name'])
        features.append(feature)
    return FeatureCollection(features)


@routes.route('/vsynthese', methods=['POST'])
@json_resp
def get_vsynthese():
    """
        return synthese row(s) filtered by form params
        Params must have same synthese fields names
        'observers' param (string) is filtered with ilike clause
    """
    filters = dict(request.get_json())
    q = DB.session.query(VSyntheseForWebApp)

    if 'observers' in filters and filters['observers']:
        q = q.filter(VSyntheseForWebApp.observers.ilike('%'+filters.pop('observers')+'%'))

    for colname, value in filters.items():
        col = getattr(VSyntheseForWebApp.__table__.columns, colname)
        testT = testDataType(value, col.type, colname)
        if testT:
            return {'error': testT}, 500
        q = q.filter(col == value)
    if 'limit' in filters:
        q = q.limit(
            filters['limit']
        ).orderby(
            VSyntheseForWebApp.date_min
        )
    else:
        data = q.all()
    return FeatureCollection([d.get_geofeature() for d in data])


@routes.route('/vsynthese/<id_synthese>', methods=['GET'])
@json_resp
def get_one_synthese(id_synthese):
    """
        Retourne un enregistrement de la synthese
        avec les nomenclatures décodées pour la webapp
    """
    q = DB.session.query(VSyntheseDecodeNomenclatures)
    q = q.filter(VSyntheseDecodeNomenclatures.id_synthese == id_synthese)

    try:
        data = q.one()
        return data.as_dict()
    except exc.NoResultFound:
        return None


@routes.route('/<id_synthese>', methods=['DELETE'])
@fnauth.check_auth_cruved('D', True)
@json_resp
def delete_synthese(info_role, id_synthese):
    synthese_obs = DB.session.query(Synthese).get(id_synthese)
    user_datasets = TDatasets.get_user_datasets(info_role)
    synthese_releve = synthese_obs.get_observation_if_allowed(info_role, user_datasets)

    # get and delete source
    # FIX
    # est-ce qu'on peut supprimer les données historiques depuis la synthese
    source = DB.session.query(TSources).filter(TSources.id_source == synthese_obs.id_source).one()
    pk_field_source = source.entity_source_pk_field
    inter = pk_field_source.split('.')
    pk_field = inter.pop()
    table_source = inter.join('.')
    sql = text("DELETE FROM {table} WHERE {pk_field} = :id".format(
        table=table_source,
        pk_field=pk_field)
    )
    result = DB.engine.execute(
        sql,
        id=synthese_obs.entity_source_pk_value
    )

    # delete synthese obs
    DB.session.delete(synthese_releve)
    DB.session.commit()

    return {'message': 'delete with success'}, 200
