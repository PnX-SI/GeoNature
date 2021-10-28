import logging
import json
import datetime
import ast
import time

from collections import OrderedDict

from flask import Blueprint, request, current_app, send_from_directory, render_template, jsonify
from sqlalchemy import distinct, func, desc, select, text
from sqlalchemy.orm import exc
from sqlalchemy.sql.expression import delete
from geojson import FeatureCollection, Feature

from utils_flask_sqla.generic import serializeQuery, GenericTable
from utils_flask_sqla.response import to_csv_resp, to_json_resp, json_resp
from utils_flask_sqla_geo.generic import GenericTableGeo

from geonature.utils import filemanager
from geonature.utils.env import DB
from geonature.utils.errors import GeonatureApiError
from geonature.utils.utilsgeometrytools import export_as_geo_file

from geonature.core.gn_meta.models import TDatasets
from geonature.core.gn_meta.repositories import get_datasets_cruved

from geonature.core.gn_synthese.models import (
    Synthese,
    TSources,
    DefaultsNomenclaturesValue,
    SyntheseOneRecord,
    VSyntheseForWebApp,
    VColorAreaTaxon,
)
from geonature.core.gn_synthese.synthese_config import MANDATORY_COLUMNS
from geonature.core.taxonomie.models import (
    Taxref,
    TaxrefProtectionArticles,
    TaxrefProtectionEspeces,
    VMTaxrefListForautocomplete,
)
from geonature.core.ref_geo.models import LAreas, BibAreasTypes
from geonature.core.gn_synthese.utils import query as synthese_query
from geonature.core.gn_synthese.utils.query_select_sqla import SyntheseQuery
from geonature.core.gn_synthese.utils.blurring import DataBlurring

from geonature.core.gn_permissions import decorators as permissions
from geonature.core.gn_permissions.tools import cruved_scope_for_user_in_module
from werkzeug.exceptions import BadRequest

# debug
# current_app.config['SQLALCHEMY_ECHO'] = True

routes = Blueprint("gn_synthese", __name__)

# get the root logger
log = logging.getLogger()


def current_milli_time():
    return time.time()


############################################
########### GET OBSERVATIONS  ##############
############################################


@routes.route("/for_web", methods=["GET", "POST"])
@permissions.check_permissions(module_code="SYNTHESE", action_code="R")
@json_resp
def get_observations_for_web(auth, permissions):
    """Optimized route to serve data for the frontend with all filters.

    .. :quickref: Synthese; Get filtered observations

    Query filtered by any filter, returning all the fields of the
    view v_synthese_for_export::

        properties = {
            "id": r["id_synthese"],
            "date_min": str(r["date_min"]),
            "cd_nom": r["cd_nom"],
            "nom_vern_or_lb_nom": r["nom_vern"] if r["nom_vern"] else r["lb_nom"],
            "lb_nom": r["lb_nom"],
            "dataset_name": r["dataset_name"],
            "observers": r["observers"],
            "url_source": r["url_source"],
            "unique_id_sinp": r["unique_id_sinp"],
            "entity_source_pk_value": r["entity_source_pk_value"],
        }
        geojson = ast.literal_eval(r["st_asgeojson"])
        geojson["properties"] = properties

    :param str auth: autorisation contenant des informations sur
        l'utilisateur et la permissions permettant l'accés au web service.
        Utiliser pour configurer les filtres, **TBC**.
    :param str permissions: listes de toutes les permissions NON applaties
        en lien avec la permission d'accès. Seul l'héritage des groupes est appliqué.
        Utiliser pour configurer les filtres, **TBC**.
    :qparam str limit: Limit number of synthese returned. Defaults to NB_MAX_OBS_MAP.
    :qparam str cd_ref: Filter by TAXREF cd_ref attribute
    :qparam str taxonomy_group2_inpn: Filter by TAXREF group2_inpn attribute
    :qparam str taxonomy_id_hab: Filter by TAXREF id_habitat attribute
    :qparam str taxonomy_lr: Filter by TAXREF cd_ref attribute
    :qparam str taxhub_attribut*: Generig TAXREF filter, given attribute & value
    :qparam str observers: Filter on observer
    :qparam str id_organism: Filter on organism
    :qparam str date_min: Start date
    :qparam str date_max: End date
    :qparam str id_acquisition_framework: *tbd*
    :qparam str geoIntersection: Intersect with the geom send from the map
    :qparam str period_start: *tbd*
    :qparam str period_end: *tbd*
    :qparam str area*: Generic filter on area
    :qparam str *: Generic filter, given by colname & value
    :>jsonarr array data: Array of synthese with geojson key, see above
    :>jsonarr int nb_total: Number of observations
    :>jsonarr bool nb_obs_limited: Is number of observations capped
    """
    if request.is_json:
        filters = request.json
    elif request.data:
        #  decode byte to str - compat python 3.5
        filters = json.loads(request.data.decode("utf-8"))
    else:
        filters = {key: request.args.get(key) for key, value in request.args.items()}

    if "limit" in filters:
        result_limit = filters.pop("limit")
    else:
        result_limit = current_app.config["SYNTHESE"]["NB_MAX_OBS_MAP"]

    columns = [
        VSyntheseForWebApp.id_synthese,
        VSyntheseForWebApp.date_min,
        VSyntheseForWebApp.lb_nom,
        VSyntheseForWebApp.cd_nom,
        VSyntheseForWebApp.nom_vern,
        VSyntheseForWebApp.count_min,
        VSyntheseForWebApp.count_max,
        VSyntheseForWebApp.st_asgeojson,
        VSyntheseForWebApp.observers,
        VSyntheseForWebApp.dataset_name,
        VSyntheseForWebApp.url_source,
        VSyntheseForWebApp.entity_source_pk_value,
        VSyntheseForWebApp.unique_id_sinp,
    ]

    if current_app.config["DATA_BLURRING"]["ENABLE_DATA_BLURRING"]:
        columns.append(VSyntheseForWebApp.id_nomenclature_sensitivity)
        columns.append(VSyntheseForWebApp.id_nomenclature_diffusion_level)

    query = (
        select(columns)
            .where(VSyntheseForWebApp.the_geom_4326.isnot(None))
            .order_by(VSyntheseForWebApp.date_min.desc())
    )
    synthese_query_class = SyntheseQuery(VSyntheseForWebApp, query, filters)
    synthese_query_class.filter_query_all_filters(auth)
    results = DB.session.execute(synthese_query_class.query.limit(result_limit))

    if current_app.config["DATA_BLURRING"]["ENABLE_DATA_BLURRING"]:
        data_blurring = DataBlurring(permissions)
        results = data_blurring.blurSeveralObs(results)

    # Group results by geometry
    seen_geoms = {}
    grouped_results = []
    for result in results:
        result = dict(result)
        for key in result.keys():
            if key != "st_asgeojson":
                result[key] = [result[key]]
        if not result["st_asgeojson"] in seen_geoms.keys():
            seen_geoms[result["st_asgeojson"]] = len(grouped_results)
            grouped_results.append(result)
        else:
            for key in result.keys():
                if key != "st_asgeojson":
                    grouped_results[seen_geoms[result["st_asgeojson"]]][key].extend(result[key])
    geojson_features = []
    for r in grouped_results:
        properties = {
            "id": r["id_synthese"],
            "date_min": [str(date) for date in r["date_min"]],
            "cd_nom": r["cd_nom"],
            "nom_vern_or_lb_nom": [r["nom_vern"][i] if r["nom_vern"][i] else r["lb_nom"][i] for i in
                                   range(len(r["lb_nom"]))],
            "lb_nom": r["lb_nom"],
            "count_min_max": [
                '{} - {}'.format(r["count_min"][i], r["count_max"][i]) if r["count_min"][i] != r["count_max"][
                    i] else str(r["count_min"][i] or '') for i in range(len(r["count_max"]))],
            "dataset_name": r["dataset_name"],
            "observers": r["observers"],
            "url_source": r["url_source"],
            "unique_id_sinp": str(r["unique_id_sinp"]),
            "entity_source_pk_value": r["entity_source_pk_value"],
        }
        geojson = json.loads(r["st_asgeojson"])
        geojson["properties"] = properties
        geojson_features.append(geojson)
    return {
        "data": FeatureCollection(geojson_features),
        "nb_total": len(geojson_features),
        "nb_obs_limited": len(geojson_features)
                          == current_app.config["SYNTHESE"]["NB_MAX_OBS_MAP"],
    }


@routes.route("", methods=["GET"])
@permissions.check_permissions(module_code="SYNTHESE", action_code="R")
@json_resp
def get_synthese(auth, permissions):
    """Return synthese row(s) filtered by form params. NOT USED ANY MORE FOR PERFORMANCE ISSUES

    .. :quickref: Synthese; Deprecated

    .. deprecated:: 2?
    Use :route: /for_web instead

    Params must have same synthese fields names

    :param str auth: autorisation contenant des informations sur
        l'utilisateur et la permissions permettant l'accés au web service.
        Utiliser pour configurer les filtres, **TBC**.
    :param str permissions: listes de toutes les permissions NON applaties
        en lien avec la permission d'accès. Seul l'héritage des groupes est appliqué.
        Utiliser pour configurer les filtres, **TBC**.
    :returns dict[dict, int, bool]: See description above
    """
    # change all args in a list of value
    filters = {key: request.args.getlist(key) for key, value in request.args.items()}
    if "limit" in filters:
        result_limit = filters.pop("limit")[0]
    else:
        result_limit = current_app.config["SYNTHESE"]["NB_MAX_OBS_MAP"]

    query = select([VSyntheseForWebApp]).order_by(VSyntheseForWebApp.date_min.desc())
    synthese_query_class = SyntheseQuery(VSyntheseForWebApp, query, filters)
    synthese_query_class.filter_query_all_filters(auth)
    data = DB.session.execute(synthese_query_class.query.limit(result_limit))

    # q = synthese_query.filter_query_all_filters(VSyntheseForWebApp, q, filters, auth)

    # data = q.limit(result_limit)
    columns = current_app.config["SYNTHESE"]["COLUMNS_API_SYNTHESE_WEB_APP"] + MANDATORY_COLUMNS
    features = []
    for d in data:
        feature = d.get_geofeature(fields=columns)
        feature["properties"]["nom_vern_or_lb_nom"] = (
            d.lb_nom if d.nom_vern is None else d.nom_vern
        )
        features.append(feature)
    return {
        "data": FeatureCollection(features),
        "nb_obs_limited": len(features) == current_app.config["SYNTHESE"]["NB_MAX_OBS_MAP"],
        "nb_total": len(features),
    }


@routes.route("/vsynthese/<id_synthese>", methods=["GET"])
@permissions.check_permissions(module_code="SYNTHESE", action_code="R")
@json_resp
def get_one_synthese(auth, permissions, id_synthese):
    """Get one synthese record for web app with all decoded nomenclature

    .. :quickref: Synthese; Get one synthese

    It returns a dict composed of the following::

        'data' dict: Array of dict (with geojson key)
        'nb_total' int: Number of observations
        'nb_obs_limited' bool: Is number of observations capped

    :param int id_synthese:Synthese to be queried
    :>jsonarr array synthese_as_dict: One synthese with geojson key, see above
    """
    metadata_view = GenericTable(
        tableName="v_metadata_for_export", schemaName="gn_synthese", engine=DB.engine
    )
    q = (
        DB.session.query(
            SyntheseOneRecord,
            getattr(
                metadata_view.tableDef.columns,
                current_app.config["SYNTHESE"]["EXPORT_METADATA_ACTOR_COL"],
            ),
        )
            .filter(SyntheseOneRecord.id_synthese == id_synthese)
            .outerjoin(
            metadata_view.tableDef,
            getattr(
                metadata_view.tableDef.columns,
                current_app.config["SYNTHESE"]["EXPORT_METADATA_ID_DATASET_COL"],
            )
            == SyntheseOneRecord.id_dataset,
        )
    )
    try:
        data = q.one()
        synthese_as_dict = data[0].as_dict(
            depth=2,
        )

        synthese_as_dict["actors"] = data[1]
        if current_app.config["DATA_BLURRING"]["ENABLE_DATA_BLURRING"]:
            data_blurring = DataBlurring(permissions)
            synthese_as_dict = data_blurring.blurOneObsAreas(synthese_as_dict)
        return synthese_as_dict
    except exc.NoResultFound:
        return None


################################
########### EXPORTS ############
################################


@routes.route("/export_taxons", methods=["POST"])
@permissions.check_cruved_scope("E", True, module_code="SYNTHESE")
def export_taxon_web(info_role):
    """Optimized route for taxon web export.

    .. :quickref: Synthese;

    This view is customisable by the administrator
    Some columns are mandatory: cd_ref

    POST parameters: Use a list of cd_ref (in POST parameters)
         to filter the v_synthese_taxon_for_export_view

    :query str export_format: str<'csv'>

    """
    taxon_view = GenericTable(
        tableName="v_synthese_taxon_for_export_view",
        schemaName="gn_synthese",
        engine=DB.engine,
    )
    columns = taxon_view.tableDef.columns
    # Test de conformité de la vue v_synthese_for_export_view
    try:
        assert hasattr(taxon_view.tableDef.columns, "cd_ref")

    except AssertionError as e:
        return (
            {
                "msg": """
                        View v_synthese_taxon_for_export_view
                        must have a cd_ref column \n
                        trace: {}
                        """.format(
                    str(e)
                )
            },
            500,
        )

    id_list = request.get_json()

    # check R and E CRUVED to know if we filter with cruved
    cruved = cruved_scope_for_user_in_module(info_role.id_role, module_code="SYNTHESE")[0]
    sub_query = (
        select([
            VSyntheseForWebApp.cd_ref,
            func.count(distinct(VSyntheseForWebApp.id_synthese)).label("nb_obs"),
            func.min(VSyntheseForWebApp.date_min).label("date_min"),
            func.max(VSyntheseForWebApp.date_max).label("date_max")
        ])
            .where(VSyntheseForWebApp.id_synthese.in_(id_list))
            .group_by(VSyntheseForWebApp.cd_ref)
    )

    synthese_query_class = SyntheseQuery(
        VSyntheseForWebApp,
        sub_query,
        {},
    )

    if cruved["R"] > cruved["E"]:
        # filter on cruved
        synthese_query_class.filter_query_with_cruved(info_role)

    subq = synthese_query_class.query.alias("subq")

    q = DB.session.query(*columns, subq.c.nb_obs, subq.c.date_min, subq.c.date_max).join(
        subq, subq.c.cd_ref == columns.cd_ref
    )
    return to_csv_resp(
        datetime.datetime.now().strftime("%Y_%m_%d_%Hh%Mm%S"),
        data=serializeQuery(q.all(), q.column_descriptions),
        separator=";",
        columns=[db_col.key for db_col in columns] + ["nb_obs", "date_min", "date_max"],
    )


@routes.route("/export_observations", methods=["POST"])
@permissions.check_permissions(module_code="SYNTHESE", action_code="E")
def export_observations_web(auth, permissions):
    """Optimized route for observations web export.

    .. :quickref: Synthese;

    This view is customisable by the administrator
    Some columns are mandatory: id_synthese, geojson and geojson_local to generate the exported files

    POST parameters: Use a list of id_synthese (in POST parameters) to filter the v_synthese_for_export_view

    :query str export_format: str<'csv', 'geojson', 'shapefiles', 'gpkg'>

    """
    params = request.args
    export_format = params.get("export_format", "csv")
    # Test export_format
    if not export_format in current_app.config["SYNTHESE"]["EXPORT_FORMAT"]:
        raise BadRequest("Unsupported format")

    # Set default to csv
    export_view = GenericTableGeo(
        tableName="v_synthese_for_export",
        schemaName="gn_synthese",
        engine=DB.engine,
        geometry_field=None,
        srid=current_app.config["LOCAL_SRID"],
    )

    # Get list of id synthese from POST
    id_list = request.get_json()

    db_cols_for_shape = []
    columns_to_serialize = []
    # Loop over synthese config to get the columns for export
    for db_col in export_view.db_cols:
        if db_col.key in current_app.config["SYNTHESE"]["EXPORT_COLUMNS"]:
            db_cols_for_shape.append(db_col)
            columns_to_serialize.append(db_col.key)

    query = select([export_view.tableDef]).where(
        export_view.tableDef.columns[current_app.config["SYNTHESE"]["EXPORT_ID_SYNTHESE_COL"]].in_(
            id_list
        )
    )
    columns_options = {
        "id_synthese_column": current_app.config["SYNTHESE"]["EXPORT_ID_SYNTHESE_COL"],
        "id_dataset_column": current_app.config["SYNTHESE"]["EXPORT_ID_DATASET_COL"],
        "observers_column": current_app.config["SYNTHESE"]["EXPORT_OBSERVERS_COL"],
        "id_digitiser_column": current_app.config["SYNTHESE"]["EXPORT_ID_DIGITISER_COL"],
    }
    if current_app.config["DATA_BLURRING"]["ENABLE_DATA_BLURRING"]:
        columns_options["sensitivity_column"] = current_app.config["DATA_BLURRING"]["EXPORT_SENSITIVITY_COL"]
        columns_options["diffusion_column"] = current_app.config["DATA_BLURRING"]["EXPORT_DIFFUSION_COL"]

    synthese_query_class = SyntheseQuery(
        export_view.tableDef,
        query,
        {},
        with_generic_table=True,
        **columns_options,
    )
    # Check R and E CRUVED to know if we filter with cruved
    cruved = cruved_scope_for_user_in_module(auth.id_role, module_code="SYNTHESE")[0]
    if cruved["R"] > cruved["E"]:
        synthese_query_class.filter_query_with_cruved(auth)
    results = DB.session.execute(synthese_query_class.query.limit(
        current_app.config["SYNTHESE"]["NB_MAX_OBS_EXPORT"])
    )

    if current_app.config["DATA_BLURRING"]["ENABLE_DATA_BLURRING"]:
        data_blurring = DataBlurring(
            permissions,
            sensitivity_column=current_app.config["DATA_BLURRING"]["EXPORT_SENSITIVITY_COL"],
            diffusion_column=current_app.config["DATA_BLURRING"]["EXPORT_DIFFUSION_COL"],
            result_to_dict=False,
            fields_to_erase=current_app.config["DATA_BLURRING"]["EXPORT_FIELDS_TO_BLURRE"],
            geom_fields=[
                {
                    "output_field": current_app.config["SYNTHESE"]["EXPORT_GEOJSON_4326_COL"],
                    "area_field": "geojson_4326",
                },
                {
                    "output_field": current_app.config["SYNTHESE"]["EXPORT_GEOJSON_LOCAL_COL"],
                    "area_field": "geom",
                    "compute": "asgeojson",
                    "srid": current_app.config["LOCAL_SRID"],
                },
                {
                    "output_field": 'x_centroid_4326',
                    "compute": "x",
                },
                {
                    "output_field": 'y_centroid_4326',
                    "compute": "y",
                },
            ]
        )
        results = data_blurring.blurSeveralObs(results)

    file_name = datetime.datetime.now().strftime("%Y_%m_%d_%Hh%Mm%S")
    file_name = filemanager.removeDisallowedFilenameChars(file_name)

    if export_format == "csv":
        formated_data = [export_view.as_dict(d, fields=columns_to_serialize) for d in results]
        return to_csv_resp(file_name, formated_data, separator=";", columns=columns_to_serialize)

    elif export_format == "geojson":
        features = []
        for r in results:
            geometry = ast.literal_eval(
                getattr(r, current_app.config["SYNTHESE"]["EXPORT_GEOJSON_4326_COL"])
            )
            feature = Feature(
                geometry=geometry,
                properties=export_view.as_dict(r, fields=columns_to_serialize),
            )
            features.append(feature)
        results = FeatureCollection(features)
        return to_json_resp(results, as_file=True, filename=file_name, indent=4)
    else:
        try:
            dir_name, file_name = export_as_geo_file(
                export_format=export_format,
                export_view=export_view,
                db_cols=db_cols_for_shape,
                geojson_col=current_app.config["SYNTHESE"]["EXPORT_GEOJSON_LOCAL_COL"],
                data=results,
                file_name=file_name,
            )
            return send_from_directory(dir_name, file_name, as_attachment=True)

        except GeonatureApiError as e:
            message = str(e)

        return render_template(
            "error.html",
            error=message,
            redirect=current_app.config["URL_APPLICATION"] + "/#/synthese",
        )


@routes.route("/export_metadata", methods=["GET", "POST"])
@permissions.check_cruved_scope("E", True, module_code="SYNTHESE")
def export_metadata(info_role):
    """Route to export the metadata in CSV

    .. :quickref: Synthese;

    The table synthese is join with gn_synthese.v_metadata_for_export
    The column jdd_id is mandatory in the view gn_synthese.v_metadata_for_export

    POST parameters: Use a list of id_synthese (in POST parameters) to filter the v_synthese_for_export_view
    """
    if request.json:
        filters = request.json
    elif request.data:
        #  decode byte to str - compat python 3.5
        filters = json.loads(request.data.decode("utf-8"))
    else:
        filters = {key: request.args.getlist(key) for key, value in request.args.items()}

    metadata_view = GenericTable(
        tableName="v_metadata_for_export", schemaName="gn_synthese", engine=DB.engine
    )
    q = DB.session.query(distinct(VSyntheseForWebApp.id_dataset), metadata_view.tableDef).join(
        metadata_view.tableDef,
        getattr(
            metadata_view.tableDef.columns,
            current_app.config["SYNTHESE"]["EXPORT_METADATA_ID_DATASET_COL"],
        )
        == VSyntheseForWebApp.id_dataset,
    )

    q = select([
        distinct(VSyntheseForWebApp.id_dataset), metadata_view.tableDef
    ])
    synthese_query_class = SyntheseQuery(VSyntheseForWebApp, q, filters)
    synthese_query_class.add_join(
        metadata_view.tableDef,
        getattr(
            metadata_view.tableDef.columns,
            current_app.config["SYNTHESE"]["EXPORT_METADATA_ID_DATASET_COL"],
        ),
        VSyntheseForWebApp.id_dataset
    )
    synthese_query_class.filter_query_all_filters(info_role)

    data = DB.session.execute(synthese_query_class.query)
    return to_csv_resp(
        datetime.datetime.now().strftime("%Y_%m_%d_%Hh%Mm%S"),
        data=[metadata_view.as_dict(d) for d in data],
        separator=";",
        columns=[db_col.key for db_col in metadata_view.tableDef.columns],
    )


@routes.route("/export_statuts", methods=["POST"])
@permissions.check_cruved_scope("E", True, module_code="SYNTHESE")
def export_status(info_role):
    """Route to get all the protection status of a synthese search

    .. :quickref: Synthese;

    Get the CRUVED from 'R' action because we don't give observations X/Y but only statuts
    and to be constistant with the data displayed in the web interface

    Parameters:
        - HTTP-GET: the same that the /synthese endpoint (all the filter in web app)
    """
    if request.json:
        filters = request.json
    elif request.data:
        #  decode byte to str - compat python 3.5
        filters = json.loads(request.data.decode("utf-8"))
    else:
        filters = {key: request.args.getlist(key) for key, value in request.args.items()}

    # initalize the select object
    q = select(
        [
            distinct(VSyntheseForWebApp.cd_nom),
            Taxref.nom_complet,
            Taxref.cd_ref,
            Taxref.nom_vern,
            TaxrefProtectionArticles.type_protection,
            TaxrefProtectionArticles.article,
            TaxrefProtectionArticles.intitule,
            TaxrefProtectionArticles.arrete,
            TaxrefProtectionArticles.date_arrete,
            TaxrefProtectionArticles.url,
        ]
    )

    synthese_query_class = SyntheseQuery(VSyntheseForWebApp, q, filters)

    # add join
    synthese_query_class.add_join(Taxref, Taxref.cd_nom, VSyntheseForWebApp.cd_nom)
    synthese_query_class.add_join(
        TaxrefProtectionEspeces,
        TaxrefProtectionEspeces.cd_nom,
        VSyntheseForWebApp.cd_nom,
    )
    synthese_query_class.add_join(
        TaxrefProtectionArticles,
        TaxrefProtectionArticles.cd_protection,
        TaxrefProtectionEspeces.cd_protection,
    )
    # filter with all get params
    q = synthese_query_class.filter_query_all_filters(info_role)

    data = DB.session.execute(q)

    protection_status = []
    for d in data:
        row = OrderedDict(
            [
                ("nom_complet", d["nom_complet"]),
                ("nom_vern", d["nom_vern"]),
                ("cd_nom", d["cd_nom"]),
                ("cd_ref", d["cd_ref"]),
                ("type_protection", d["type_protection"]),
                ("article", d["article"]),
                ("intitule", d["intitule"]),
                ("arrete", d["arrete"]),
                ("date_arrete", d["date_arrete"]),
                ("url", d["url"]),
            ]
        )
        protection_status.append(row)

    export_columns = [
        "nom_complet",
        "nom_vern",
        "cd_nom",
        "cd_ref",
        "type_protection",
        "article",
        "intitule",
        "arrete",
        "date_arrete",
        "url",
    ]

    return to_csv_resp(
        datetime.datetime.now().strftime("%Y_%m_%d_%Hh%Mm%S"),
        protection_status,
        separator=";",
        columns=export_columns,
    )


######################################
########### OTHERS ROUTES ############
######################################


@routes.route("/general_stats", methods=["GET"])
@permissions.check_cruved_scope("R", True)
@json_resp
def general_stats(info_role):
    """Return stats about synthese.

    .. :quickref: Synthese;

        - nb of observations
        - nb of distinct species
        - nb of distinct observer
        - nb of datasets
    """
    allowed_datasets = get_datasets_cruved(info_role)
    q = select(
        [
            func.count(Synthese.id_synthese),
            func.count(func.distinct(Synthese.cd_nom)),
            func.count(func.distinct(Synthese.observers))
        ]
    )
    synthese_query_obj = SyntheseQuery(Synthese, q, {})
    synthese_query_obj.filter_query_with_cruved(info_role)
    result = DB.session.execute(synthese_query_obj.query)
    synthese_counts = result.fetchone()

    data = {
        "nb_data": synthese_counts[0],
        "nb_species": synthese_counts[1],
        "nb_observers": synthese_counts[2],
        "nb_dataset": len(allowed_datasets),
    }
    return data


@routes.route("/taxons_tree", methods=["GET"])
@json_resp
def get_taxon_tree():
    """Get taxon tree.

    .. :quickref: Synthese;
    """
    taxon_tree_table = GenericTable(
        tableName="v_tree_taxons_synthese", schemaName="gn_synthese", engine=DB.engine
    )
    data = DB.session.query(taxon_tree_table.tableDef).all()
    return [taxon_tree_table.as_dict(d) for d in data]


@routes.route("/taxons_autocomplete", methods=["GET"])
@json_resp
def get_autocomplete_taxons_synthese():
    """Autocomplete taxon for web search (based on all taxon in Synthese).

    .. :quickref: Synthese;

    The request use trigram algorithm to get relevent results

    :query str search_name: the search name (use sql ilike statement and puts "%" for spaces)
    :query str regne: filter with kingdom
    :query str group2_inpn : filter with INPN group 2
    """
    search_name = request.args.get("search_name", "")
    q = (
        DB.session.query(
            VMTaxrefListForautocomplete,
            func.similarity(VMTaxrefListForautocomplete.search_name, search_name).label(
                "idx_trgm"
            ),
        )
            .distinct()
            .join(Synthese, Synthese.cd_nom == VMTaxrefListForautocomplete.cd_nom)
    )
    search_name = search_name.replace(" ", "%")
    q = q.filter(VMTaxrefListForautocomplete.search_name.ilike("%" + search_name + "%"))
    regne = request.args.get("regne")
    if regne:
        q = q.filter(VMTaxrefListForautocomplete.regne == regne)

    group2_inpn = request.args.get("group2_inpn")
    if group2_inpn:
        q = q.filter(VMTaxrefListForautocomplete.group2_inpn == group2_inpn)

    q = q.order_by(desc(VMTaxrefListForautocomplete.cd_nom == VMTaxrefListForautocomplete.cd_ref))
    limit = request.args.get("limit", 20)
    data = q.order_by(desc("idx_trgm")).limit(20).all()
    return [d[0].as_dict() for d in data]


@routes.route("/sources", methods=["GET"])
@json_resp
def get_sources():
    """Get all sources.

    .. :quickref: Synthese;
    """
    q = DB.session.query(TSources)
    data = q.all()
    return [n.as_dict() for n in data]


@routes.route("/defaultsNomenclatures", methods=["GET"])
@json_resp
def getDefaultsNomenclatures():
    """Get default nomenclatures

    .. :quickref: Synthese;

    :query str group2_inpn:
    :query str regne:
    :query int organism:
    """
    params = request.args
    group2_inpn = "0"
    regne = "0"
    organism = 0
    if "group2_inpn" in params:
        group2_inpn = params["group2_inpn"]
    if "regne" in params:
        regne = params["regne"]
    if "organism" in params:
        organism = params["organism"]
    types = request.args.getlist("mnemonique_type")

    q = DB.session.query(
        distinct(DefaultsNomenclaturesValue.mnemonique_type),
        func.gn_synthese.get_default_nomenclature_value(
            DefaultsNomenclaturesValue.mnemonique_type, organism, regne, group2_inpn
        ),
    )
    if len(types) > 0:
        q = q.filter(DefaultsNomenclaturesValue.mnemonique_type.in_(tuple(types)))
    data = q.all()
    if not data:
        return {"message": "not found"}, 404
    return {d[0]: d[1] for d in data}


@routes.route("/color_taxon", methods=["GET"])
def get_color_taxon():
    """Get color of taxon in areas (vue synthese.v_color_taxon_area).

    .. :quickref: Synthese;

    :query str code_area_type: Type area code (ref_geo.bib_areas_types.type_code)
    :query int id_area: Id of area (ref_geo.l_areas.id_area)
    :query int cd_nom: taxon code (taxonomie.taxref.cd_nom)
    Those three parameters can be multiples
    :returns: Array<dict<VColorAreaTaxon>>
    """
    params = request.args
    limit = int(params.get("limit", 100))
    offset = int(params.get("offset", 0))
    id_areas_type = params.getlist("code_area_type")
    cd_noms = params.getlist("cd_nom")
    id_areas = params.getlist("id_area")
    q = DB.session.query(VColorAreaTaxon)
    if len(id_areas_type) > 0:
        q = q.join(LAreas, LAreas.id_area == VColorAreaTaxon.id_area).join(
            BibAreasTypes, BibAreasTypes.id_type == LAreas.id_type
        )
        q = q.filter(BibAreasTypes.type_code.in_(tuple(id_areas_type)))
    if len(id_areas) > 0:
        # check if the join already done on l_areas
        if not LAreas in [mapper.class_ for mapper in q._join_entities]:
            q = q.join(LAreas, LAreas.id_area == VColorAreaTaxon.id_area)
        q = q.filter(LAreas.id_area.in_(tuple(id_areas)))
    if len(cd_noms) > 0:
        q = q.filter(VColorAreaTaxon.cd_nom.in_(tuple(cd_noms)))
    data = q.limit(limit).offset(offset).all()

    return jsonify([d.as_dict() for d in data])


@routes.route("/taxa_count", methods=["GET"])
@json_resp
def get_taxa_count():
    """
    Get taxa count in synthese filtering with generic parameters

    .. :quickref: Synthese;

    Parameters
    ----------
    id_dataset: `int` (query parameter)

    Returns
    -------
    count: `int`:
        the number of taxon
    """
    params = request.args

    query = DB.session.query(func.count(distinct(Synthese.cd_nom))).select_from(Synthese)

    if "id_dataset" in params:
        query = query.filter(Synthese.id_dataset == params["id_dataset"])
    return query.one()


@routes.route("/observation_count", methods=["GET"])
@json_resp
def get_observation_count():
    """
    Get observations found in a given dataset

    .. :quickref: Synthese;

    Parameters
    ----------
    id_dataset: `int` (query parameter)

    Returns
    -------
    count: `int`:
        the number of observation

    """
    params = request.args

    query = DB.session.query(func.count(Synthese.id_synthese)).select_from(Synthese)

    if "id_dataset" in params:
        query = query.filter(Synthese.id_dataset == params["id_dataset"])

    return query.one()


@routes.route("/observations_bbox", methods=["GET"])
@json_resp
def get_bbox():
    """
    Get bbbox of observations

    .. :quickref: Synthese;

    Parameters
    -----------
    id_dataset: int: (query parameter)

    Returns
    -------
        bbox: `geojson`:
            the bounding box in geojson
    """
    params = request.args

    query = DB.session.query(func.ST_AsGeoJSON(func.ST_Extent(Synthese.the_geom_4326)))

    if "id_dataset" in params:
        query = query.filter(Synthese.id_dataset == params["id_dataset"])
    data = query.one()
    if data and data[0]:
        return json.loads(data[0])
    return None


@routes.route("/observation_count_per_column/<column>", methods=["GET"])
@json_resp
def observation_count_per_column(column):
    """Get observations count group by a given column"""
    params = request.args
    try:
        model_column = getattr(Synthese, column)
    except Exception:
        return f'No column name {column} in Synthese', 500
    query = DB.session.query(
        func.count(Synthese.id_synthese), model_column
    ).select_from(
        Synthese
    ).group_by(model_column)
    data = []
    for d in query.all():
        temp = {}
        temp[column] = d[1]
        temp['count'] = d[0]
        data.append(temp)
    return data


@routes.route("/taxa_distribution", methods=["GET"])
@json_resp
def get_taxa_distribution():
    """
    Get taxa distribution for a given dataset or acquisition framework
    and grouped by a certain taxa rank
    """

    id_dataset = request.args.get("id_dataset")
    id_af = request.args.get("id_af")

    rank = request.args.get("taxa_rank")
    if not rank:
        rank = "regne"

    rank = getattr(Taxref.__table__.columns, rank)

    Taxref.group2_inpn

    query = (
        DB.session.query(func.count(distinct(Synthese.cd_nom)), rank)
            .select_from(Synthese)
            .outerjoin(Taxref, Taxref.cd_nom == Synthese.cd_nom)
    )

    if id_dataset:
        query = query.filter(Synthese.id_dataset == id_dataset)

    elif id_af:
        query = query.outerjoin(TDatasets, TDatasets.id_dataset == Synthese.id_dataset).filter(
            TDatasets.id_acquisition_framework == id_af
        )

    data = query.group_by(rank).all()
    return [{"count": d[0], "group": d[1]} for d in data]

# @routes.route("/test", methods=["GET"])
# @json_resp
# def test():
#     from shapely.geometry import asShape
#     from geoalchemy2.shape import from_shape
#     from shapely.geometry import Point
#     import random

#     s = DB.session.query(Synthese).get(2)

#     s_as_dict = s.as_dict()
#     s_as_dict.pop("unique_id_sinp")
#     # wkt = asShape(s.the_geom_4326)
#     # print(wkt)
#     # releve.geom_4326 = from_shape(shape, srid=4326)
#     import datetime

#     DB.session.query()
#     for i in range(1000):
#         new_point = Point(random.uniform(6.1, 7.5), random.uniform(44.0, 45.2))
#         wkb = from_shape(new_point, 4326)
#         s_as_dict["id_synthese"] = random.randint(1500, 999999999)

#         # with random cd_nom
#         random_cd_nom = DB.session.execute(
#             """
#         SELECT cd_nom FROM taxonomie.bib_noms OFFSET random() * (select count(*) from taxonomie.bib_noms) limit 1 ;"""
#         )
#         cd_nom = None
#         for cd in random_cd_nom:
#             s_as_dict["cd_nom"] = cd[0]
#         new_synthese = Synthese(**s_as_dict)
#         new_synthese.the_geom_4326 = wkb
#         new_synthese.the_geom_local = func.st_transform(wkb, 2154)

#         new_date = datetime.datetime.now()
#         new_date = new_date.replace(year=random.randint(2000, 2016))
#         new_synthese.date_min = new_date
#         new_synthese.date_max = new_date
#         print(new_synthese.the_geom_local)
#         q = DB.session.add(new_synthese)
#         # DB.session.flush()
#         DB.session.commit()

#     # s = TSources(name_source="lalala")

#     # DB.session.add(s)
#     # DB.session.commit()
#     return "la"
