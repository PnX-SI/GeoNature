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
from utils_flask_sqla_geo.generic import GenericTableGeo, GenericQueryGeo
from werkzeug.exceptions import BadRequest, Forbidden

from geonature.core.gn_synthese.tasks.exports import export_taxons, export_observations

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

    id_list = request.get_json()

    export_taxons.delay(
        id_permissions=[p.id_permission for p in permissions],
        id_list=id_list,
        id_role=g.current_user.id_role,
    )

    return (
        {"msg": "task en cours"},
        200,
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
    # get list of id synthese from POST
    id_list = request.get_json()

    export_observations.delay(
        id_permissions=[p.id_permission for p in permissions],
        id_list=id_list,
        params=params,
        id_role=g.current_user.id_role,
    )

    return (
        {"msg": "task en cours"},
        200,
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
