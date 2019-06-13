import logging
import datetime
import ast

from collections import OrderedDict

from flask import Blueprint, request, current_app, send_from_directory, render_template
from sqlalchemy import distinct, func, desc, select
from sqlalchemy.orm import exc
from sqlalchemy.sql import text
from geojson import FeatureCollection, Feature


from geonature.utils import filemanager
from geonature.utils.env import DB, ROOT_DIR
from geonature.utils.errors import GeonatureApiError

from geonature.utils.utilsgeometry import FionaShapeService

from geonature.core.gn_synthese.models import (
    Synthese,
    TSources,
    DefaultsNomenclaturesValue,
    SyntheseOneRecord,
    VMTaxonsSyntheseAutocomplete,
    VSyntheseForWebApp,
    VColorAreaTaxon,
)
from geonature.core.gn_synthese.synthese_config import MANDATORY_COLUMNS
from geonature.core.taxonomie.models import (
    Taxref,
    TaxrefProtectionArticles,
    TaxrefProtectionEspeces,
)
from geonature.core.ref_geo.models import LAreas, BibAreasTypes
from geonature.core.gn_synthese.utils import query as synthese_query
from geonature.core.gn_synthese.utils import query_select_sqla as synthese_query_select
from geonature.core.gn_synthese.utils.query_select_sqla import SyntheseQuery

from geonature.core.gn_meta.models import TDatasets

from geonature.core.gn_permissions import decorators as permissions
from geonature.core.gn_permissions.tools import cruved_scope_for_user_in_module

from geonature.utils.utilssqlalchemy import (
    to_csv_resp,
    to_json_resp,
    json_resp,
    GenericTable,
    csv_resp,
)

# debug
# current_app.config['SQLALCHEMY_ECHO'] = True

routes = Blueprint("gn_synthese", __name__)

# get the root logger
log = logging.getLogger()


import time


def current_milli_time():
    return time.time()


############################################
########### GET OBSERVATIONS  ##############
############################################


@routes.route("/for_web", methods=["GET"])
@permissions.check_cruved_scope("R", True, module_code="SYNTHESE")
@json_resp
def get_observations_for_web(info_role):
    """
        Optimized route for serve data to the frontend with all filters
        .. :quickref: Synthese;
        :query: all the fields of the view v_synthese_for_export
        :returns: Array of dict (with geojson key)
    """
    filters = {key: request.args.getlist(key) for key, value in request.args.items()}
    if "limit" in filters:
        result_limit = filters.pop("limit")[0]
    else:
        result_limit = current_app.config["SYNTHESE"]["NB_MAX_OBS_MAP"]
    query = (
        select(
            [
                VSyntheseForWebApp.id_synthese,
                VSyntheseForWebApp.date_min,
                VSyntheseForWebApp.lb_nom,
                VSyntheseForWebApp.cd_nom,
                VSyntheseForWebApp.nom_vern,
                VSyntheseForWebApp.st_asgeojson,
                VSyntheseForWebApp.observers,
                VSyntheseForWebApp.dataset_name,
                VSyntheseForWebApp.url_source,
                VSyntheseForWebApp.entity_source_pk_value,
            ]
        )
        .where(VSyntheseForWebApp.the_geom_4326.isnot(None))
        .order_by(VSyntheseForWebApp.date_min.desc())
    )
    synthese_query_class = SyntheseQuery(VSyntheseForWebApp, query, filters)
    synthese_query_class.filter_query_all_filters(info_role)
    result = DB.engine.execute(synthese_query_class.query.limit(result_limit))
    geojson_features = []
    for r in result:
        properties = {
            "id": r["id_synthese"],
            "date_min": str(r["date_min"]),
            "cd_nom": r["cd_nom"],
            "nom_vern_or_lb_nom": r["nom_vern"] if r["nom_vern"] else r["lb_nom"],
            "lb_nom": r["lb_nom"],
            "dataset_name": r["dataset_name"],
            "observers": r["observers"],
            "url_source": r["url_source"],
            "entity_source_pk_value": r["entity_source_pk_value"],
        }
        geojson = ast.literal_eval(r["st_asgeojson"])
        geojson["properties"] = properties
        geojson_features.append(geojson)
    return {
        "data": FeatureCollection(geojson_features),
        "nb_total": len(geojson_features),
        "nb_obs_limited": len(geojson_features)
        == current_app.config["SYNTHESE"]["NB_MAX_OBS_MAP"],
    }


@routes.route("", methods=["GET"])
@permissions.check_cruved_scope("R", True, module_code="SYNTHESE")
@json_resp
def get_synthese(info_role):
    """
        Return synthese row(s) filtered by form params NOT USE ANY MORE FOR PERFORMANCE ISSUES
        .. :quickref: Synthese;
        Params must have same synthese fields names
        
    """
    # change all args in a list of value
    filters = {key: request.args.getlist(key) for key, value in request.args.items()}
    if "limit" in filters:
        result_limit = filters.pop("limit")[0]
    else:
        result_limit = current_app.config["SYNTHESE"]["NB_MAX_OBS_MAP"]

    q = DB.session.query(VSyntheseForWebApp)

    q = synthese_query.filter_query_all_filters(
        VSyntheseForWebApp, q, filters, info_role
    )
    q = q.order_by(VSyntheseForWebApp.date_min.desc())

    data = q.limit(result_limit)
    columns = (
        current_app.config["SYNTHESE"]["COLUMNS_API_SYNTHESE_WEB_APP"]
        + MANDATORY_COLUMNS
    )
    features = []
    for d in data:
        feature = d.get_geofeature(columns=columns)
        feature["properties"]["nom_vern_or_lb_nom"] = (
            d.lb_nom if d.nom_vern is None else d.nom_vern
        )
        features.append(feature)
    return {
        "data": FeatureCollection(features),
        "nb_obs_limited": len(features)
        == current_app.config["SYNTHESE"]["NB_MAX_OBS_MAP"],
        "nb_total": len(features),
    }


@routes.route("/vsynthese/<id_synthese>", methods=["GET"])
@json_resp
def get_one_synthese(id_synthese):
    """
        Get one synthese record for web app with all decoded nomenclature
        .. :quickref: Synthese;

        :params id_synthese:
        :type id_synthese: int
    """
    metadata_view = GenericTable("v_metadata_for_export", "gn_synthese", None)
    q = (
        DB.session.query(
            SyntheseOneRecord,
            getattr(
                metadata_view.tableDef.columns,
                current_app.config["SYNTHESE"]["EXPORT_METADATA_ACTOR_COL"],
            ),
        )
        .filter(SyntheseOneRecord.id_synthese == id_synthese)
        .join(
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
        synthese_as_dict = data[0].as_dict(True)
        synthese_as_dict["actors"] = data[1]
        return synthese_as_dict
    except exc.NoResultFound:
        return None


################################
########### EXPORTS ############
################################


@routes.route("/export_observations", methods=["POST"])
@permissions.check_cruved_scope("E", True, module_code="SYNTHESE")
def export_observations_web(info_role):
    """
        Optimized route for observations web export
        .. :quickref: Synthese;
        This view is customisable by the administrator
        Some columns arer mandatory: id_sythese, geojson and geojson_local to generate the exported files
        
        POST parameters: Use a list of id_synthese (in POST parameters) to filter the v_synthese_for_export_view
        
        :query str export_format: str<'csv', 'geojson', 'shapefiles'>

    """
    params = request.args
    # set default to csv
    export_format = "csv"
    export_view = GenericTable(
        "v_synthese_for_export",
        "gn_synthese",
        "the_geom_local",
        current_app.config["LOCAL_SRID"],
    )
    if "export_format" in params:
        export_format = params["export_format"]

    # get list of id synthese from POST
    id_list = request.get_json()

    db_cols_for_shape = []
    columns_to_serialize = []
    # loop over synthese config to get the columns for export
    for db_col in export_view.db_cols:
        if db_col.key in current_app.config["SYNTHESE"]["EXPORT_COLUMNS"]:
            db_cols_for_shape.append(db_col)
            columns_to_serialize.append(db_col.key)

    q = DB.session.query(export_view.tableDef).filter(
        export_view.tableDef.columns.idSynthese.in_(id_list)
    )
    # check R and E CRUVED to know if we filter with cruved
    cruved = cruved_scope_for_user_in_module(info_role.id_role, module_code="SYNTHESE")[
        0
    ]
    if cruved["R"] > cruved["E"]:
        # filter on cruved specifying the column
        # id_dataset, id_synthese, id_digitiser and observer in the v_synthese_for_export_view
        q = synthese_query.filter_query_with_cruved(
            export_view.tableDef,
            q,
            info_role,
            id_synthese_column=current_app.config["SYNTHESE"]["EXPORT_ID_SYNTHESE_COL"],
            id_dataset_column=current_app.config["SYNTHESE"]["EXPORT_ID_DATASET_COL"],
            observers_column=current_app.config["SYNTHESE"]["EXPORT_OBSERVERS_COL"],
            id_digitiser_column=current_app.config["SYNTHESE"][
                "EXPORT_ID_DIGITISER_COL"
            ],
            with_generic_table=True,
        )
    results = q.limit(current_app.config["SYNTHESE"]["NB_MAX_OBS_EXPORT"])

    file_name = datetime.datetime.now().strftime("%Y_%m_%d_%Hh%Mm%S")
    file_name = filemanager.removeDisallowedFilenameChars(file_name)

    # columns = [db_col.key for db_col in export_view.db_cols]

    if export_format == "csv":
        formated_data = [
            export_view.as_dict(d, columns=columns_to_serialize) for d in results
        ]
        return to_csv_resp(
            file_name, formated_data, separator=";", columns=columns_to_serialize
        )

    elif export_format == "geojson":
        features = []
        for r in results:
            geometry = ast.literal_eval(
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
            filemanager.delete_recursively(
                str(ROOT_DIR / "backend/static/shapefiles"), excluded_files=[".gitkeep"]
            )

            dir_path = str(ROOT_DIR / "backend/static/shapefiles")

            export_view.as_shape(
                db_cols=db_cols_for_shape,
                data=results,
                geojson_col=current_app.config["SYNTHESE"]["EXPORT_GEOJSON_LOCAL_COL"],
                dir_path=dir_path,
                file_name=file_name,
            )
            return send_from_directory(dir_path, file_name + ".zip", as_attachment=True)

        except GeonatureApiError as e:
            message = str(e)

        return render_template(
            "error.html",
            error=message,
            redirect=current_app.config["URL_APPLICATION"] + "/#/synthese",
        )


@routes.route("/export_metadata", methods=["GET"])
@permissions.check_cruved_scope("E", True, module_code="SYNTHESE")
def export_metadata(info_role):
    """
        Route to export the metadata in CSV
        .. :quickref: Synthese;
        The table synthese is join with gn_synthese.v_metadata_for_export
        The column jdd_id is mandatory in the view gn_synthese.v_metadata_for_export

        POST parameters: Use a list of id_synthese (in POST parameters) to filter the v_synthese_for_export_view
    """
    filters = {key: request.args.getlist(key) for key, value in request.args.items()}

    metadata_view = GenericTable("v_metadata_for_export", "gn_synthese", None)
    q = DB.session.query(
        distinct(VSyntheseForWebApp.id_dataset), metadata_view.tableDef
    ).join(
        metadata_view.tableDef,
        getattr(
            metadata_view.tableDef.columns,
            current_app.config["SYNTHESE"]["EXPORT_METADATA_ID_DATASET_COL"],
        )
        == VSyntheseForWebApp.id_dataset,
    )

    q = synthese_query.filter_query_all_filters(
        VSyntheseForWebApp, q, filters, info_role
    )

    return to_csv_resp(
        datetime.datetime.now().strftime("%Y_%m_%d_%Hh%Mm%S"),
        data=[metadata_view.as_dict(d) for d in q.all()],
        separator=";",
        columns=[db_col.key for db_col in metadata_view.tableDef.columns],
    )


@routes.route("/export_statuts", methods=["GET"])
@permissions.check_cruved_scope("R", True, module_code="SYNTHESE")
def export_status(info_role):
    """
    Route to get all the protection status of a synthese search
    .. :quickref: Synthese;
    Parameters:
        - HTTP-GET: the same that the /synthese endpoint (all the filter in web app)
    Get the CRUVED from 'R' action because we don't give observations X/Y but only statuts
    and to be constistant with the data displayed in the web interface
    """
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

    data = DB.engine.execute(q)

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
    """
    .. :quickref: Synthese;
    Return stats about synthese
        - nb of observations
        - nb of distinct species
        - nb of distinct observer
        - nb ob datasets
    """
    allowed_datasets = TDatasets.get_user_datasets(info_role)
    q = DB.session.query(
        func.count(Synthese.id_dataset),
        func.count(func.distinct(Synthese.cd_nom)),
        func.count(func.distinct(Synthese.observers)),
    )
    q = synthese_query.filter_query_with_cruved(Synthese, q, info_role)
    data = q.one()
    data = {
        "nb_data": data[0],
        "nb_species": data[1],
        "nb_observers": data[2],
        "nb_dataset": len(allowed_datasets),
    }
    return data


@routes.route("/taxons_tree", methods=["GET"])
@json_resp
def get_taxon_tree():
    """
    Get taxon tree
    .. :quickref: Synthese;
    """
    taxon_tree_table = GenericTable(
        "v_tree_taxons_synthese", "gn_synthese", geometry_field=None
    )
    data = DB.session.query(taxon_tree_table.tableDef).all()
    return [taxon_tree_table.as_dict(d) for d in data]


@routes.route("/taxons_autocomplete", methods=["GET"])
@json_resp
def get_autocomplete_taxons_synthese():
    """
        Autocomplete taxon for web search (based on all taxon in Synthese)
        The request use trigram algorithm to get relevent results
        .. :quickref: Synthese;

        :query str search_name: the search name (use sql ilike statement and puts "%" for spaces)
        :query str regne: filter with kingdom
        :query str group2_inpn : filter with INPN group 2
    """
    search_name = request.args.get("search_name", "")
    q = DB.session.query(
        VMTaxonsSyntheseAutocomplete,
        func.similarity(VMTaxonsSyntheseAutocomplete.search_name, search_name).label(
            "idx_trgm"
        ),
    )
    search_name = search_name.replace(" ", "%")
    q = q.filter(
        VMTaxonsSyntheseAutocomplete.search_name.ilike("%" + search_name + "%")
    )
    regne = request.args.get("regne")
    if regne:
        q = q.filter(VMTaxonsSyntheseAutocomplete.regne == regne)

    group2_inpn = request.args.get("group2_inpn")
    if group2_inpn:
        q = q.filter(VMTaxonsSyntheseAutocomplete.group2_inpn == group2_inpn)

    q = q.order_by(
        desc(VMTaxonsSyntheseAutocomplete.cd_nom == VMTaxonsSyntheseAutocomplete.cd_ref)
    )
    limit = request.args.get("limit", 20)
    data = q.order_by(desc("idx_trgm")).limit(20).all()
    return [d[0].as_dict() for d in data]


@routes.route("/sources", methods=["GET"])
@json_resp
def get_sources():
    """
        Get all sources
        .. :quickref: Synthese;
    """
    q = DB.session.query(TSources)
    data = q.all()
    return [n.as_dict() for n in data]


@routes.route("/defaultsNomenclatures", methods=["GET"])
@json_resp
def getDefaultsNomenclatures():
    """
        Get default nomenclatures
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
    try:
        data = q.all()
    except Exception:
        DB.session.rollback()
        raise
    if not data:
        return {"message": "not found"}, 404
    return {d[0]: d[1] for d in data}


@routes.route("/color_taxon", methods=["GET"])
@json_resp
def get_color_taxon():
    """
    Get color of taxon in areas (table synthese.cor_area_taxon)
    .. :quickref: Synthese;
    :query str code_area_type: Type area code (ref_geo.bib_areas_types.type_code)
    :query int id_area: Id of area (ref_geo.l_areas.id_area)
    :query int cd_nom: taxon code (taxonomie.taxref.cd_nom)
    Those three parameters can be multiples
    Returns: Array<dict<VColorAreaTaxon>>
    """
    params = request.args
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
    return [d.as_dict() for d in q.all()]
