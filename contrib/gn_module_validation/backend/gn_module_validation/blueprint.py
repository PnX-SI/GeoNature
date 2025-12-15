import logging

from flask import Blueprint, request, jsonify, current_app, g
from flask.json import jsonify
from geonature.core.gn_meta.models.datasets import TDatasets
from pypnusershub.db.models import User
from utils_flask_sqla_geo.utils import rows_to_geojson
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
import gn_module_validation.tasks  # Dont remove it !!!!!!!!

from marshmallow import Schema, fields


class ValidationSchema(Schema):
    id_synthese = fields.Int()
    nom_cite = fields.Str(allow_none=True)
    observers = fields.Str(allow_none=True)
    date_min = fields.DateTime(allow_none=True)
    date_max = fields.DateTime(allow_none=True)

    id_validation = fields.Int()
    validation_date = fields.DateTime()
    validation_auto = fields.Boolean()
    validation_comment = fields.Str(allow_none=True)
    validator = fields.Str()

    nomenclature_cd_nomenclature = fields.Str()
    nomenclature_mnemonique = fields.Str()
    nomenclature_label_default = fields.Str()


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

MAX_PER_PAGE = 10000


def _get_fields(params):
    """
    Construit l'ensemble des champs à retourner en fonction des paramètres

    Args:
        params: Dictionnaire des paramètres de la requête

    Returns:
        set: Ensemble des champs à inclure dans la réponse
    """
    enable_profile = current_app.config["FRONTEND"]["ENABLE_PROFILES"]
    fields_as_str = params.pop("fields", None)

    fields = set()
    if fields_as_str:
        fields.update({field for field in fields_as_str.split(",")})
    else:
        fields.update(DEFAULT_FIELDS)
        if enable_profile:
            fields.update(DEFAULT_PROFILE_FIELDS)

    # Add config parameters
    fields.update({col["column_name"] for col in blueprint.config["COLUMN_LIST"]})

    return fields


def _build_synthese_query(params, permissions, limit=MAX_PER_PAGE):
    """
    Fonction utilitaire pour construire la requête de base pour les données de synthèse

    Returns:
        tuple: (query, fields, lateral_join)
    """
    enable_profile = current_app.config["FRONTEND"]["ENABLE_PROFILES"]
    # Profile parameters
    score = params.pop("score", None)
    valid_distribution = params.pop("valid_distribution", None)
    valid_altitude = params.pop("valid_altitude", None)
    valid_phenology = params.pop("valid_phenology", None)
    use_profile_filter = valid_altitude or valid_distribution or valid_phenology

    no_auto = params.pop("no_auto", False)

    # Fields: Setup fields
    fields = _get_fields(params)

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

    synthese_subquery = (
        sa.select(Synthese)
        .order_by(Synthese.date_min.desc())
        .join(
            TDatasets,
            TDatasets.id_dataset == Synthese.id_dataset,
        )
        .where(TDatasets.validable == True)
        .limit(limit)
        .subquery()
    )
    synthese_alias = aliased(Synthese, synthese_subquery)

    last_validation_subquery = (
        sa.select(TValidations)
        .where(TValidations.uuid_attached_row == synthese_alias.unique_id_sinp)
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
            .where(VConsistancyData.id_synthese == synthese_alias.id_synthese)
            .limit(1)
            .subquery()
            .lateral("profile")
        )

        profile = aliased(VConsistancyData, profile_subquery)
        lateral_join[profile] = synthese_alias.profile

    relationships = list(
        {
            field.split(".", 1)[0]
            for field in fields
            if "." in field
            and not (field.startswith("last_validation.") or field.startswith("profile."))
        }
    )

    # Use synthese_alias to get relationship attributes
    base_relationships = [getattr(Synthese, rel) for rel in relationships]
    aliases = [aliased(rel.property.mapper.class_) for rel in base_relationships]

    # Use synthese_alias instead of Synthese
    query = db.session.query(synthese_alias, *aliases, *lateral_join.keys())

    # Join using the base Synthese relationships but querying from synthese_alias
    for base_rel, alias in zip(base_relationships, aliases):
        query = query.outerjoin(alias, getattr(synthese_alias, base_rel.key))

    for alias in lateral_join.keys():
        query = query.outerjoin(alias, sa.true())

    # filter with profile
    if enable_profile and use_profile_filter:
        if score is not None:
            query = query.where(profile.score == score)
        if valid_distribution is not None:
            query = query.where(profile.valid_distribution.is_(bool(valid_distribution)))
        if valid_altitude is not None:
            query = query.where(profile.valid_altitude.is_((bool(valid_altitude))))
        if valid_phenology is not None:
            query = query.where(profile.valid_phenology.is_(bool(valid_phenology)))

    if params.pop("modif_since_validation", None):
        query = query.where(synthese_alias.meta_update_date > last_validation.validation_date)

    if no_auto:
        query = query.where(last_validation.validation_auto == False)

    # Step 2: give SyntheseQuery the Core selectable from ORM query
    assert len(query.selectable.get_final_froms()) <= 2

    selectable = SyntheseQuery(
        synthese_alias,
        query.selectable,
        params,
    ).filter_query_all_filters(g.current_user, permissions)

    # Step 3: Construct Synthese model from query result
    syntheseQueryStatement = synthese_alias.query.options(
        *[
            contains_eager(base_rel, alias=alias)
            for base_rel, alias in zip(base_relationships, aliases)
        ]
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
    query = selectable.where(synthese_alias.the_geom_4326.isnot(None))

    return selectable, syntheseQueryStatement


@blueprint.route("/observations", methods=["GET", "POST"])
@permissions_required("C", module_code="VALIDATION")
def get_observations_last_validations(permissions):
    """
    Return synthese and t_validations data as GeoJSON filtered by form params
    Params must have same synthese fields names

    .. :quickref: Validation;

    Parameters:
    ------------
    :query str sort: str<'asc', 'desc'> trier dans l'ordre ascendant ou descendant (optionnel, 'order')
    :query str order_by: champs sur lequel appliquer le tri de données (optionnel. lié à 'sort')
    Returns
    -------
    FeatureCollection (GeoJSON)
    """
    params = (request.json if request.is_json else None) or {}
    params.update(request.args)

    # Sorting parameter
    sort = params.get("sort", "desc")
    order_by = sa.text(request.args.get("order_by", "last_validation.validation_date", str))
    sorting_active = sort != "" and order_by != ""

    limit = params.pop("limit", blueprint.config["NB_MAX_OBS_MAP"])

    # Get fields
    fields = _get_fields(params)

    query, syntheseQueryStatement = _build_synthese_query(params, permissions, limit=limit)

    # Sort
    if sorting_active:
        if sort == "asc":
            query = query.order_by(sa.asc(order_by))
        else:
            query = query.order_by(sa.desc(order_by))

    query = syntheseQueryStatement.from_statement(query)
    return jsonify(query.as_geofeaturecollection(fields=fields))


@blueprint.route("/", methods=["GET", "POST"])
@permissions_required("C", module_code="VALIDATION")
def get_validations(permissions):
    """
    Return last validations

    .. :quickref: Validation;

    Parameters:
    ------------
    :query str sort: str<'asc', 'desc'> trier dans l'ordre ascendant ou descendant (optionnel, 'order')
    :query str order_by: champs sur lequel appliquer le tri de données (optionnel. lié à 'sort')
    :query int page: numéro de page (requis)
    :query int per_page: nombre d'élément par page (requis)
    Returns
    -------
    json with items, total, per_page, page
    """
    params = (request.json if request.is_json else None) or {}
    params.update(request.args)

    limit = params.pop("limit", blueprint.config["NB_MAX_OBS_MAP"])

    DEFAULT_FIELDS = [
        TValidations.id_validation,
        TValidations.validation_date,
        TValidations.validation_auto,
        TValidations.validation_comment,
        TNomenclatures.cd_nomenclature.label("nomenclature_cd_nomenclature"),
        TNomenclatures.mnemonique.label("nomenclature_mnemonique"),
        TNomenclatures.label_default.label("nomenclature_label_default"),
    ]

    FIELDS_AUTHORIZED = {
        "observation": (
            Synthese,
            TValidations.uuid_attached_row == Synthese.unique_id_sinp,
            [
                Synthese.id_synthese,
                Synthese.nom_cite,
                Synthese.observers,
                Synthese.date_min,
                Synthese.date_max,
            ],
        ),
        "user_info": (
            User,
            TValidations.id_validator == User.id_role,
            [User.nom_complet.label("validator")],
        ),
    }

    selected = DEFAULT_FIELDS
    fields = params.get("fields", None)
    fields = fields.split(",") if fields else []

    format_ = params.get("format", "json")

    if "user_info" in fields:
        selected += FIELDS_AUTHORIZED["user_info"][2]
    if "observation" in fields or format_ == "geojson":
        selected += FIELDS_AUTHORIZED["observation"][2]

    if format_ == "geojson":
        selected += [sa.func.ST_AsGeoJSON(Synthese.the_geom_4326).label("the_geom_4326")]

    new_query = (
        sa.select(selected)
        .select_from(TValidations)
        .join(Synthese, TValidations.uuid_attached_row == Synthese.unique_id_sinp)
        .join(TDatasets, Synthese.id_dataset == TDatasets.id_dataset)
        .join(
            TNomenclatures,
            TValidations.id_nomenclature_valid_status == TNomenclatures.id_nomenclature,
        )
        .where(TValidations.validation_auto == False)
        .where(TDatasets.validable == True)
    )

    if "user_info" in fields:
        new_query = new_query.join(*FIELDS_AUTHORIZED["user_info"][:2])

    # Sorting parameter
    sort = params.get("sort", "desc")
    order_by = sa.text(request.args.get("order_by", "validation_date", str))
    sorting_active = sort != "" and order_by != ""

    # Pagination parameter (mandatory for JSON format)
    page = int(params.get("page", 0))
    per_page = int(params.get("per_page", 0))

    if page <= 0 or per_page <= 0:
        raise BadRequest(
            "Pagination is required for JSON format: 'page' and 'per_page' must be positive integers"
        )

    selectable = SyntheseQuery(Synthese, new_query, params)
    new_query = selectable.filter_query_all_filters(g.current_user, permissions)

    # Sort
    if sorting_active:
        if sort == "asc":
            new_query = new_query.order_by(sa.asc(order_by))
        else:
            new_query = new_query.order_by(sa.desc(order_by))

    offset = (page - 1) * per_page
    query = new_query.limit(per_page).offset(offset)

    count = db.session.scalar(new_query.with_only_columns([sa.func.count()]).order_by(None))

    if format_ == "geojson":
        data = rows_to_geojson(db.session.execute(query).all(), "the_geom_4326")
    else:
        data = ValidationSchema(many=True).dump(db.session.execute(query).all())
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
