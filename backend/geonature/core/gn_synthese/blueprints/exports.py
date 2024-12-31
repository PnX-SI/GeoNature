import datetime
import json
import re
from collections import OrderedDict

from flask import (
    Blueprint,
    current_app,
    g,
    render_template,
    request,
    send_from_directory,
)

from geojson import Feature, FeatureCollection
from geonature.core.gn_permissions.decorators import permissions_required
from geonature.core.gn_synthese.models import (
    CorAreaSynthese,
    Synthese,
    VSyntheseForWebApp,
)
from geonature.core.gn_synthese.synthese_config import MANDATORY_COLUMNS
from geonature.core.gn_synthese.utils.blurring import (
    build_allowed_geom_cte,
    build_blurred_precise_geom_queries,
    split_blurring_precise_permissions,
)
from geonature.core.gn_synthese.utils.query_select_sqla import SyntheseQuery
from geonature.utils import filemanager
from geonature.utils.env import DB, db
from geonature.utils.errors import GeonatureApiError
from geonature.utils.utilsgeometrytools import export_as_geo_file

from apptax.taxonomie.models import (
    Taxref,
    TaxrefBdcStatutCorTextValues,
    TaxrefBdcStatutTaxon,
    TaxrefBdcStatutText,
    TaxrefBdcStatutType,
    TaxrefBdcStatutValues,
    bdc_statut_cor_text_area,
)

from sqlalchemy import distinct, func, select
from utils_flask_sqla.generic import GenericTable, serializeQuery
from utils_flask_sqla.response import to_csv_resp, to_json_resp
from utils_flask_sqla_geo.generic import GenericTableGeo
from werkzeug.exceptions import BadRequest, Forbidden

export_routes = Blueprint("exports", __name__)


@export_routes.route("/export_taxons", methods=["POST"])
@permissions_required("E", module_code="SYNTHESE")
def export_taxon_web(permissions):
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

    sub_query = (
        select(
            VSyntheseForWebApp.cd_ref,
            func.count(distinct(VSyntheseForWebApp.id_synthese)).label("nb_obs"),
            func.min(VSyntheseForWebApp.date_min).label("date_min"),
            func.max(VSyntheseForWebApp.date_max).label("date_max"),
        )
        .where(VSyntheseForWebApp.id_synthese.in_(id_list))
        .group_by(VSyntheseForWebApp.cd_ref)
    )

    synthese_query_class = SyntheseQuery(
        VSyntheseForWebApp,
        sub_query,
        {},
    )

    synthese_query_class.filter_query_all_filters(g.current_user, permissions)

    subq = synthese_query_class.query.alias("subq")

    query = select(*columns, subq.c.nb_obs, subq.c.date_min, subq.c.date_max).join(
        subq, subq.c.cd_ref == columns.cd_ref
    )

    return to_csv_resp(
        datetime.datetime.now().strftime("%Y_%m_%d_%Hh%Mm%S"),
        data=serializeQuery(db.session.execute(query).all(), query.column_descriptions),
        separator=";",
        columns=[db_col.key for db_col in columns] + ["nb_obs", "date_min", "date_max"],
    )


@export_routes.route("/export_observations", methods=["POST"])
@permissions_required("E", module_code="SYNTHESE")
def export_observations_web(permissions):
    """Optimized route for observations web export.

    .. :quickref: Synthese;

    This view is customisable by the administrator
    Some columns are mandatory: id_synthese, geojson and geojson_local to generate the exported files

    POST parameters: Use a list of id_synthese (in POST parameters) to filter the v_synthese_for_export_view

    :query str export_format: str<'csv', 'geojson', 'shapefiles', 'gpkg'>
    :query str export_format: str<'csv', 'geojson', 'shapefiles', 'gpkg'>

    """
    params = request.args
    # set default to csv
    export_format = params.get("export_format", "csv")
    view_name_param = params.get("view_name", "gn_synthese.v_synthese_for_export")
    # Test export_format
    if export_format not in current_app.config["SYNTHESE"]["EXPORT_FORMAT"]:
        raise BadRequest("Unsupported format")
    config_view = {
        "view_name": "gn_synthese.v_synthese_for_web_app",
        "geojson_4326_field": "geojson_4326",
        "geojson_local_field": "geojson_local",
    }
    # Test export view name is config params for security reason
    if view_name_param != "gn_synthese.v_synthese_for_export":
        try:
            config_view = next(
                _view
                for _view in current_app.config["SYNTHESE"]["EXPORT_OBSERVATIONS_CUSTOM_VIEWS"]
                if _view["view_name"] == view_name_param
            )
        except StopIteration:
            raise Forbidden("This view is not available for export")

    geojson_4326_field = config_view["geojson_4326_field"]
    geojson_local_field = config_view["geojson_local_field"]
    try:
        schema_name, view_name = view_name_param.split(".")
    except ValueError:
        raise BadRequest("view_name parameter must be a string with schema dot view_name")

    # get list of id synthese from POST
    id_list = request.get_json()

    # Get the SRID for the export
    local_srid = DB.session.execute(
        func.Find_SRID("gn_synthese", "synthese", "the_geom_local")
    ).scalar()

    blurring_permissions, precise_permissions = split_blurring_precise_permissions(permissions)

    # Get the view for export
    # Useful to have geom column so that they can be replaced by blurred geoms
    # (only if the user has sensitive permissions)
    export_view = GenericTableGeo(
        tableName=view_name,
        schemaName=schema_name,
        engine=DB.engine,
        geometry_field=None,
        srid=local_srid,
    )
    mandatory_columns = {"id_synthese", geojson_4326_field, geojson_local_field}
    if not mandatory_columns.issubset(set(map(lambda col: col.name, export_view.db_cols))):
        print(set(map(lambda col: col.name, export_view.db_cols)))
        raise BadRequest(
            f"The view {view_name} miss one of required columns {str(mandatory_columns)}"
        )

    # If there is no sensitive permissions => same path as before blurring implementation
    if not blurring_permissions:
        # Get the CTE for synthese filtered by user permissions
        synthese_query_class = SyntheseQuery(
            Synthese,
            select(Synthese.id_synthese),
            {},
        )
        synthese_query_class.filter_query_all_filters(g.current_user, permissions)
        cte_synthese_filtered = synthese_query_class.build_query().cte("cte_synthese_filtered")
        selectable_columns = [export_view.tableDef]
    else:
        # Use slightly the same process as for get_observations_for_web()
        # Add a where_clause to filter the id_synthese provided to reduce the
        # UNION queries
        where_clauses = [Synthese.id_synthese.in_(id_list)]
        blurred_geom_query, precise_geom_query = build_blurred_precise_geom_queries(
            filters={}, where_clauses=where_clauses
        )

        cte_synthese_filtered = build_allowed_geom_cte(
            blurring_permissions=blurring_permissions,
            precise_permissions=precise_permissions,
            blurred_geom_query=blurred_geom_query,
            precise_geom_query=precise_geom_query,
            limit=current_app.config["SYNTHESE"]["NB_MAX_OBS_EXPORT"],
        )

        # Overwrite geometry columns to compute the blurred geometry from the blurring cte
        columns_with_geom_excluded = [
            col
            for col in export_view.tableDef.columns
            if col.name
            not in [
                "geometrie_wkt_4326",  # FIXME: hardcoded column names?
                "x_centroid_4326",
                "y_centroid_4326",
                geojson_4326_field,
                geojson_local_field,
            ]
        ]
        # Recomputed the blurred geometries
        blurred_geom_columns = [
            func.st_astext(cte_synthese_filtered.c.geom).label("geometrie_wkt_4326"),
            func.st_x(func.st_centroid(cte_synthese_filtered.c.geom)).label("x_centroid_4326"),
            func.st_y(func.st_centroid(cte_synthese_filtered.c.geom)).label("y_centroid_4326"),
            func.st_asgeojson(cte_synthese_filtered.c.geom).label(geojson_4326_field),
            func.st_asgeojson(func.st_transform(cte_synthese_filtered.c.geom, local_srid)).label(
                geojson_local_field
            ),
        ]

        # Finally provide all the columns to be selected in the export query
        selectable_columns = columns_with_geom_excluded + blurred_geom_columns

    # Get the query for export
    export_query = (
        select(*selectable_columns)
        .select_from(
            export_view.tableDef.join(
                cte_synthese_filtered,
                cte_synthese_filtered.c.id_synthese == export_view.tableDef.columns["id_synthese"],
            )
        )
        .where(export_view.tableDef.columns["id_synthese"].in_(id_list))
    )

    # Get the results for export
    results = DB.session.execute(
        export_query.limit(current_app.config["SYNTHESE"]["NB_MAX_OBS_EXPORT"])
    )

    db_cols_for_shape = []
    columns_to_serialize = []
    # loop over synthese config to exclude columns if its default export
    for db_col in export_view.db_cols:
        if view_name_param == "gn_synthese.v_synthese_for_export":
            if db_col.key in current_app.config["SYNTHESE"]["EXPORT_COLUMNS"]:
                db_cols_for_shape.append(db_col)
                columns_to_serialize.append(db_col.key)
        else:
            # remove geojson fields of serialization
            if db_col.key not in [geojson_4326_field, geojson_local_field]:
                db_cols_for_shape.append(db_col)
                columns_to_serialize.append(db_col.key)

    file_name = datetime.datetime.now().strftime("%Y_%m_%d_%Hh%Mm%S")
    file_name = filemanager.removeDisallowedFilenameChars(file_name)

    if export_format == "csv":
        formated_data = [export_view.as_dict(d, fields=columns_to_serialize) for d in results]
        return to_csv_resp(file_name, formated_data, separator=";", columns=columns_to_serialize)
    elif export_format == "geojson":
        features = []
        for r in results:
            geometry = json.loads(getattr(r, geojson_4326_field))
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
                geojson_col=geojson_local_field,
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


# TODO: Change the following line to set method as "POST" only ?
@export_routes.route("/export_metadata", methods=["GET", "POST"])
@permissions_required("E", module_code="SYNTHESE")
def export_metadata(permissions):
    """Route to export the metadata in CSV

    .. :quickref: Synthese;

    The table synthese is join with gn_synthese.v_metadata_for_export
    The column jdd_id is mandatory in the view gn_synthese.v_metadata_for_export

    TODO: Remove the following comment line ? or add the where clause for id_synthese in id_list ?
    POST parameters: Use a list of id_synthese (in POST parameters) to filter the v_synthese_for_export_view
    """
    filters = request.json if request.is_json else {}

    metadata_view = GenericTable(
        tableName="v_metadata_for_export",
        schemaName="gn_synthese",
        engine=DB.engine,
    )

    # Test de conformité de la vue v_metadata_for_export
    try:
        assert hasattr(metadata_view.tableDef.columns, "jdd_id")
    except AssertionError as e:
        return (
            {
                "msg": """
                        View v_metadata_for_export
                        must have a jdd_id column \n
                        trace: {}
                        """.format(
                    str(e)
                )
            },
            500,
        )

    q = select(distinct(VSyntheseForWebApp.id_dataset), metadata_view.tableDef)

    synthese_query_class = SyntheseQuery(
        VSyntheseForWebApp,
        q,
        filters,
    )
    synthese_query_class.add_join(
        metadata_view.tableDef,
        getattr(
            metadata_view.tableDef.columns,
            current_app.config["SYNTHESE"]["EXPORT_METADATA_ID_DATASET_COL"],
        ),
        VSyntheseForWebApp.id_dataset,
    )

    # Filter query with permissions (scope, sensitivity, ...)
    synthese_query_class.filter_query_all_filters(g.current_user, permissions)

    data = DB.session.execute(synthese_query_class.query)

    # Define the header of the csv file
    columns = [db_col.key for db_col in metadata_view.tableDef.columns]
    columns[columns.index("nombre_obs")] = "nombre_total_obs"

    # Retrieve the data to write in the csv file
    data = [metadata_view.as_dict(d) for d in data]
    for d in data:
        d["nombre_total_obs"] = d.pop("nombre_obs")

    return to_csv_resp(
        datetime.datetime.now().strftime("%Y_%m_%d_%Hh%Mm%S"),
        data=data,
        separator=";",
        columns=columns,
    )


@export_routes.route("/export_statuts", methods=["POST"])
@permissions_required("E", module_code="SYNTHESE")
def export_status(permissions):
    """Route to get all the protection status of a synthese search

    .. :quickref: Synthese;

    Get the CRUVED from 'R' action because we don't give observations X/Y but only statuts
    and to be consistent with the data displayed in the web interface.

    Parameters:
        - HTTP-GET: the same that the /synthese endpoint (all the filter in web app)
    """
    filters = request.json if request.is_json else {}

    # Initalize the select object
    query = select(
        distinct(VSyntheseForWebApp.cd_nom).label("cd_nom"),
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
    )
    # Initialize SyntheseQuery class
    synthese_query = SyntheseQuery(VSyntheseForWebApp, query, filters)

    # Filter query with permissions
    synthese_query.filter_query_all_filters(g.current_user, permissions)

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
    query = synthese_query.build_query()

    # Set enable status texts filter
    query = query.where(TaxrefBdcStatutText.enable == True)

    protection_status = []
    data = DB.session.execute(query)

    for d in data:
        d = d._mapping
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
