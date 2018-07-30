import json
import logging
from flask import Blueprint, request, session, current_app

from sqlalchemy import distinct, func
from sqlalchemy.orm import exc
from sqlalchemy.sql import text
from geojson import FeatureCollection

from geonature.utils.env import DB
from geonature.utils.errors import GeonatureApiError

from geonature.core.gn_synthese.models import (
    Synthese,
    TSources,
    CorAreaSynthese,
    DefaultsNomenclaturesValue,
    VSyntheseForWebApp,
    VSyntheseDecodeNomenclatures,
    VSyntheseForWebAppBis
)

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


@routes.route('/synthese', methods=['POST'])
@fnauth.check_auth_cruved('R', True)
@json_resp
def get_synthese(info_role):
    """
        return synthese row(s) filtered by form params
        Params must have same synthese fields names
        'observers' param (string) is filtered with ilike clause
    """

    filters = dict(request.get_json())
    result_limit = filters.pop('limit', 100)
    q = DB.session.query(VSyntheseForWebAppBis)

    user_cruved = get_or_fetch_user_cruved(
        session=session,
        id_role=info_role.id_role,
        id_application_parent=14
    )

    if 'observers' in filters:
        q = q.filter(VSyntheseForWebAppBis.observers.ilike('%'+filters.pop('observers')+'%'))

    if 'date_min' in filters:
        q = q.filter(VSyntheseForWebAppBis.date_min >= filters.pop('date_min'))

    if 'date_max' in filters:
        q = q.filter(VSyntheseForWebAppBis.date_min <= filters.pop('date_max'))

    if 'areas' in filters:
        filters.pop('areas')

    if 'id_acquisition_frameworks' in filters:
        q = (q.join(TDatasets, VSyntheseForWebAppBis.id_dataset == TDatasets.id_dataset).join(
            TAcquisitionFramework, TDatasets.id_acquisition_framework == TAcquisitionFramework.id_acquisition_framework))

        q = q.filter(TAcquisitionFramework.id_acquisition_framework.in_(filters.pop('id_acquisition_frameworks')))

    # generic filters
    join_on_synthese = False
    for colname, value in filters.items():
        # join on Syntese only if cd_nomenclature filters
        if 'cd_nomenclature' in colname:
            if not join_on_synthese:
                q = q.join(Synthese, Synthese.id_synthese == VSyntheseForWebAppBis.id_synthese)
                #table_columns = table_columns + Synthese.__table__.columns
                join_on_synthese = True
            col = getattr(Synthese.__table__.columns, colname)
            q = q.filter(col.in_(value))
        else:
            col = getattr(VSyntheseForWebAppBis.__table__.columns, colname)
            q = q.filter(col.in_(value))

    q = q.order_by(
        VSyntheseForWebAppBis.date_min.desc()
    )
    data = q.limit(
        result_limit
    )

    user_datasets = TDatasets.get_user_datasets(info_role)

    features = []
    for d in data:
        feature = d.get_geofeature()
        cruved = d.get_synthese_cruved(info_role, user_cruved, user_datasets)
        feature['properties']['cruved'] = cruved
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


# data = {
#     id_dataset: 1,
#     id_nomenclature_geo_object_nature: 3,
#     id_nomenclature_grp_typ,
#     id_nomenclature_obs_meth,
#     id_nomenclature_obs_technique,
#     id_nomenclature_bio_status,
#     id_nomenclature_bio_condition
#     id_nomenclature_naturalness
#     id_nomenclature_exist_proof
#     id_nomenclature_valid_status
#     id_nomenclature_diffusion_level
#     id_nomenclature_life_stage
#     id_nomenclature_sex
#     id_nomenclature_obj_count
#     id_nomenclature_type_count
#     id_nomenclature_sensitivity
#     id_nomenclature_observation_status
#     id_nomenclature_blurring
#     id_nomenclature_source_status
#     id_nomenclature_info_geo_type
#     id_municipality
#     count_min
#     count_max
#     cd_nom


# }

# import copy
# from datetime import datetime
# @blueprint.route('/test/insert', methods=['POST'])
# def insertData():
#     for i in range(10000):
#         data = copy.deepcopy(sample_data)
#         taxon_val = [351,60612,67111,18437,8326,11165,81065,95186]
#         life_stage_val = [2,3,4,5,6,7,8,9,10,11,12,13,14,15,16,17,18,19,20,21,22,23,24,25,26,27]
#         naturality_val = [181,182,183,184,185]

#         # d1 = datetime.strptime('1/1/2008 1:30 PM', '%m/%d/%Y')
#         # d2 = datetime.strptime('1/1/20018 4:50 AM', '%m/%d/%Y')

#         # date_max = random_date(d1, d2)
#         # date_min = date_max

#         occurrences_occtax = data['properties']['t_occurrences_occtax']
#         data['properties'].pop('t_occurrences_occtax')


#         releve = TRelevesOccurrence(**data['properties'])
#         releve.geom_4326 = from_shape(generate_random_point(), srid=4326)


#         for occ in occurrences_occtax:
#             occ['id_nomenclature_naturalness'] = get_random_value(naturality_val)
#             occ['cd_nom'] = get_random_value(taxon_val)
#             counting = occ.pop('cor_counting_occtax')
#             occurrence = TOccurrencesOccurrence(**occ)

#             for count in counting:
#                 count['id_nomenclature_life_stage'] = get_random_value(life_stage_val)
#                 occurrence.cor_counting_occtax.append(CorCountingOccurrence(**count))
#         releve.t_occurrences_occtax.append(occurrence)

#         DB.session.add(releve)
#     DB.session.commit()
#     DB.session.flush()

#     return 'ça marche bien'
