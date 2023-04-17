import json
import datetime
import re
from collections import OrderedDict
from warnings import warn

from flask import (
    Blueprint,
    request,
    Response,
    current_app,
    send_from_directory,
    render_template,
    jsonify,
    g,
)
from werkzeug.exceptions import Forbidden, NotFound, BadRequest, Conflict
from werkzeug.datastructures import MultiDict
from sqlalchemy import distinct, func, desc, asc, select, case
from sqlalchemy.orm import joinedload, lazyload, selectinload
from geojson import FeatureCollection, Feature
import sqlalchemy as sa
from sqlalchemy.orm import load_only, aliased

from utils_flask_sqla.generic import serializeQuery, GenericTable
from utils_flask_sqla.response import to_csv_resp, to_json_resp, json_resp
from utils_flask_sqla_geo.generic import GenericTableGeo

from geonature.utils import filemanager
from geonature.utils.env import db, DB
from geonature.utils.errors import GeonatureApiError
from geonature.utils.utilsgeometrytools import export_as_geo_file

from geonature.core.gn_meta.models import TDatasets

from geonature.core.gn_synthese.models import (
    BibReportsTypes,
    CorAreaSynthese,
    DefaultsNomenclaturesValue,
    Synthese,
    TSources,
    VSyntheseForWebApp,
    VColorAreaTaxon,
    TReport,
    SyntheseLogEntry,
)
from geonature.core.gn_synthese.synthese_config import MANDATORY_COLUMNS

from geonature.core.gn_synthese.utils.query_select_sqla import SyntheseQuery

from geonature.core.gn_permissions import decorators as permissions
from geonature.core.gn_permissions.tools import get_scopes_by_action

from ref_geo.models import LAreas, BibAreasTypes

from apptax.taxonomie.models import (
    Taxref,
    bdc_statut_cor_text_area,
    Taxref,
    TaxrefBdcStatutCorTextValues,
    TaxrefBdcStatutTaxon,
    TaxrefBdcStatutText,
    TaxrefBdcStatutType,
    TaxrefBdcStatutValues,
    VMTaxrefListForautocomplete,
)


routes = Blueprint("gn_synthese", __name__)


############################################
########### GET OBSERVATIONS  ##############
############################################


@routes.route("/for_web", methods=["GET", "POST"])
@permissions.check_cruved_scope("R", get_scope=True, module_code="SYNTHESE")
def get_observations_for_web(scope):
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
        geojson = json.loads(r["st_asgeojson"])
        geojson["properties"] = properties

    :qparam str limit: Limit number of synthese returned. Defaults to NB_MAX_OBS_MAP.
    :qparam str cd_ref_parent: filtre tous les taxons enfants d'un TAXREF cd_ref.
    :qparam str cd_ref: Filter by TAXREF cd_ref attribute
    :qparam str taxonomy_group2_inpn: Filter by TAXREF group2_inpn attribute
    :qparam str taxonomy_id_hab: Filter by TAXREF id_habitat attribute
    :qparam str taxhub_attribut*: filtre générique TAXREF en fonction de l'attribut et de la valeur.
    :qparam str *_red_lists: filtre générique de listes rouges. Filtre sur les valeurs. Voir config.
    :qparam str *_protection_status: filtre générique de statuts (BdC Statuts). Filtre sur les types. Voir config.
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
    filters = request.json if request.is_json else {}
    if type(filters) != dict:
        raise BadRequest("Bad filters")
    result_limit = request.args.get(
        "limit", current_app.config["SYNTHESE"]["NB_MAX_OBS_MAP"], type=int
    )
    output_format = request.args.get("format", "ungrouped_geom")
    if output_format not in ["ungrouped_geom", "grouped_geom", "grouped_geom_by_areas"]:
        raise BadRequest(f"Bad format '{output_format}'")

    # Build defaut CTE observations query
    count_min_max = case(
        [
            (
                VSyntheseForWebApp.count_min != VSyntheseForWebApp.count_max,
                func.concat(VSyntheseForWebApp.count_min, " - ", VSyntheseForWebApp.count_max),
            ),
            (VSyntheseForWebApp.count_min != None, func.concat(VSyntheseForWebApp.count_min)),
        ],
        else_="",
    )

    nom_vern_or_lb_nom = func.coalesce(
        func.nullif(VSyntheseForWebApp.nom_vern, ""), VSyntheseForWebApp.lb_nom
    )

    columns = [
        "id",
        VSyntheseForWebApp.id_synthese,
        "date_min",
        VSyntheseForWebApp.date_min,
        "lb_nom",
        VSyntheseForWebApp.lb_nom,
        "cd_nom",
        VSyntheseForWebApp.cd_nom,
        "observers",
        VSyntheseForWebApp.observers,
        "dataset_name",
        VSyntheseForWebApp.dataset_name,
        "url_source",
        VSyntheseForWebApp.url_source,
        "unique_id_sinp",
        VSyntheseForWebApp.unique_id_sinp,
        "nom_vern_or_lb_nom",
        nom_vern_or_lb_nom,
        "count_min_max",
        count_min_max,
        "entity_source_pk_value",
        VSyntheseForWebApp.entity_source_pk_value,
    ]
    observations = func.json_build_object(*columns).label("obs_as_json")

    obs_query = (
        # select([VSyntheseForWebApp.id_synthese, observations])
        select([observations])
        .where(VSyntheseForWebApp.the_geom_4326.isnot(None))
        .order_by(VSyntheseForWebApp.date_min.desc())
        .limit(result_limit)
    )

    # Add filters to observations CTE query
    synthese_query_class = SyntheseQuery(
        VSyntheseForWebApp,
        obs_query,
        filters,
    )
    synthese_query_class.filter_query_all_filters(g.current_user, scope)
    obs_query = synthese_query_class.query

    if output_format == "grouped_geom_by_areas":
        # SQLAlchemy 1.4: replace column by add_columns
        obs_query = obs_query.column(VSyntheseForWebApp.id_synthese).cte("OBS")
        agg_areas = (
            select([CorAreaSynthese.id_synthese, LAreas.id_area])
            .select_from(
                CorAreaSynthese.__table__.join(
                    LAreas, LAreas.id_area == CorAreaSynthese.id_area
                ).join(
                    BibAreasTypes,
                    BibAreasTypes.id_type == LAreas.id_type,
                ),
            )
            .where(CorAreaSynthese.id_synthese == VSyntheseForWebApp.id_synthese)
            .where(
                BibAreasTypes.type_code == current_app.config["SYNTHESE"]["AREA_AGGREGATION_TYPE"]
            )
            .lateral("agg_areas")
        )
        obs_query = (
            select([LAreas.geojson_4326.label("geojson"), obs_query.c.obs_as_json])
            .select_from(
                obs_query.outerjoin(
                    agg_areas, agg_areas.c.id_synthese == obs_query.c.id_synthese
                ).outerjoin(LAreas, LAreas.id_area == agg_areas.c.id_area)
            )
            .cte("OBSERVATIONS")
        )
    else:
        # SQLAlchemy 1.4: replace column by add_columns
        obs_query = obs_query.column(VSyntheseForWebApp.st_asgeojson.label("geojson")).cte(
            "OBSERVATIONS"
        )

    if output_format == "ungrouped_geom":
        query = select([obs_query.c.geojson, obs_query.c.obs_as_json])
    else:
        # Group geometries with main query
        grouped_properties = func.json_build_object(
            "observations", func.json_agg(obs_query.c.obs_as_json).label("observations")
        )
        query = select([obs_query.c.geojson, grouped_properties]).group_by(obs_query.c.geojson)

    results = DB.session.execute(query)

    # Build final GeoJson
    geojson_features = []
    for geom_as_geojson, properties in results:
        geojson_features.append(
            Feature(
                geometry=json.loads(geom_as_geojson) if geom_as_geojson else None,
                properties=properties,
            )
        )
    return jsonify(FeatureCollection(geojson_features))


@routes.route("", methods=["GET"])
@permissions.check_cruved_scope("R", get_scope=True, module_code="SYNTHESE")
@json_resp
def get_synthese(scope):
    """Return synthese row(s) filtered by form params. NOT USED ANY MORE FOR PERFORMANCE ISSUES

    .. :quickref: Synthese; Deprecated

    .. deprecated:: 2?
    Use :route: /for_web instead

    Params must have same synthese fields names

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
    synthese_query_class.filter_query_all_filters(g.current_user, scope)
    data = DB.engine.execute(synthese_query_class.query.limit(result_limit))

    # data = q.limit(result_limit)
    columns = current_app.config["SYNTHESE"]["COLUMNS_API_SYNTHESE_WEB_APP"] + MANDATORY_COLUMNS
    features = []
    for d in data:
        feature = d.as_geofeature(fields=columns)
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
@permissions.check_cruved_scope("R", get_scope=True, module_code="SYNTHESE")
def get_one_synthese(scope, id_synthese):
    """Get one synthese record for web app with all decoded nomenclature"""
    synthese = Synthese.query.join_nomenclatures().options(
        joinedload("dataset").options(
            selectinload("acquisition_framework").options(
                joinedload("creator"),
                joinedload("nomenclature_territorial_level"),
                joinedload("nomenclature_financing_type"),
            ),
        ),
        lazyload("areas").options(
            joinedload("area_type"),
        ),
    )
    ##################

    fields = [
        "dataset",
        "dataset.acquisition_framework",
        "dataset.acquisition_framework.bibliographical_references",
        "dataset.acquisition_framework.cor_af_actor",
        "dataset.acquisition_framework.cor_objectifs",
        "dataset.acquisition_framework.cor_territories",
        "dataset.acquisition_framework.cor_volets_sinp",
        "dataset.acquisition_framework.creator",
        "dataset.acquisition_framework.nomenclature_territorial_level",
        "dataset.acquisition_framework.nomenclature_financing_type",
        "dataset.cor_dataset_actor",
        "dataset.cor_dataset_actor.role",
        "dataset.cor_dataset_actor.organism",
        "dataset.cor_territories",
        "dataset.nomenclature_source_status",
        "dataset.nomenclature_resource_type",
        "dataset.nomenclature_dataset_objectif",
        "dataset.nomenclature_data_type",
        "dataset.nomenclature_data_origin",
        "dataset.nomenclature_collecting_method",
        "dataset.creator",
        "dataset.modules",
        "validations",
        "validations.validation_label",
        "validations.validator_role",
        "cor_observers",
        "cor_observers.organisme",
        "source",
        "habitat",
        "medias",
        "areas",
        "areas.area_type",
    ]

    # get reports info only if activated by admin config
    alertModulesActivated = current_app.config["SYNTHESE"]["ALERT_MODULES"]
    if len(alertModulesActivated) and "SYNTHESE" in alertModulesActivated:
        fields.append("reports.report_type.type")
        synthese = synthese.options(lazyload(Synthese.reports).joinedload(TReport.report_type))

    synthese = synthese.get_or_404(id_synthese)

    if not synthese.has_instance_permission(scope=scope):
        raise Forbidden()

    geofeature = synthese.as_geofeature(fields=Synthese.nomenclature_fields + fields)
    return jsonify(geofeature)


################################
########### EXPORTS ############
################################


@routes.route("/export_taxons", methods=["POST"])
@permissions.check_cruved_scope("E", get_scope=True, module_code="SYNTHESE")
def export_taxon_web(scope):
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
    cruved = get_scopes_by_action(module_code="SYNTHESE")
    sub_query = (
        select(
            [
                VSyntheseForWebApp.cd_ref,
                func.count(distinct(VSyntheseForWebApp.id_synthese)).label("nb_obs"),
                func.min(VSyntheseForWebApp.date_min).label("date_min"),
                func.max(VSyntheseForWebApp.date_max).label("date_max"),
            ]
        )
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
        synthese_query_class.filter_query_with_cruved(g.current_user, scope)

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
@permissions.check_cruved_scope("E", get_scope=True, module_code="SYNTHESE")
def export_observations_web(scope):
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

    srid = DB.session.execute(func.Find_SRID("gn_synthese", "synthese", "the_geom_local")).scalar()
    # set default to csv
    export_view = GenericTableGeo(
        tableName="v_synthese_for_export",
        schemaName="gn_synthese",
        engine=DB.engine,
        geometry_field=None,
        srid=srid,
    )

    # get list of id synthese from POST
    id_list = request.get_json()

    db_cols_for_shape = []
    columns_to_serialize = []
    # loop over synthese config to get the columns for export
    for db_col in export_view.db_cols:
        if db_col.key in current_app.config["SYNTHESE"]["EXPORT_COLUMNS"]:
            db_cols_for_shape.append(db_col)
            columns_to_serialize.append(db_col.key)

    query = select([export_view.tableDef]).where(
        export_view.tableDef.columns[current_app.config["SYNTHESE"]["EXPORT_ID_SYNTHESE_COL"]].in_(
            id_list
        )
    )
    synthese_query_class = SyntheseQuery(
        export_view.tableDef,
        query,
        {},
        id_synthese_column=current_app.config["SYNTHESE"]["EXPORT_ID_SYNTHESE_COL"],
        id_dataset_column=current_app.config["SYNTHESE"]["EXPORT_ID_DATASET_COL"],
        observers_column=current_app.config["SYNTHESE"]["EXPORT_OBSERVERS_COL"],
        id_digitiser_column=current_app.config["SYNTHESE"]["EXPORT_ID_DIGITISER_COL"],
        with_generic_table=True,
    )
    # check R and E CRUVED to know if we filter with cruved
    cruved = get_scopes_by_action(module_code="SYNTHESE")
    if cruved["R"] > cruved["E"]:
        synthese_query_class.filter_query_with_cruved(g.current_user, scope)

    results = DB.session.execute(
        synthese_query_class.query.limit(current_app.config["SYNTHESE"]["NB_MAX_OBS_EXPORT"])
    )

    file_name = datetime.datetime.now().strftime("%Y_%m_%d_%Hh%Mm%S")
    file_name = filemanager.removeDisallowedFilenameChars(file_name)

    if export_format == "csv":
        formated_data = [export_view.as_dict(d, columns=columns_to_serialize) for d in results]
        return to_csv_resp(file_name, formated_data, separator=";", columns=columns_to_serialize)

    elif export_format == "geojson":
        features = []
        for r in results:
            geometry = json.loads(
                getattr(r, current_app.config["SYNTHESE"]["EXPORT_GEOJSON_4326_COL"])
            )
            feature = Feature(
                geometry=geometry,
                properties=export_view.as_dict(r, columns=columns_to_serialize),
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
@permissions.check_cruved_scope("E", get_scope=True, module_code="SYNTHESE")
def export_metadata(scope):
    """Route to export the metadata in CSV

    .. :quickref: Synthese;

    The table synthese is join with gn_synthese.v_metadata_for_export
    The column jdd_id is mandatory in the view gn_synthese.v_metadata_for_export

    POST parameters: Use a list of id_synthese (in POST parameters) to filter the v_synthese_for_export_view
    """
    filters = request.json if request.is_json else {}

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

    q = select([distinct(VSyntheseForWebApp.id_dataset), metadata_view.tableDef])
    synthese_query_class = SyntheseQuery(VSyntheseForWebApp, q, filters)
    synthese_query_class.add_join(
        metadata_view.tableDef,
        getattr(
            metadata_view.tableDef.columns,
            current_app.config["SYNTHESE"]["EXPORT_METADATA_ID_DATASET_COL"],
        ),
        VSyntheseForWebApp.id_dataset,
    )
    synthese_query_class.filter_query_all_filters(g.current_user, scope)

    data = DB.engine.execute(synthese_query_class.query)
    return to_csv_resp(
        datetime.datetime.now().strftime("%Y_%m_%d_%Hh%Mm%S"),
        data=[metadata_view.as_dict(d) for d in data],
        separator=";",
        columns=[db_col.key for db_col in metadata_view.tableDef.columns],
    )


@routes.route("/export_statuts", methods=["POST"])
@permissions.check_cruved_scope("E", get_scope=True, module_code="SYNTHESE")
def export_status(scope):
    """Route to get all the protection status of a synthese search

    .. :quickref: Synthese;

    Get the CRUVED from 'R' action because we don't give observations X/Y but only statuts
    and to be consistent with the data displayed in the web interface.

    Parameters:
        - HTTP-GET: the same that the /synthese endpoint (all the filter in web app)
    """
    filters = request.json if request.is_json else {}

    # Initalize the select object
    q = select(
        [
            distinct(VSyntheseForWebApp.cd_nom),
            Taxref.cd_ref,
            Taxref.nom_complet,
            Taxref.nom_vern,
            TaxrefBdcStatutTaxon.rq_statut,
            TaxrefBdcStatutType.regroupement_type,
            TaxrefBdcStatutType.lb_type_statut,
            TaxrefBdcStatutText.cd_sig,
            TaxrefBdcStatutText.full_citation,
            TaxrefBdcStatutText.doc_url,
            TaxrefBdcStatutValues.code_statut,
            TaxrefBdcStatutValues.label_statut,
        ]
    )

    # Initialize SyntheseQuery class
    synthese_query = SyntheseQuery(VSyntheseForWebApp, q, filters)

    synthese_query.apply_all_filters(g.current_user, scope)

    # Add join
    synthese_query.add_join(Taxref, Taxref.cd_nom, VSyntheseForWebApp.cd_nom)
    synthese_query.add_join(
        CorAreaSynthese,
        CorAreaSynthese.id_synthese,
        VSyntheseForWebApp.id_synthese,
    )
    synthese_query.add_join(
        bdc_statut_cor_text_area, bdc_statut_cor_text_area.c.id_area, CorAreaSynthese.id_area
    )
    synthese_query.add_join(TaxrefBdcStatutTaxon, TaxrefBdcStatutTaxon.cd_ref, Taxref.cd_ref)
    synthese_query.add_join(
        TaxrefBdcStatutCorTextValues,
        TaxrefBdcStatutCorTextValues.id_value_text,
        TaxrefBdcStatutTaxon.id_value_text,
    )
    synthese_query.add_join_multiple_cond(
        TaxrefBdcStatutText,
        [
            TaxrefBdcStatutText.id_text == TaxrefBdcStatutCorTextValues.id_text,
            TaxrefBdcStatutText.id_text == bdc_statut_cor_text_area.c.id_text,
        ],
    )
    synthese_query.add_join(
        TaxrefBdcStatutType,
        TaxrefBdcStatutType.cd_type_statut,
        TaxrefBdcStatutText.cd_type_statut,
    )
    synthese_query.add_join(
        TaxrefBdcStatutValues,
        TaxrefBdcStatutValues.id_value,
        TaxrefBdcStatutCorTextValues.id_value,
    )

    # Build query
    q = synthese_query.build_query()

    # Set enable status texts filter
    q = q.where(TaxrefBdcStatutText.enable == True)

    protection_status = []
    data = DB.engine.execute(q)
    for d in data:
        row = OrderedDict(
            [
                ("cd_nom", d["cd_nom"]),
                ("cd_ref", d["cd_ref"]),
                ("nom_complet", d["nom_complet"]),
                ("nom_vern", d["nom_vern"]),
                ("type_regroupement", d["regroupement_type"]),
                ("type", d["lb_type_statut"]),
                ("territoire_application", d["cd_sig"]),
                ("intitule_doc", re.sub("<[^<]+?>", "", d["full_citation"])),
                ("code_statut", d["code_statut"]),
                ("intitule_statut", d["label_statut"]),
                ("remarque", d["rq_statut"]),
                ("url_doc", d["doc_url"]),
            ]
        )
        protection_status.append(row)

    export_columns = [
        "nom_complet",
        "nom_vern",
        "cd_nom",
        "cd_ref",
        "type_regroupement",
        "type",
        "territoire_application",
        "intitule_doc",
        "code_statut",
        "intitule_statut",
        "remarque",
        "url_doc",
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
@permissions.check_cruved_scope("R", get_scope=True, module_code="SYNTHESE")
@json_resp
def general_stats(scope):
    """Return stats about synthese.

    .. :quickref: Synthese;

        - nb of observations
        - nb of distinct species
        - nb of distinct observer
        - nb of datasets
    """
    allowed_datasets = TDatasets.query.filter_by_readable().all()
    q = select(
        [
            func.count(Synthese.id_synthese),
            func.count(func.distinct(Synthese.cd_nom)),
            func.count(func.distinct(Synthese.observers)),
        ]
    )
    synthese_query_obj = SyntheseQuery(Synthese, q, {})
    synthese_query_obj.filter_query_with_cruved(g.current_user, scope)
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
        raise NotFound
    return jsonify(dict(data))


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
    page = params.get("page", 1, int)

    if "offset" in request.args:
        warn(
            "offset is deprecated, please use page for pagination (start at 1)", DeprecationWarning
        )
        page = (int(request.args["offset"]) / limit) + 1
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
    q = q.order_by(VColorAreaTaxon.cd_nom).order_by(VColorAreaTaxon.id_area)
    if len(cd_noms) > 0:
        q = q.filter(VColorAreaTaxon.cd_nom.in_(tuple(cd_noms)))
    results = q.paginate(page=page, per_page=limit, error_out=False)

    return jsonify([d.as_dict() for d in results.items])


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
    if "id_source" in params:
        query = query.filter(Synthese.id_source == params["id_source"])
    data = query.one()
    if data and data[0]:
        return Response(data[0], mimetype="application/json")
    return "", 204


@routes.route("/observation_count_per_column/<column>", methods=["GET"])
def observation_count_per_column(column):
    """Get observations count group by a given column"""
    if column not in sa.inspect(Synthese).column_attrs:
        raise BadRequest(f"No column name {column} in Synthese")
    synthese_column = getattr(Synthese, column)
    stmt = (
        DB.session.query(
            func.count(Synthese.id_synthese).label("count"),
            synthese_column.label(column),
        )
        .select_from(Synthese)
        .group_by(synthese_column)
    )
    return jsonify(DB.session.execute(stmt).fetchall())


@routes.route("/taxa_distribution", methods=["GET"])
@json_resp
def get_taxa_distribution():
    """
    Get taxa distribution for a given dataset or acquisition framework
    and grouped by a certain taxa rank
    """

    id_dataset = request.args.get("id_dataset")
    id_af = request.args.get("id_af")
    id_source = request.args.get("id_source")

    rank = request.args.get("taxa_rank")
    if not rank:
        rank = "regne"

    try:
        rank = getattr(Taxref.__table__.columns, rank)
    except AttributeError:
        raise BadRequest("Rank does not exist")

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
    # User can add id_source filter along with id_dataset or id_af
    if id_source is not None:
        query = query.filter(Synthese.id_source == id_source)

    data = query.group_by(rank).all()
    return [{"count": d[0], "group": d[1]} for d in data]


@routes.route("/reports", methods=["POST"])
@permissions.check_cruved_scope("R", get_scope=True, module_code="SYNTHESE")
@json_resp
def create_report(scope):
    """
    Create a report (e.g report) for a given synthese id

    Returns
    -------
        report: `json`:
            Every occurrence's report
    """
    session = DB.session
    data = request.get_json()
    if data is None:
        raise BadRequest("Empty request data")
    try:
        type_name = data["type"]
        id_synthese = data["item"]
        content = data["content"]
        if not id_synthese:
            raise BadRequest("id_synthese is missing from the request")
        if not type_name:
            raise BadRequest("Report type is missing from the request")
        if not content and type_name == "discussion":
            raise BadRequest("Discussion content is required")
        type_exists = BibReportsTypes.query.filter_by(type=type_name).first()
        if not type_exists:
            raise BadRequest("This report type does not exist")
        synthese = Synthese.query.get_or_404(id_synthese)
        if not synthese.has_instance_permission(scope):
            raise Forbidden
        # only allow one alert by id_synthese
        if type_name in ["alert", "pin"]:
            alert_exists = TReport.query.filter(
                TReport.id_synthese == id_synthese,
                TReport.report_type.has(BibReportsTypes.type == type_name),
            ).one_or_none()
            if alert_exists is not None:
                raise Conflict("This type already exists for this id")
    except KeyError:
        raise BadRequest("Empty request data")
    new_entry = TReport(
        id_synthese=id_synthese,
        id_role=g.current_user.id_role,
        content=content,
        creation_date=datetime.datetime.now(),
        id_type=type_exists.id_type,
    )
    session.add(new_entry)
    session.commit()


@routes.route("/reports/<int:id_report>", methods=["PUT"])
@permissions.login_required
@json_resp
def update_content_report(id_report):
    """
    Modify a report (e.g report) for a given synthese id

    Returns
    -------
        report: `json`:
            Every occurrence's report
    """
    data = request.json
    session = DB.session
    idReport = data["idReport"]
    row = TReport.query.get_or_404(idReport)
    if row.user != g.current.user:
        raise Forbidden
    row.content = data["content"]
    session.commit()


@routes.route("/reports", methods=["GET"])
@permissions.check_cruved_scope("R", get_scope=True, module_code="SYNTHESE")
def list_reports(scope):
    type_name = request.args.get("type")
    id_synthese = request.args.get("idSynthese")
    sort = request.args.get("sort")
    # VERIFY ID SYNTHESE
    synthese = Synthese.query.get_or_404(id_synthese)
    if not synthese.has_instance_permission(scope):
        raise Forbidden
    # START REQUEST
    req = TReport.query.filter(TReport.id_synthese == id_synthese)
    # SORT
    if sort == "asc":
        req = req.order_by(asc(TReport.creation_date))
    if sort == "desc":
        req = req.order_by(desc(TReport.creation_date))
    # VERIFY AND SET TYPE
    type_exists = BibReportsTypes.query.filter_by(type=type_name).one_or_none()
    # type param is not required to get all
    if type_name and not type_exists:
        raise BadRequest("This report type does not exist")
    if type_name:
        req = req.filter(TReport.report_type.has(BibReportsTypes.type == type_name))
    # filter by id_role for pin type only
    if type_name and type_name == "pin":
        req = req.filter(TReport.id_role == g.current_user.id_role)
    req = req.options(
        joinedload("user").load_only("nom_role", "prenom_role"), joinedload("report_type")
    )
    result = [
        report.as_dict(
            fields=[
                "id_report",
                "id_synthese",
                "id_role",
                "report_type.type",
                "report_type.id_type",
                "content",
                "deleted",
                "creation_date",
                "user.nom_role",
                "user.prenom_role",
            ]
        )
        for report in req.all()
    ]
    return jsonify(result)


@routes.route("/reports/<int:id_report>", methods=["DELETE"])
@permissions.login_required
@json_resp
def delete_report(id_report):
    reportItem = TReport.query.get_or_404(id_report)
    # alert control to check cruved - allow validators only
    if reportItem.report_type.type in ["alert"]:
        scope = get_scopes_by_action(module_code="VALIDATION")["C"]
        if not reportItem.synthese.has_instance_permission(scope):
            raise Forbidden("Permission required to delete this report !")
    # only owner could delete a report for pin and discussion
    if reportItem.id_role != g.current_user.id_role and reportItem.report_type.type in [
        "discussion",
        "pin",
    ]:
        raise Forbidden
    # discussion control to don't delete but tag report as deleted only
    if reportItem.report_type.type == "discussion":
        reportItem.content = ""
        reportItem.deleted = True
    else:
        DB.session.delete(reportItem)
    DB.session.commit()


@routes.route("/log", methods=["get"])
@permissions.check_cruved_scope("R", module_code="SYNTHESE")
def list_synthese_log_entries() -> dict:
    """Get log history from synthese

    Parameters
    ----------
    scope

    Returns
    -------
    dict
        log action list
    """

    deletion_entries = SyntheseLogEntry.query.options(
        load_only(
            SyntheseLogEntry.id_synthese,
            SyntheseLogEntry.last_action,
            SyntheseLogEntry.meta_last_action_date,
        )
    )
    create_update_entries = Synthese.query.with_entities(
        Synthese.id_synthese,
        db.case(
            [
                (Synthese.meta_create_date < Synthese.meta_update_date, "U"),
            ],
            else_="I",
        ).label("last_action"),
        func.coalesce(Synthese.meta_update_date, Synthese.meta_create_date).label(
            "meta_last_action_date"
        ),
    )
    query = deletion_entries.union(create_update_entries)

    # Filter
    try:
        query = query.filter_by_params(request.args)
    except ValueError as exc:
        raise BadRequest(*exc.args) from exc

    # Sort
    try:
        query = query.sort(request.args.getlist("sort"))
    except ValueError as exc:
        raise BadRequest(*exc.args) from exc

    # Paginate
    limit = request.args.get("limit", type=int, default=50)
    page = request.args.get("page", type=int, default=1)
    results = query.paginate(page=page, per_page=limit, error_out=False)

    return jsonify(
        {
            "items": [item.as_dict() for item in results.items],
            "total": results.total,
            "limit": limit,
            "page": page,
        }
    )
