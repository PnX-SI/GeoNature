import logging
import datetime
from collections import OrderedDict

from flask import Blueprint, request, current_app, send_from_directory, render_template
from sqlalchemy import distinct, func, desc
from sqlalchemy.orm import exc
from sqlalchemy.sql import text
from geojson import FeatureCollection


from geonature.utils import filemanager
from geonature.utils.env import DB, ROOT_DIR
from geonature.utils.utilsgeometry import FionaShapeService

from geonature.core.gn_synthese.models import (
    Synthese,
    TSources,
    DefaultsNomenclaturesValue,
    SyntheseOneRecord,
    VMTaxonsSyntheseAutocomplete,
    VSyntheseForWebApp, VSyntheseForExport
)
from geonature.core.gn_synthese.synthese_config import MANDATORY_COLUMNS
from geonature.core.taxonomie.models import (
    Taxref,
    TaxrefProtectionArticles,
    TaxrefProtectionEspeces
)
from geonature.core.gn_synthese.utils import query as synthese_query

from geonature.core.gn_meta.models import TDatasets

from pypnusershub import routes as fnauth

from geonature.utils.utilssqlalchemy import (
    to_csv_resp, to_json_resp,
    json_resp, GenericTable
)


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
    """
    filters = {key: value[0].split(',') for key, value in dict(request.args).items()}
    if 'limit' in filters:
        result_limit = filters.pop('limit')[0]
    else:
        result_limit = current_app.config['SYNTHESE']['NB_MAX_OBS_MAP']

    allowed_datasets = TDatasets.get_user_datasets(info_role)

    q = DB.session.query(VSyntheseForWebApp)

    q = synthese_query.filter_query_all_filters(VSyntheseForWebApp, q, filters, info_role, allowed_datasets)
    q = q.order_by(
        VSyntheseForWebApp.date_min.desc()
    )
    nb_total = 0

    data = q.limit(result_limit)
    columns = current_app.config['SYNTHESE']['COLUMNS_API_SYNTHESE_WEB_APP'] + MANDATORY_COLUMNS
    features = []
    for d in data:
        feature = d.get_geofeature(
            columns=columns
        )
        feature['properties']['nom_vern_or_lb_nom'] = d.lb_nom if d.nom_vern is None else d.nom_vern
        features.append(feature)
    return {
        'data': FeatureCollection(features),
        'nb_obs_limited': nb_total == current_app.config['SYNTHESE']['NB_MAX_OBS_MAP'],
        'nb_total': nb_total
    }


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
        result_limit = current_app.config['SYNTHESE']['NB_MAX_OBS_EXPORT']

    export_format = filters.pop('export_format')[0]
    allowed_datasets = TDatasets.get_user_datasets(info_role)

    q = DB.session.query(VSyntheseForExport)
    q = synthese_query.filter_query_all_filters(VSyntheseForExport, q, filters, info_role, allowed_datasets)

    q = q.order_by(
        VSyntheseForExport.date_min.desc()
    )
    data = q.limit(result_limit)

    file_name = datetime.datetime.now().strftime('%Y_%m_%d_%Hh%Mm%S')
    file_name = filemanager.removeDisallowedFilenameChars(file_name)

    if export_format == 'csv':
        formated_data = [d.as_dict_ordered() for d in data]
        return to_csv_resp(
            file_name,
            formated_data,
            separator=';',
            columns=[value for key, value in current_app.config['SYNTHESE']['EXPORT_COLUMNS'].items()]
        )

    elif export_format == 'geojson':
        formated_data = [d.get_geofeature_ordered() for d in data]
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
        filemanager.delete_recursively(str(ROOT_DIR / 'backend/static/shapefiles'), excluded_files=['.gitkeep'])

        dir_path = str(ROOT_DIR / 'backend/static/shapefiles')
        FionaShapeService.create_shapes_struct(
            db_cols=VSyntheseForExport.db_cols,
            srid=current_app.config['LOCAL_SRID'],
            dir_path=dir_path,
            file_name=file_name,
            col_mapping=current_app.config['SYNTHESE']['EXPORT_COLUMNS']
        )
        for row in data:
            geom = row.the_geom_local
            row_as_dict = row.as_dict_ordered()
            FionaShapeService.create_feature(row_as_dict, geom)

        FionaShapeService.save_and_zip_shapefiles()

        return send_from_directory(
            dir_path,
            file_name+'.zip',
            as_attachment=True
        )


@routes.route('/statuts', methods=['GET'])
@fnauth.check_auth_cruved('E', True)
def get_status(info_role):
    """
    Route to get all the protection status of a synthese search
    """

    filters = dict(request.args)

    q = (DB.session.query(distinct(VSyntheseForWebApp.cd_nom), Taxref, TaxrefProtectionArticles)
         .join(
        Taxref, Taxref.cd_nom == VSyntheseForWebApp.cd_nom
    ).join(
        TaxrefProtectionEspeces, TaxrefProtectionEspeces.cd_nom == VSyntheseForWebApp.cd_nom
    ).join(
        TaxrefProtectionArticles, TaxrefProtectionArticles.cd_protection == TaxrefProtectionEspeces.cd_protection
    ))

    allowed_datasets = TDatasets.get_user_datasets(info_role)
    q = synthese_query.filter_query_all_filters(VSyntheseForWebApp, q, filters, info_role, allowed_datasets)
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
    data = DB.session.query(
        taxon_tree_table.tableDef
    ).all()
    return [taxon_tree_table.as_dict(d) for d in data]


@routes.route('/taxons_autocomplete', methods=['GET'])
@json_resp
def get_autocomplete_taxons_synthese():

    search_name = request.args.get('search_name')
    q = DB.session.query(VMTaxonsSyntheseAutocomplete)
    if search_name:
        search_name = search_name.replace(' ', '%')
        q = q.filter(
            VMTaxonsSyntheseAutocomplete.search_name.ilike(search_name+"%")
        )
    regne = request.args.get('regne')
    if regne:
        q = q.filter(VMTaxonsSyntheseAutocomplete.regne == regne)

    group2_inpn = request.args.get('group2_inpn')
    if group2_inpn:
        q = q.filter(VMTaxonsSyntheseAutocomplete.group2_inpn == group2_inpn)

    q = q.order_by(desc(
        VMTaxonsSyntheseAutocomplete.cd_nom ==
        VMTaxonsSyntheseAutocomplete.cd_ref
    ))

    data = q.limit(20).all()
    return [d.as_dict() for d in data]
