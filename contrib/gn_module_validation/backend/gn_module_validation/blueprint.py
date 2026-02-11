import logging

from flask import Blueprint, request, jsonify, g
from werkzeug.exceptions import BadRequest, Forbidden
import sqlalchemy as sa
from marshmallow import ValidationError

from pypnnomenclature.models import TNomenclatures, BibNomenclaturesTypes
from utils_flask_sqla_geo.utilsgeometry import rows_to_geojson

from geonature.utils.env import DB, db
from geonature.core.gn_synthese.models import Synthese
from geonature.core.gn_synthese.utils.query_select_sqla import SyntheseQuery
from geonature.core.gn_permissions.decorators import permissions_required
from geonature.core.gn_commons.schemas import TValidationSchema
from geonature.core.gn_commons.models.base import TValidations


from gn_module_validation.constant import *
from gn_module_validation.query_build import *
from gn_module_validation.notifications import *
from gn_module_validation.schema import *
import gn_module_validation.tasks  # Dont remove it !!!!!!!!


# Blueprint setupt
blueprint = Blueprint("validation", __name__)
log = logging.getLogger(__name__)


@blueprint.route("/observations", methods=["GET", "POST"])
@permissions_required("C", module_code="VALIDATION")
def get_observations_last_validations(permissions):
    """
    Returns observations with their last validations in GeoJSON format.

    This route allows retrieving filtered observations with their validation statuses
    as a GeoJSON FeatureCollection for map display.

    Parameters
    ----------
    permissions : object
        User permissions, injected by the decorator

    Query Parameters
    ----------------
    sort : str, optional
        Sort order: 'asc' (ascending) or 'desc' (descending), default 'desc'
    order_by : str, optional
        Field to sort by, default 'last_validation.validation_date'
    limit : int, optional
        Maximum number of results, default is the NB_MAX_OBS_MAP configuration value
    fields : str, optional
        Comma-separated list of additional fields
    score : int, optional
        Filter on profile score
    valid_distribution : bool, optional
        Filter on distribution validity
    valid_altitude : bool, optional
        Filter on altitude validity
    valid_phenology : bool, optional
        Filter on phenology validity
    no_auto : bool, optional
        If True, excludes automatic validations
    modif_since_validation : bool, optional
        If True, filters observations modified since their last validation

    Returns
    -------
    Response
        JSON response containing a GeoJSON FeatureCollection with:
        - type: "FeatureCollection"
        - features: List of observations with their geometries and properties

    Examples
    --------
    GET /validation/observations?sort=desc&limit=100
    POST /validation/observations
    Body: {"valid_distribution": true, "no_auto": true}
    """
    params = request.get_json() if request.is_json else {}
    params.update(request.args)

    limit = params.pop("limit", blueprint.config["NB_MAX_OBS_MAP"])

    # Build query
    selectable = build_synthese_query(params, permissions, limit)
    print(selectable.compile(compile_kwargs={"literal_binds": True}))

    return jsonify(
        rows_to_geojson(
            db.session.execute(selectable).all(),
            geom_field="the_geom_4326",
            nest_properties=True,
        )
    )


@blueprint.route("/", methods=["GET", "POST"])
@permissions_required("C", module_code="VALIDATION")
def get_validations(permissions):
    """
    Returns a paginated list of validations.

    This route allows retrieving the history of manual validations
    with pagination, sorting, and the possibility of JSON or GeoJSON export.

    Parameters
    ----------
    permissions : object
        User permissions, injected by the decorator

    Query Parameters
    ----------------
    page : int, required
        Page number to retrieve (starts at 1)
    per_page : int, required
        Number of items per page
    sort : str, optional
        Sort order: 'asc' or 'desc', default 'desc'
    order_by : str, optional
        Field to sort by, default 'validation_date'
    format : str, optional
        Output format: 'json' (default) or 'geojson'
    fields : str, optional
        Additional fields separated by commas: 'observation', 'user_info'

    Returns
    -------
    Response
        JSON response containing:
        - items: List of validations (format depends on 'format' parameter)
        - total: Total number of validations matching the filters
        - per_page: Number of items per page (echo of the parameter)
        - page: Current page number (echo of the parameter)

    Raises
    ------
    BadRequest
        If 'page' or 'per_page' are missing, null, or negative

    Notes
    -----
    - Only manual validations (validation_auto=False) are returned
    - Only observations from validatable datasets are included
    - The 'geojson' format automatically adds observation fields
    - The method accepts parameters in GET or POST

    Examples
    --------
    GET /validation/?page=1&per_page=20&fields=user_info
    POST /validation/
    Body: {"page": 1, "per_page": 50, "format": "geojson"}
    """
    params = request.get_json() if request.is_json else {}
    params.update(request.args)

    # Validate pagination
    page = int(params.get("page", 0))
    per_page = int(params.get("per_page", 0))

    if page <= 0 or per_page <= 0:
        raise BadRequest("Pagination required: 'page' and 'per_page' must be positive integers")

    # Build query
    query = build_validations_query(params)

    # Apply filters
    selectable = SyntheseQuery(Synthese, query, params)
    filtered_query = selectable.filter_query_all_filters(g.current_user, permissions)

    # Apply sorting
    params["order_by"] = params.get("order_by", "validation_date")
    filtered_query = apply_sorting(filtered_query, params)

    # Apply pagination
    offset = (page - 1) * per_page
    paginated_query = filtered_query.limit(per_page).offset(offset)

    # Get total count
    count = db.session.scalar(filtered_query.with_only_columns([sa.func.count()]).order_by(None))

    # Format output
    format_type = params.get("format", "json")
    if format_type == "geojson":
        data = rows_to_geojson(db.session.execute(paginated_query).all(), "the_geom_4326")
    else:
        data = ValidationRouteSchema(many=True).dump(db.session.execute(paginated_query).all())

    return jsonify(
        {
            "items": data,
            "total": count,
            "per_page": per_page,
            "page": page,
        }
    )


@blueprint.route("/statusNames", methods=["GET"])
@permissions_required("C", module_code="VALIDATION")
def get_status_names(permissions):
    """
    Returns the list of available validation statuses.

    Parameters
    ----------
    permissions : object
        User permissions, injected by the decorator

    Returns
    -------
    Response
        JSON list of active validation status nomenclatures, each containing:
        - id_nomenclature: Nomenclature identifier
        - mnemonique: Mnemonic code
        - cd_nomenclature: Nomenclature code
        - definition_default: Default definition of the status

    Notes
    -----
    Only active nomenclatures of type 'STATUT_VALID' are returned,
    sorted by nomenclature code.

    Examples
    --------
    GET /validation/statusNames
    Response: [
        {
            "id_nomenclature": 1,
            "mnemonique": "Pending",
            "cd_nomenclature": "0",
            "definition_default": "Pending validation"
        },
        ...
    ]
    """
    nomenclatures = (
        sa.select(TNomenclatures)
        .join(BibNomenclaturesTypes)
        .where(BibNomenclaturesTypes.mnemonique == "STATUT_VALID")
        .where(TNomenclatures.active == True)
        .order_by(TNomenclatures.cd_nomenclature)
    )

    return jsonify(
        [
            nomenc.as_dict(
                fields=["id_nomenclature", "mnemonique", "cd_nomenclature", "definition_default"]
            )
            for nomenc in db.session.scalars(nomenclatures).all()
        ]
    )


@blueprint.route("/<id_synthese>", methods=["POST"])
@permissions_required("C", module_code="VALIDATION")
def post_status(permissions, id_synthese):
    """
    Creates a validation status for one or more observations.

    This route allows manually validating observations by assigning them
    a validation status and a comment. Observations are identified by their
    synthese identifiers.

    Parameters
    ----------
    permissions : object
        User permissions, injected by the decorator
    id_synthese : str
        Synthese identifier(s), comma-separated for group validation

    Request Body
    ------------
    statut : int, required
        Nomenclature identifier of the validation status
    comment : str, required
        Validation comment

    Returns
    -------
    Response
        JSON representation of the applied validation status containing:
        - id_nomenclature: Nomenclature identifier
        - mnemonique: Status mnemonic code
        - cd_nomenclature: Nomenclature code
        - label_default: Default label

    Raises
    ------
    BadRequest
        If the 'statut' or 'comment' field is missing
    Forbidden
        If the user does not have permissions on an observation
    NotFound
        If a synthese identifier or the status does not exist

    Notes
    -----
    - Each created validation is marked as manual (validation_auto=False)
    - A notification is sent to the observation's recorder
    - Changes are committed after processing all observations

    Examples
    --------
    POST /validation/123
    Body: {
        "statut": 2,
        "comment": "Observation validated after verification"
    }

    POST /validation/123,456,789
    Body: {
        "statut": 3,
        "comment": "Invalid data"
    }
    """
    data = request.get_json()

    # Validate input
    if not data.get("statut"):
        raise BadRequest("No validation status selected")
    if "comment" not in data:
        raise BadRequest("Missing 'comment' field")

    id_validation_status = data["statut"]
    validation_comment = data["comment"]

    # Get validation status
    validation_status = db.get_or_404(TNomenclatures, id_validation_status)

    # Process each synthese ID
    id_list = [id.strip() for id in id_synthese.split(",")]

    for synthese_id in id_list:
        create_validation(
            synthese_id=int(synthese_id),
            id_validation_status=id_validation_status,
            validation_comment=validation_comment,
            permissions=permissions,
            validation_status=validation_status,
        )

    return jsonify(validation_status.as_dict())


def create_validation(
    synthese_id: int,
    id_validation_status: int,
    validation_comment: str,
    permissions,
    validation_status,
):
    """
    Creates a validation entry for a synthese record.

    This function creates a new manual validation for an observation,
    checks permissions, and sends a notification to the recorder.

    Parameters
    ----------
    synthese_id : int
        Identifier of the record in the synthese table
    id_validation_status : int
        Nomenclature identifier of the validation status
    validation_comment : str
        Comment associated with the validation
    permissions : object
        User permissions for access verification
    validation_status : TNomenclatures
        Nomenclature object of the validation status

    Raises
    ------
    NotFound
        If the observation does not exist
    Forbidden
        If the user does not have the necessary permissions
    BadRequest
        If the validation data is invalid

    Notes
    -----
    - The validation is always marked as manual (validation_auto=False)
    - The validator is the current user (g.current_user)
    - A notification is sent only if id_digitiser is defined
    - Changes are added to the session but not committed
    """
    # Get synthese record
    synthese = db.get_or_404(Synthese, synthese_id)

    # Check permissions
    if not synthese.has_instance_permission(permissions):
        raise Forbidden

    # Create validation data
    validation_data = {
        "uuid_attached_row": synthese.unique_id_sinp,
        "id_nomenclature_valid_status": id_validation_status,
        "id_validator": g.current_user.id_role,
        "validation_comment": validation_comment,
        "validation_auto": False,
    }

    # Insert validation
    try:
        validation_schema = TValidationSchema()
        validation = validation_schema.load(
            validation_data, instance=TValidations(), session=DB.session
        )
    except ValidationError as error:
        raise BadRequest(error.messages)

    DB.session.add(validation)

    # Send notification
    notify_validation_state_change(synthese, validation, validation_status)

    DB.session.commit()


@blueprint.route("/date/<uuid:uuid>", methods=["GET"])
@permissions_required("C", module_code="VALIDATION")
def get_validation_date(permissions, uuid):
    """
    Returns the date of the last validation for an observation.

    Parameters
    ----------
    permissions : object
        User permissions, injected by the decorator
    uuid : UUID
        Unique SINP identifier of the observation

    Returns
    -------
    Response
        - If validated: JSON containing the validation date (string)
        - If not validated: Empty response with code 204 (No Content)

    Raises
    ------
    NotFound
        If the observation does not exist
    Forbidden
        If the user does not have the necessary permissions

    Notes
    -----
    Only the last validation is returned, whether manual or automatic.

    Examples
    --------
    GET /validation/date/550e8400-e29b-41d4-a716-446655440000
    Response: "2024-12-15T10:30:00"

    GET /validation/date/550e8400-e29b-41d4-a716-446655440001
    Response: 204 No Content
    """
    synthese = db.first_or_404(
        Synthese.lateraljoin_last_validation(
            query=sa.select(Synthese).filter_by(unique_id_sinp=uuid)
        )
    )

    if not synthese.has_instance_permission(permissions):
        raise Forbidden

    if synthese.last_validation:
        return jsonify(str(synthese.last_validation.validation_date))

    return "", 204
