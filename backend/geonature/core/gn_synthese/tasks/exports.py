import os
from pathlib import Path
from datetime import datetime
from typing import List, Optional
from celery.utils.log import get_task_logger

from flask import current_app
from geoalchemy2 import Geometry
from sqlalchemy import distinct, func, select
from flask_sqlalchemy.query import Query
from marshmallow import fields, Schema
from werkzeug.exceptions import BadRequest, Forbidden

from utils_flask_sqla_geo.generic import GenericQueryGeo
from utils_flask_sqla_geo.export import (
    export_csv,
    export_geojson,
    export_geopackage,
    export_json,
)

from ref_geo.utils import get_local_srid

from apptax.taxonomie.models import VBdcStatus

from pypnusershub.db.models import User

from geonature.utils.env import DB, db
from geonature.utils.celery import celery_app

from geonature.core.gn_permissions.models import Permission
from geonature.core.gn_commons.models import Task, TModules

from geonature.core.gn_synthese.models import (
    Synthese,
    VSyntheseForWebApp,
)
from geonature.core.gn_synthese.schemas import ExportStatusSchema
from geonature.core.gn_synthese.synthese_config import MANDATORY_COLUMNS
from geonature.core.gn_synthese.utils.blurring import (
    build_allowed_geom_cte,
    build_blurred_precise_geom_queries,
    split_blurring_precise_permissions,
)
from geonature.core.gn_synthese.utils.query_select_sqla import SyntheseQuery


logger = get_task_logger(__name__)


@celery_app.task(bind=True)
def export_synthese_task(self, export_type, id_permissions, params, id_role):
    db_task = Task.create_pending_task(id_role, self.request.id, "SYNTHESE")
    try:
        current_user = db.session.scalar(select(User).where(User.id_role == id_role))
        permissions = db.session.scalars(
            select(Permission).where(Permission.id_permission.in_(id_permissions))
        ).all()
        geometry_field_name = None
        local_srid = None

        export_format = params.get("export_format", "csv")
        if export_type == "taxons":
            ExportSchema, query, columns = export_taxons(permissions, current_user, params)
        elif export_type == "observations":
            ExportSchema, query, columns, geometry_field_name, local_srid = export_observations(
                permissions, current_user, params
            )
        elif export_type == "status":
            ExportSchema, query, columns = export_status(permissions, current_user, params)
        elif export_type == "metadata":
            ExportSchema, query, columns = export_metadata(permissions, current_user, params)
        else:
            # TODO raise
            return

        export_dir = Path(current_app.config["MEDIA_FOLDER"]) / "exports/usr_generated"
        current_timestamp = datetime.now().strftime("%Y_%m_%d_%Hh%Mm%S")
        export_file_name = f"export_{export_type}_{current_timestamp}.{export_format}"

        full_file_path = f"{export_dir}/{export_file_name}"
        export_data_file(
            file_name=full_file_path,
            format="csv",
            query=query,
            schema_class=ExportSchema,
            pk_name=None,
            geometry_field=geometry_field_name,
            srid=local_srid,
            columns=columns,
        )
        db_task.set_succesfull(export_file_name)
        return db_task
    except Exception as e:
        db_task.status = "error"
        db.session.commit()
        raise e


def export_taxons(permissions, current_user, params):

    taxon_view = GenericQueryGeo(
        DB=DB, tableName="v_synthese_taxon_for_export_view", schemaName="gn_synthese"
    )
    columns = taxon_view.view.tableDef.columns
    id_list = params.get("id_list")

    # Test de conformité de la vue v_synthese_for_export_view
    try:
        assert hasattr(columns, "cd_ref")
    except AssertionError as e:
        raise Exception("View v_synthese_taxon_for_export_view must have a cd_ref column \n")

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

    synthese_query_class.filter_query_all_filters(current_user, permissions)

    subq = synthese_query_class.query.alias("subq")

    query = select(*columns, subq.c.nb_obs, subq.c.date_min, subq.c.date_max).join(
        subq, subq.c.cd_ref == columns.cd_ref
    )

    # Créate schema
    extra_fields = {}
    extra_fields["nb_obs"] = fields.Integer(dump_only=True)
    extra_fields["date_min"] = fields.Date(dump_only=True)
    extra_fields["date_max"] = fields.Date(dump_only=True)
    ExportTaxonViewSchema = type(
        "ExportTaxonViewSchema", (taxon_view.get_marshmallow_schema(),), extra_fields
    )
    return ExportTaxonViewSchema, query, []


def export_observations(permissions, current_user, params):
    export_format = params.get("export_format", "csv")
    view_name_param = params.get("view_name", "gn_synthese.v_synthese_for_export")
    id_list = params.get("id_list")
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

    # Get the SRID for the export
    local_srid = DB.session.execute(
        func.Find_SRID("gn_synthese", "synthese", "the_geom_local")
    ).scalar()

    blurring_permissions, precise_permissions = split_blurring_precise_permissions(permissions)

    # Get the view for export
    # Useful to have geom column so that they can be replaced by blurred geoms
    # (only if the user has sensitive permissions)
    export_view = GenericQueryGeo(DB=DB, tableName=view_name, schemaName=schema_name)

    mandatory_columns = {"id_synthese", geojson_4326_field, geojson_local_field}
    if not mandatory_columns.issubset(set(map(lambda col: col.name, export_view.view.db_cols))):
        print(set(map(lambda col: col.name, export_view.view.db_cols)))
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
        synthese_query_class.filter_query_all_filters(current_user, permissions)
        cte_synthese_filtered = synthese_query_class.build_query().cte("cte_synthese_filtered")
        selectable_columns = [export_view.view.tableDef]
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
            for col in export_view.view.tableDef.columns
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
            export_view.view.tableDef.join(
                cte_synthese_filtered,
                cte_synthese_filtered.c.id_synthese
                == export_view.view.tableDef.columns["id_synthese"],
            )
        )
        .where(export_view.view.tableDef.columns["id_synthese"].in_(id_list))
        .distinct(export_view.view.tableDef.columns["id_synthese"])
    )

    # Créate schema
    ExportObservationViewSchema = export_view.get_marshmallow_schema()

    columns_to_serialize = []

    # loop over synthese config to exclude columns if its default export
    for db_col in export_view.view.db_cols:
        if view_name_param == "gn_synthese.v_synthese_for_export":
            if db_col.key in current_app.config["SYNTHESE"]["EXPORT_COLUMNS"]:
                columns_to_serialize.append(db_col.key)
        else:
            # remove geojson and geometry fields of serialization
            if (
                db_col.key not in [geojson_4326_field, geojson_local_field, "geometry"]
                and not type(db_col.type) is Geometry
            ):
                columns_to_serialize.append(db_col.key)

    return (
        ExportObservationViewSchema,
        export_query,
        columns_to_serialize,
        geojson_local_field,
        local_srid,
    )


def export_metadata(permissions, current_user, params):

    metadata_view = GenericQueryGeo(
        DB=DB, tableName="v_metadata_for_export", schemaName="gn_synthese"
    )
    columns = metadata_view.view.tableDef.columns
    id_dataset_col = current_app.config["SYNTHESE"]["EXPORT_METADATA_ID_DATASET_COL"]
    try:
        assert hasattr(metadata_view.view.tableDef.columns, id_dataset_col)
    except AssertionError as e:
        raise Exception("View v_metadata_for_export must have a jdd_id column")

    q = select(distinct(VSyntheseForWebApp.id_dataset), metadata_view.view.tableDef)

    synthese_query_class = SyntheseQuery(
        VSyntheseForWebApp,
        q,
        params,
    )
    synthese_query_class.add_join(
        metadata_view.view.tableDef,
        getattr(
            metadata_view.view.tableDef.columns,
            id_dataset_col,
        ),
        VSyntheseForWebApp.id_dataset,
    )

    synthese_query_class.filter_query_all_filters(current_user, permissions)

    query = synthese_query_class.build_query()
    return metadata_view.get_marshmallow_schema(), query, []


def export_status(permissions, current_user, params):
    filters = params
    query = select(
        VSyntheseForWebApp.cd_ref,
        VSyntheseForWebApp.nom_valide,
        VSyntheseForWebApp.nom_vern,
        VBdcStatus.rq_statut,
        VBdcStatus.regroupement_type,
        VBdcStatus.lb_type_statut,
        VBdcStatus.cd_sig,
        VBdcStatus.full_citation,
        VBdcStatus.doc_url,
        VBdcStatus.code_statut,
        VBdcStatus.label_statut,
    ).distinct()

    synthese_query_class = SyntheseQuery(
        VSyntheseForWebApp,
        query,
        filters,
    )
    synthese_query_class.add_join(
        VBdcStatus,
        VBdcStatus.cd_ref,
        VSyntheseForWebApp.cd_ref,
    )

    synthese_query_class.filter_query_all_filters(current_user, permissions)
    query = synthese_query_class.build_query()

    return ExportStatusSchema, query, []


def export_data_file(
    file_name: str,
    format: str,
    query: Query,
    schema_class: Schema,
    pk_name: Optional[str] = None,
    geometry_field: Optional[str] = None,
    srid: Optional[int] = None,
    columns: Optional[List[str]] = [],
):
    """
    Fonction qui permet de générer un export fichier

    .. :quickref:  Fonction qui permet de générer un export fichier

    :query int id_export: Identifiant de l'export
    :query str export_format: Format de l'export (csv, json, gpkg)
    :query {} filters: Filtre à appliquer sur l'export
    :query

    **Returns:**
    .. str : nom du fichier
    """
    logger.info(f"Generate export {geometry_field} {file_name}...")
    try:
        export_as_file(
            file_format=format,
            filename=file_name,
            query=query,
            schema_class=schema_class,
            pk_name=pk_name,
            geometry_field=geometry_field,
            srid=srid,
            columns=columns,
        )
    except Exception as exp:
        notify_export_file_generated()
        raise exp
    notify_export_file_generated()


def notify_export_file_generated():
    pass


def export_as_file(
    file_format: str,
    filename: str,
    query,
    schema_class,
    pk_name: Optional[str] = None,
    geometry_field: Optional[str] = None,
    srid: Optional[int] = None,
    columns: Optional[List[str]] = [],
):
    # format_list = [k for k in current_app.config["EXPORTS"]["export_format_map"].keys()]

    # if file_format not in format_list:
    #     raise GeoNatureError("Unsupported format")

    if file_format == "gpkg" and srid is None:
        srid = get_local_srid(db.session)

    # Generate directory
    os.makedirs(Path(filename).parent, exist_ok=True)
    if file_format == "gpkg":
        export_geopackage(
            query=query,
            schema_class=schema_class,
            filename=filename,
            geometry_field_name=geometry_field,
            columns=columns,
            srid=srid,
        )
        return

    func_dict = {
        "geojson": export_geojson,
        "json": export_json,
        "csv": export_csv,
    }

    with open(filename, "w") as f:
        func_dict[file_format](
            query=query,
            schema_class=schema_class,
            fp=f,
            columns=columns,
            geometry_field_name=geometry_field,
        )
