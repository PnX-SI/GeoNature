import os
from pathlib import Path
from celery.schedules import crontab
from celery.utils.log import get_task_logger
import datetime
import json
import re
from collections import OrderedDict
from pathlib import Path
from flask import (
    Blueprint,
    current_app,
    g,
    render_template,
    request,
    send_from_directory,
)

from marshmallow import fields
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
from utils_flask_sqla_geo.generic import GenericTableGeo, GenericQueryGeo
from werkzeug.exceptions import BadRequest, Forbidden

from typing import List, Optional


from app.models import TRoles
from geonature.utils.env import db
from geonature.core.gn_commons.repositories import TMediumRepository
from geonature.utils.celery import celery_app
from geonature.utils.config import config

from utils_flask_sqla_geo.export import (
    export_csv,
    export_geojson,
    export_geopackage,
    export_json,
)
from geonature.core.gn_permissions.models import Permission
from ref_geo.utils import get_local_srid


from flask_sqlalchemy.query import Query

from marshmallow import Schema

logger = get_task_logger(__name__)


@celery_app.task(bind=True)
def export_taxons(self, id_permissions, id_list, id_role):

    print("export_taxons")
    current_user = db.session.scalar(select(TRoles).where(TRoles.id_role == id_role))
    permissions = db.session.scalars(
        select(Permission).where(Permission.id_permission.in_(id_permissions))
    )
    taxon_view = GenericQueryGeo(
        DB=DB, tableName="v_synthese_taxon_for_export_view", schemaName="gn_synthese"
    )
    columns = taxon_view.view.tableDef.columns

    # Test de conformité de la vue v_synthese_for_export_view
    try:
        assert hasattr(columns, "cd_ref")
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
    export_dir = Path(current_app.config["MEDIA_FOLDER"]) / "exports/synthese"
    current_timestamp = datetime.datetime.now().strftime("%Y_%m_%d_%Hh%Mm%S")
    export_file_name = f"export_taxons_{current_timestamp}"
    print(export_dir, export_file_name)

    export_data_file(
        file_name=f"{export_dir}/{export_file_name}",
        export_url="",
        format="csv",
        query=query,
        schema_class=ExportTaxonViewSchema,
        pk_name=None,
        srid=None,
        columns=[],
    )


def export_data_file(
    file_name: str,
    export_url: str,
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
    print(file_name)
    logger.info(f"Generate export {file_name}...")
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
            geometry_field_name=geometry_field,
            columns=columns,
        )
