import logging
import datetime
import ast

from collections import OrderedDict

from flask import Blueprint, request, current_app, send_from_directory, render_template
from sqlalchemy import distinct, func, desc, select
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
    DefaultsNomenclaturesValue,
    SyntheseOneRecord,
    VMTaxonsSyntheseAutocomplete,
    VSyntheseForWebApp,
)
from geonature.core.gn_synthese.synthese_config import MANDATORY_COLUMNS
from geonature.core.taxonomie.models import (
    Taxref,
    TaxrefProtectionArticles,
    TaxrefProtectionEspeces,
)
from geonature.core.gn_synthese.utils import query as synthese_query
from geonature.core.gn_synthese.utils import query_select_sqla as synthese_query_select
from geonature.core.gn_synthese.utils.query_select_sqla import SyntheseQuery

from geonature.core.gn_meta.models import TDatasets

from geonature.core.gn_permissions import decorators as permissions

from geonature.utils.utilssqlalchemy import (
    to_csv_resp,
    to_json_resp,
    json_resp,
    GenericTable,
)


# debug
# current_app.config['SQLALCHEMY_ECHO'] = True

routes = Blueprint("gn_synthese", __name__)

# get the root logger
log = logging.getLogger()


@routes.route("/sources", methods=["GET"])
@json_resp
def get_sources():
    q = DB.session.query(TSources)
    data = q.all()
    return [n.as_dict() for n in data]


@routes.route("/defaultsNomenclatures", methods=["GET"])
@json_resp
def getDefaultsNomenclatures():
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


import time


def current_milli_time():
    return time.time()


@routes.route("", methods=["GET"])
@permissions.check_cruved_scope("R", True, module_code="SYNTHESE")
@json_resp
def get_synthese(info_role):
    """
        return synthese row(s) filtered by form params
        Params must have same synthese fields names
        NOT USE ANY MORE FOR PERFORMANCE ISSUES
    """
    # change all args in a list of value
    filters = {key: request.args.getlist(key) for key, value in request.args.items()}
    if "limit" in filters:
        result_limit = filters.pop("limit")[0]
    else:
        result_limit = current_app.config["SYNTHESE"]["NB_MAX_OBS_MAP"]

    allowed_datasets = TDatasets.get_user_datasets(info_role)

    q = DB.session.query(VSyntheseForWebApp)

    q = synthese_query.filter_query_all_filters(
        VSyntheseForWebApp, q, filters, info_role, allowed_datasets
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


@routes.route("/statuts", methods=["GET"])
@permissions.check_cruved_scope("E", True, module_code="SYNTHESE")
def get_status(info_role):
    """
    Route to get all the protection status of a synthese search
    """

    filters = dict(request.args)

    q = (
        DB.session.query(
            distinct(VSyntheseForWebApp.cd_nom), Taxref, TaxrefProtectionArticles
        )
        .join(Taxref, Taxref.cd_nom == VSyntheseForWebApp.cd_nom)
        .join(
            TaxrefProtectionEspeces,
            TaxrefProtectionEspeces.cd_nom == VSyntheseForWebApp.cd_nom,
        )
        .join(
            TaxrefProtectionArticles,
            TaxrefProtectionArticles.cd_protection
            == TaxrefProtectionEspeces.cd_protection,
        )
    )

    allowed_datasets = TDatasets.get_user_datasets(info_role)
    q = synthese_query.filter_query_all_filters(
        VSyntheseForWebApp, q, filters, info_role, allowed_datasets
    )
    data = q.all()

    protection_status = []
    for d in data:
        taxon = d[1].as_dict()
        protection = d[2].as_dict()
        row = OrderedDict(
            [
                ("nom_complet", taxon["nom_complet"]),
                ("nom_vern", taxon["nom_vern"]),
                ("cd_nom", taxon["cd_nom"]),
                ("cd_ref", taxon["cd_ref"]),
                ("type_protection", protection["type_protection"]),
                ("article", protection["article"]),
                ("intitule", protection["intitule"]),
                ("arrete", protection["arrete"]),
                ("date_arrete", protection["date_arrete"]),
                ("url", protection["url"]),
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

    file_name = datetime.datetime.now().strftime("%Y_%m_%d_%Hh%Mm%S")
    return to_csv_resp(
        file_name, protection_status, separator=";", columns=export_columns
    )


@routes.route("/taxons_tree", methods=["GET"])
@json_resp
def get_taxon_tree():
    taxon_tree_table = GenericTable(
        "v_tree_taxons_synthese", "gn_synthese", geometry_field=None
    )
    data = DB.session.query(taxon_tree_table.tableDef).all()
    return [taxon_tree_table.as_dict(d) for d in data]


@routes.route("/taxons_autocomplete", methods=["GET"])
@json_resp
def get_autocomplete_taxons_synthese():
    """
        Route utilisée pour les autocompletes de la synthese (basé
        sur tous les taxon présent dans la synthese)
        La requête SQL utilise l'algorithme 
        des trigrames pour améliorer la pertinence des résultats

        params GET:
            - search_name : nom recherché. Recherche basé sur la fonction
                ilike de sql avec un remplacement des espaces par %
            - regne : filtre sur le regne INPN
            - group2_inpn : filtre sur le groupe 2 de l'INPN
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


@routes.route("/general_stats", methods=["GET"])
@permissions.check_cruved_scope("R", True)
@json_resp
def general_stats(info_role):
    """
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
    q = synthese_query.filter_query_with_cruved(
        Synthese, q, info_role, allowed_datasets
    )
    data = q.one()
    data = {
        "nb_data": data[0],
        "nb_species": data[1],
        "nb_observers": data[2],
        "nb_dataset": len(allowed_datasets),
    }
    return data


@routes.route("/for_web", methods=["GET"])
@permissions.check_cruved_scope("R", True, module_code="SYNTHESE")
@json_resp
def synthese_for_web(info_role):
    """
        Optimized route for serve data to the frontend with all filters
    """
    start = current_milli_time()
    filters = {key: request.args.getlist(key) for key, value in request.args.items()}
    if "limit" in filters:
        result_limit = filters.pop("limit")[0]
    else:
        result_limit = current_app.config["SYNTHESE"]["NB_MAX_OBS_MAP"]
    query = select(
        [
            VSyntheseForWebApp.id_synthese,
            VSyntheseForWebApp.date_min,
            VSyntheseForWebApp.lb_nom,
            VSyntheseForWebApp.nom_vern,
            VSyntheseForWebApp.st_asgeojson,
            VSyntheseForWebApp.observers,
            VSyntheseForWebApp.dataset_name,
            VSyntheseForWebApp.url_source,
        ]
    )
    synthese_query_class = SyntheseQuery(VSyntheseForWebApp, query, filters)
    allowed_datasets = TDatasets.get_user_datasets(info_role)

    synthese_query_class.filter_query_with_cruved(info_role, allowed_datasets)

    synthese_query_class.filter_taxonomy()
    synthese_query_class.filter_other_filters()

    # check if there are join to do
    if synthese_query_class.query_joins is not None:
        synthese_query_class.query = synthese_query_class.query.select_from(
            synthese_query_class.query_joins
        )

    result = DB.engine.execute(synthese_query_class.query.limit(result_limit))
    formated_result = []
    for r in result:
        temp = {
            "id": r["id_synthese"],
            "date_min": str(r["date_min"]),
            "nom_vern_or_lb_nom": r["nom_vern"] if r["nom_vern"] else r["lb_nom"],
            "geometry": ast.literal_eval(r["st_asgeojson"]),
            "dataset_name": r["dataset_name"],
            "observers": r["observers"],
            "url_source": r["url_source"],
        }
        formated_result.append(temp)
    return {
        "data": formated_result,
        "nb_total": len(formated_result),
        "nb_obs_limited": len(formated_result)
        == current_app.config["SYNTHESE"]["NB_MAX_OBS_MAP"],
    }


@routes.route("/export", methods=["POST"])
# @permissions.check_cruved_scope("R", True, module_code="SYNTHESE")
def export_test():
    start = current_milli_time()
    params = request.args
    # set default to csv
    export_format = "csv"
    if "export_format" in params:
        export_format = params["export_format"]
        if params["export_format"] == "geojson":
            export_view = GenericTable(
                "v_synthese_for_export", "gn_synthese", "the_geom_local", 2154
            )
        else:
            export_view = GenericTable(
                "v_synthese_for_export", "gn_synthese", "the_geom_local", 2154
            )
    else:
        export_view = GenericTable(
            "v_synthese_for_export", "gn_synthese", "the_geom_local", 2154
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

    q = (
        DB.session.query(export_view.tableDef)
        .filter(export_view.tableDef.columns.idSynthese.in_(id_list))
        .filter(export_view.tableDef.columns.jddId.in_([1, 2]))
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
        formated_data = []
        for r in results:
            geojson = ast.literal_eval(r.geojson)
            geojson["properties"] = export_view.as_dict(r, columns=columns_to_serialize)
            formated_data.append(geojson)
        results = FeatureCollection(formated_data)
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
                geojson_col="geojson_local",
                dir_path=dir_path,
                file_name=file_name,
            )
            print("END SERIALIZ")
            print(current_milli_time() - start)
            return send_from_directory(dir_path, file_name + ".zip", as_attachment=True)

        except GeonatureApiError as e:
            message = str(e)

        return render_template(
            "error.html",
            error=message,
            redirect=current_app.config["URL_APPLICATION"] + "/#/synthese",
        )
