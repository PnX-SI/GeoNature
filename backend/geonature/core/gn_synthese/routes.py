import json
import logging
import datetime

from collections import OrderedDict

from flask import Blueprint, request, session, current_app, send_from_directory, render_template
from sqlalchemy import distinct, func
from sqlalchemy.orm import exc
from sqlalchemy.sql import text
from geojson import FeatureCollection

from geonature.utils import filemanager
from geonature.utils.env import DB, ROOT_DIR
from geonature.utils.errors import GeonatureApiError
from geonature.utils.utilsgeometry import FionaShapeService

from geonature.core.gn_synthese.models import (
    Synthese,
    TSources,
    CorAreaSynthese,
    DefaultsNomenclaturesValue,
    VSyntheseDecodeNomenclatures,
    SyntheseOneRecord,
)
from geonature.core.taxonomie.models import (
    Taxref,
    TaxrefProtectionArticles,
    TaxrefProtectionEspeces
)
from geonature.core.gn_synthese import repositories as synthese_repository

from geonature.core.gn_meta.models import (
    TDatasets,

)
from geonature.core.ref_geo.models import (
    LiMunicipalities, LAreas
)
from pypnusershub import routes as fnauth
from pypnusershub.db.tools import (
    InsufficientRightsError,
    get_or_fetch_user_cruved,
    cruved_for_user_in_app
)
from geonature.utils.utilssqlalchemy import (
    to_csv_resp, to_json_resp,
    json_resp, testDataType, GenericTable
)

from geonature.core.gn_meta import mtd_utils

# debug
# current_app.config['SQLALCHEMY_ECHO'] = True

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


@routes.route('', methods=['GET'])
@fnauth.check_auth_cruved('R', True)
@json_resp
def get_synthese(info_role):
    """
        return synthese row(s) filtered by form params
        Params must have same synthese fields names
        'observers' param (string) is filtered with ilike clause
    """

    filters = dict(request.args)

    if 'limit' in filters:
        result_limit = filters.pop('limit')[0]
    else:
        result_limit = 10000

    allowed_datasets = TDatasets.get_user_datasets(info_role)
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
    q = synthese_repository.filter_query_all_filters(q, filters, info_role, allowed_datasets)
    q = q.order_by(
        Synthese.date_min.desc()
    )
    data = q.limit(result_limit)
    print(q)
    features = []
    for d in data:
        print(d)
        feature = d[0].get_geofeature(columns=['date_min', 'observers', 'id_synthese'])
        # cruved = d[0].get_synthese_cruved(info_role, user_cruved, allowed_datasets)
        feature['properties']['taxon'] = d[1].as_dict(columns=['nom_valide', 'cd_nom'])
        feature['properties']['sources'] = d[2].as_dict(columns=['entity_source_pk_field', 'url_source'])
        feature['properties']['dataset'] = d[3].as_dict(columns=['dataset_name'])
        features.append(feature)
    return FeatureCollection(features)


@routes.route('/vsynthese/<id_synthese>', methods=['GET'])
@json_resp
def get_one_synthese(id_synthese):
    """
        Retourne un enregistrement de la synthese
        avec les nomenclatures décodées pour la webapp
    """

    q = DB.session.query(SyntheseOneRecord).filter(
        SyntheseOneRecord.id_synthese == id_synthese
    )
    try:
        data = q.one()
        return data.as_dict(True)
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
    # TODO
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


@routes.route('/export', methods=['GET'])
@fnauth.check_auth_cruved('E', True)
def export(info_role):
    filters = dict(request.args)
    if 'limit' in filters:
        result_limit = filters.pop('limit')[0]
    else:
        result_limit = 40000

    export_format = filters.pop('export_format')[0]
    allowed_datasets = TDatasets.get_user_datasets(info_role)
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
    q = synthese_repository.filter_query_all_filters(q, filters, info_role, allowed_datasets)
    q = q.add_entity(VSyntheseDecodeNomenclatures)
    q = q.join(
        VSyntheseDecodeNomenclatures,
        VSyntheseDecodeNomenclatures.id_synthese == Synthese.id_synthese
    )

    q = q.order_by(
        Synthese.date_min.desc()
    )
    data = q.limit(result_limit)

    file_name = datetime.datetime.now().strftime('%Y_%m_%d_%Hh%Mm%S')
    file_name = filemanager.removeDisallowedFilenameChars(file_name)

    synthese_columns = current_app.config['SYNTHESE']['EXPORT_COLUMNS']['SYNTHESE_COLUMNS']
    nomenclature_columns = current_app.config['SYNTHESE']['EXPORT_COLUMNS']['NOMENCLATURE_COLUMNS']
    taxonomic_columns = current_app.config['SYNTHESE']['EXPORT_COLUMNS']['TAXONOMIC_COLUMNS']

    formated_data = []
    for d in data:
        synthese = d[0].as_dict(columns=synthese_columns)
        taxon = d[1].as_dict(columns=taxonomic_columns)
        dataset = d[3].as_dict(columns='dataset_name')
        decoded = d[4].as_dict(columns=nomenclature_columns)
        synthese.update(taxon)
        synthese.update(dataset)
        synthese.update(decoded)
        formated_data.append(synthese)

    export_columns = formated_data[0].keys()
    if export_format == 'csv':
        return to_csv_resp(
            file_name,
            formated_data,
            separator=';',
            columns=export_columns,
        )

    elif export_format == 'geojson':
        results = FeatureCollection(
            formated_data
        )
        return to_json_resp(
            results,
            as_file=True,
            filename=file_name,
            indent=4
        )
    else:
        try:

            db_cols_synthese = [
                db_col for db_col in Synthese.__mapper__.c
                if not db_col.type.__class__.__name__ == 'Geometry' and
                db_col.key in synthese_columns
            ]
            db_cols_nomenclature = [
                db_col for db_col in VSyntheseDecodeNomenclatures.__mapper__.c
                if db_col.key in nomenclature_columns
            ]
            db_cols_taxonomy = [
                db_col for db_col in Taxref.__mapper__.c
                if db_col.key in taxonomic_columns
            ]

            db_cols = db_cols_synthese + db_cols_nomenclature + db_cols_taxonomy
            dir_path = str(ROOT_DIR / 'backend/static/shapefiles')
            FionaShapeService.create_shapes_struct(
                db_cols=db_cols,
                srid=current_app.config['LOCAL_SRID'],
                dir_path=dir_path,
                file_name=file_name
            )
            for row in data:
                synthese_row_as_dict = row[0].as_dict(columns=synthese_columns)
                nomenclature_row_as_dict = row[4].as_dict(columns=nomenclature_columns)
                taxon_row_as_dict = row[1].as_dict(columns=taxonomic_columns)
                geom = row[0].the_geom_local
                row_as_dict = {**synthese_row_as_dict, **nomenclature_row_as_dict, **taxon_row_as_dict}
                FionaShapeService.create_feature(row_as_dict, geom)

            FionaShapeService.save_and_zip_shapefiles()

            return send_from_directory(
                dir_path,
                file_name+'.zip',
                as_attachment=True
            )

        except GeonatureApiError as e:
            message = str(e)

        return render_template(
            'error.html',
            error=message,
            redirect=current_app.config['URL_APPLICATION']+"/#/synthese"
        )


@routes.route('/statuts', methods=['GET'])
@fnauth.check_auth_cruved('E', True)
def get_status(info_role):
    """
    Route to get all the protection status of a synthese search
    """

    filters = dict(request.args)

    q = DB.session.query(distinct(Synthese.cd_nom), Taxref, TaxrefProtectionArticles).join(
        Taxref, Taxref.cd_nom == Synthese.cd_nom
    ).join(
        TaxrefProtectionEspeces, TaxrefProtectionEspeces.cd_nom == Synthese.cd_nom
    ).join(
        TaxrefProtectionArticles, TaxrefProtectionArticles.cd_protection == TaxrefProtectionEspeces.cd_protection
    )

    allowed_datasets = TDatasets.get_user_datasets(info_role)
    q = synthese_repository.filter_query_all_filters(q, filters, info_role, allowed_datasets)
    data = q.all()

    protection_status = []
    for d in data:
        taxon = d[1].as_dict()
        protection = d[2].as_dict()
        row = OrderedDict([
            ('nom_complet', taxon['nom_complet']),
            ('nom_vern', taxon['nom_vern']),
            ('cd_nom', taxon['cd_nom']),
            ('cd_ref', taxon['cd_ref']),
            ('type_protection', protection['type_protection']),
            ('article', protection['article']),
            ('intitule', protection['intitule']),
            ('arrete', protection['arrete']),
            ('date_arrete', protection['date_arrete']),
            ('url', protection['url']),
        ])
        protection_status.append(row)

    export_columns = [
        'nom_complet', 'nom_vern', 'cd_nom', 'cd_ref', 'type_protection',
        'article', 'intitule', 'arrete', 'date_arrete', 'url'
    ]

    file_name = datetime.datetime.now().strftime('%Y_%m_%d_%Hh%Mm%S')
    return to_csv_resp(
        file_name,
        protection_status,
        separator=';',
        columns=export_columns,
    )


@routes.route('/taxons_tree', methods=['GET'])
@json_resp
def get_taxon_tree():
    taxon_tree_table = GenericTable('v_tree_taxons_synthese', 'gn_synthese', geometry_field=None)
    data = DB.session.query(taxon_tree_table.tableDef).order_by(taxon_tree_table.tableDef.c.nom_latin).all()
    return [taxon_tree_table.as_dict(d) for d in data]
