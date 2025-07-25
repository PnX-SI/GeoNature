import logging
import datetime
import json

from flask import Blueprint, request, jsonify, current_app, g
from flask.json import jsonify
from werkzeug.exceptions import Forbidden
import sqlalchemy as sa
from sqlalchemy.orm import aliased, contains_eager, selectinload
from marshmallow import ValidationError

from pypnnomenclature.models import TNomenclatures, BibNomenclaturesTypes

from geonature.utils.env import DB, db
from geonature.core.gn_synthese.models import Synthese, TReport
from geonature.core.gn_profiles.models import VConsistancyData
from geonature.core.gn_synthese.utils.query_select_sqla import SyntheseQuery
from geonature.core.gn_permissions.decorators import permissions_required
from geonature.core.gn_commons.schemas import TValidationSchema
from geonature.core.gn_commons.models.base import TValidations

from werkzeug.exceptions import BadRequest
from geonature.core.gn_commons.models import TValidations
from geonature.core.notifications.utils import dispatch_notifications
import gn_module_validation.tasks

blueprint = Blueprint("validation", __name__)
log = logging.getLogger()

DEFAULT_FIELDS = {
    "id_synthese",
    "unique_id_sinp",
    "entity_source_pk_value",
    "meta_update_date",
    "id_nomenclature_valid_status",
    "nomenclature_valid_status.cd_nomenclature",
    "nomenclature_valid_status.mnemonique",
    "nomenclature_valid_status.label_default",
    "last_validation.validation_date",
    "last_validation.validation_auto",
    "taxref.cd_nom",
    "taxref.nom_vern",
    "taxref.lb_nom",
    "taxref.nom_vern_or_lb_nom",
    "dataset.validable",
}

DEFAULT_PROFILE_FIELDS = {
    "profile.score",
    "profile.valid_phenology",
    "profile.valid_altitude",
    "profile.valid_distribution",
}


@blueprint.route("", methods=["GET", "POST"])
@permissions_required("C", module_code="VALIDATION")
def get_synthese_data(permissions):
    """
    Return synthese and t_validations data filtered by form params
    Params must have same synthese fields names

    .. :quickref: Validation;

    Parameters:
    ------------
    :query str sort: str<'asc', 'desc'> trier dans l'ordre ascendant ou descendant (optionnel, 'order')
    :query str order_by: champs sur lequel appliquer le tri de données (optionnel. lié à 'sort')
    :query int page: numéro de page (optionnel, lié à 'per_page')
    :query int per_page: nombre d'élément par page (optionnel, lié à 'page')
    :query str format: str<'json', 'geojson'> format de la sortie
    Returns
    -------
    FeatureCollection | json
    """
    enable_profile = current_app.config["FRONTEND"]["ENABLE_PROFILES"]

    params = (request.json if request.is_json else None) or {}
    params.update(request.args)

    # Sorting parameter
    sort = params.get("sort", "desc")
    order_by = sa.text(request.args.get("order_by", "last_validation.validation_date", str))
    sorting_active = sort != "" and order_by != ""
    # Pagination parameter
    page = int(params.get("page", 0))
    per_page = int(params.get("per_page", 0))
    pagination_active = page > 0 and per_page > 0
    limit = params.pop("limit", blueprint.config["NB_MAX_OBS_MAP"])

    # Profile parameters
    score = params.pop("score", None)
    valid_distribution = params.pop("valid_distribution", None)
    valid_altitude = params.pop("valid_altitude", None)
    valid_phenology = params.pop("valid_phenology", None)
    use_profile_filter = valid_altitude or valid_distribution or valid_phenology

    # Format: output format
    format = params.pop("format", "geojson")

    no_auto = params.pop("no_auto", False)
    fields_as_str = params.pop("fields", None)

    if format not in ["json", "geojson"]:
        raise BadRequest("Invalid format parameter")

    # Check pagination is active for json
    if format == "json" and not pagination_active:
        raise BadRequest("Pagination must be active when requesting json object")

    if format == "geojson" and pagination_active:
        raise BadRequest("Pagination can't be active when requesting geojson object")

    # Fields: Setup fields as route parameters with default behavior

    fields = set()
    if fields_as_str:
        fields.update({field for field in fields_as_str.split(",")})
    else:
        fields.update(DEFAULT_FIELDS)
        if enable_profile:
            fields.update(DEFAULT_PROFILE_FIELDS)

    # Fields: add config parameters
    fields.update({col["column_name"] for col in blueprint.config["COLUMN_LIST"]})

    lateral_join = {}
    """
    1) We start creating the query with SQLAlchemy ORM.
    2) We convert this query to SQLAlchemy Core in order to use
       SyntheseQuery utility class to apply user filters.
    3) We get back the results in the ORM through from_statement.
       We populate relationships with contains_eager.

    We create a lot of aliases, that are selected at step 1,
    and given to contains_eager at step 3 to correctly identify columns
    to use to populate relationships models.
    """
    last_validation_subquery = (
        sa.select(TValidations)
        .where(TValidations.uuid_attached_row == Synthese.unique_id_sinp)
        .order_by(TValidations.validation_date.desc())
        .limit(1)
        .subquery()
        .lateral("last_validation")
    )
    last_validation = aliased(TValidations, last_validation_subquery)
    lateral_join = {last_validation: Synthese.last_validation}

    if enable_profile and use_profile_filter:
        profile_subquery = (
            sa.select(VConsistancyData)
            .where(VConsistancyData.id_synthese == Synthese.id_synthese)
            .limit(1)
            .subquery()
            .lateral("profile")
        )

        profile = aliased(VConsistancyData, profile_subquery)
        lateral_join[profile] = Synthese.profile

    relationships = list(
        {
            field.split(".", 1)[0]
            for field in fields
            if "." in field
            and not (field.startswith("last_validation.") or field.startswith("profile."))
        }
    )

    # Get dataset relationship : filter only validable dataset
    dataset_index = relationships.index("dataset")
    relationships = [getattr(Synthese, rel) for rel in relationships]
    aliases = [aliased(rel.property.mapper.class_) for rel in relationships]
    dataset_alias = aliases[dataset_index]

    query = db.session.query(Synthese, *aliases, *lateral_join.keys())

    for rel, alias in zip(relationships, aliases):
        query = query.outerjoin(rel.of_type(alias))

    for alias in lateral_join.keys():
        query = query.outerjoin(alias, sa.true())

    if format == "geojson":
        query = query.where(Synthese.the_geom_4326.isnot(None)).order_by(Synthese.date_min.desc())

    # filter with profile
    if enable_profile and use_profile_filter:
        if score is not None:
            query = query.where(profile.score == score)
        if valid_distribution is not None:
            query = query.where(profile.valid_distribution == bool(valid_distribution))
        if valid_altitude is not None:
            query = query.where(profile.valid_altitude == bool(valid_altitude))
        if valid_phenology is not None:
            query = query.where(profile.valid_phenology == bool(valid_phenology))

    if params.pop("modif_since_validation", None):
        query = query.where(Synthese.meta_update_date > last_validation.validation_date)

    if no_auto:
        query = query.where(last_validation.validation_auto == False)

    # Filter only validable dataset

    query = query.where(dataset_alias.validable == True)

    # Step 2: give SyntheseQuery the Core selectable from ORM query
    assert len(query.selectable.get_final_froms()) <= 2

    selectable = SyntheseQuery(
        Synthese,
        query.selectable,
        params,  # , query_joins=query.selectable.get_final_froms()[0] # DUPLICATION of OUTER JOIN
    ).filter_query_all_filters(g.current_user, permissions)

    # Step 3: Construct Synthese model from query result
    syntheseQueryStatement = Synthese.query.options(
        *[contains_eager(rel, alias=alias) for rel, alias in zip(relationships, aliases)]
    ).options(*[contains_eager(rel, alias=alias) for alias, rel in lateral_join.items()])

    # to pass alert reports infos with synthese to validation list
    # only if tools are activate for validation
    alertActivate = (
        len(current_app.config["SYNTHESE"]["ALERT_MODULES"])
        and "VALIDATION" in current_app.config["SYNTHESE"]["ALERT_MODULES"]
    )
    pinActivate = (
        len(current_app.config["SYNTHESE"]["PIN_MODULES"])
        and "VALIDATION" in current_app.config["SYNTHESE"]["PIN_MODULES"]
    )
    if alertActivate or pinActivate:
        fields |= {"reports.report_type.type"}
        syntheseQueryStatement = syntheseQueryStatement.options(
            selectinload(Synthese.reports).joinedload(TReport.report_type)
        )
    query = selectable

    # Sort
    if sorting_active:
        if sort == "asc":
            query = query.order_by(sa.asc(order_by))
        else:
            query = query.order_by(sa.desc(order_by))

    if pagination_active:
        offset = (page - 1) * per_page
        query = syntheseQueryStatement.from_statement(query.limit(per_page).offset(offset))
    else:
        query = syntheseQueryStatement.from_statement(query.limit(limit))

    # The raise option ensure that we have correctly retrived relationships data at step 3
    if format == "geojson":
        return jsonify(query.as_geofeaturecollection(fields=fields))
    elif format == "json":
        count = db.session.scalar(selectable.with_only_columns([sa.func.count()]).order_by(None))
        return jsonify(
            {
                "items": [item.as_dict(fields=fields) for item in query.all()],
                "total": count,
                "per_page": per_page,
                "page": page,
            }
        )


@blueprint.route("/statusNames", methods=["GET"])
@permissions_required("C", module_code="VALIDATION")
def get_statusNames(permissions):
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
    data = dict(request.get_json())
    try:
        id_validation_status = data["statut"]
    except KeyError:
        raise BadRequest("Aucun statut de validation n'est sélectionné")
    validation_status = db.get_or_404(TNomenclatures, id_validation_status)
    try:
        validation_comment = data["comment"]
    except KeyError:
        raise BadRequest("Missing 'comment'")

    id_synthese = id_synthese.split(",")

    for id in id_synthese:
        # t_validations.id_validation:

        # t_validations.uuid_attached_row:
        synthese = db.get_or_404(Synthese, int(id))

        if not synthese.has_instance_permission(permissions):
            raise Forbidden

        uuid = synthese.unique_id_sinp

        # t_validations.id_validator:
        id_validator = g.current_user.id_role

        # t_validations.validation_auto
        val_auto = False
        val_dict = {
            "uuid_attached_row": uuid,
            "id_nomenclature_valid_status": id_validation_status,
            "id_validator": id_validator,
            "validation_comment": validation_comment,
            "validation_auto": val_auto,
        }
        # insert values in t_validations
        validationSchema = TValidationSchema()
        try:
            validation = validationSchema.load(
                val_dict, instance=TValidations(), session=DB.session
            )
        except ValidationError as error:
            raise BadRequest(error.messages)
        DB.session.add(validation)

        # Send element to notification system
        notify_validation_state_change(synthese, validation, validation_status)

        DB.session.commit()

    return jsonify(validation_status.as_dict())


@blueprint.route("/date/<uuid:uuid>", methods=["GET"])
@permissions_required("C", module_code="VALIDATION")
def get_validation_date(permissions, uuid):
    """
    Retourne la date de validation
    pour l'observation uuid
    """
    s = db.first_or_404(
        Synthese.lateraljoin_last_validation(
            query=sa.select(Synthese).filter_by(unique_id_sinp=uuid)
        )
    )
    if not s.has_instance_permission(permissions):
        raise Forbidden
    if s.last_validation:
        return jsonify(str(s.last_validation.validation_date))
    else:
        return "", 204


# Send notification
def notify_validation_state_change(synthese, validation, status):
    if not synthese.id_digitiser:
        return
    dispatch_notifications(
        code_categories=["VALIDATION-STATUS-CHANGED%"],
        id_roles=[synthese.id_digitiser],
        title="Changement de statut de validation",
        url=current_app.config["URL_APPLICATION"]
        + "/#/synthese/occurrence/"
        + str(synthese.id_synthese),
        context={
            "synthese": synthese,
            "validation": validation,
            "status": status,
        },
    )
