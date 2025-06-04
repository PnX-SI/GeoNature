from flask import (
    Blueprint,
    g,
    request,
)

from geonature.core.gn_permissions.decorators import permissions_required

from geonature.core.gn_synthese.tasks.exports import (
    export_synthese_task,
)

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

    uuid_task = export_synthese_task.delay(
        export_type="taxons",
        id_permissions=[p.id_permission for p in permissions],
        params={"id_list": id_list},
        id_role=g.current_user.id_role,
    )

    return {"msg": "task en cours", "uuid_task": str(uuid_task)}


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
    all_params = {**params, **{"id_list": id_list}}

    uuid_task = export_synthese_task.delay(
        export_type="observations",
        id_permissions=[p.id_permission for p in permissions],
        params=all_params,
        id_role=g.current_user.id_role,
    )

    return {"msg": "task en cours", "uuid_task": str(uuid_task)}


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

    uuid_task = export_synthese_task.delay(
        export_type="metadata",
        id_permissions=[p.id_permission for p in permissions],
        params=filters,
        id_role=g.current_user.id_role,
    )

    return {"msg": "task en cours", "uuid_task": str(uuid_task)}


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
    uuid_task = export_synthese_task.delay(
        export_type="status",
        id_permissions=[p.id_permission for p in permissions],
        params=filters,
        id_role=g.current_user.id_role,
    )

    return {"msg": "task en cours", "uuid_task": str(uuid_task)}
