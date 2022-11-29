import logging
import datetime
import json

from flask import Blueprint, request, jsonify, current_app
from flask.json import jsonify
import sqlalchemy as sa
from sqlalchemy.orm import aliased, contains_eager, selectinload
from marshmallow import ValidationError

from pypnnomenclature.models import TNomenclatures, BibNomenclaturesTypes

from geonature.utils.env import DB, db
from geonature.core.gn_synthese.models import Synthese, TReport
from geonature.core.gn_profiles.models import VConsistancyData
from geonature.core.gn_synthese.utils.query_select_sqla import SyntheseQuery
from geonature.core.gn_permissions import decorators as permissions
from geonature.core.gn_commons.schemas import TValidationSchema
from geonature.core.gn_commons.models.base import TValidations

from werkzeug.exceptions import BadRequest
from geonature.core.gn_commons.models import TValidations
from geonature.core.notifications.utils import dispatch_notifications


blueprint = Blueprint("validation", __name__)
log = logging.getLogger()


@blueprint.route("", methods=["GET", "POST"])
@permissions.check_cruved_scope("R", True, module_code="VALIDATION")
def get_synthese_data(info_role):
    """
    Return synthese and t_validations data filtered by form params
    Params must have same synthese fields names

    .. :quickref: Validation;

    Parameters:
    ------------
    info_role (User):
        Information about the user asking the route. Auto add with kwargs

    Returns
    -------
    FeatureCollection
    """

    enable_profile = current_app.config["FRONTEND"]["ENABLE_PROFILES"]
    fields = {
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

    if enable_profile:
        fields |= {
            "profile.score",
            "profile.valid_phenology",
            "profile.valid_altitude",
            "profile.valid_distribution",
        }

    fields |= {col["column_name"] for col in blueprint.config["COLUMN_LIST"]}

    filters = (request.json if request.is_json else None) or {}

    result_limit = filters.pop("limit", blueprint.config["NB_MAX_OBS_MAP"])
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
        TValidations.query.filter(TValidations.uuid_attached_row == Synthese.unique_id_sinp)
        .order_by(TValidations.validation_date.desc())
        .limit(1)
        .subquery()
        .lateral("last_validation")
    )
    last_validation = aliased(TValidations, last_validation_subquery)
    lateral_join = {last_validation: Synthese.last_validation}

    if enable_profile:
        profile_subquery = (
            VConsistancyData.query.filter(VConsistancyData.id_synthese == Synthese.id_synthese)
            .limit(result_limit)
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

    query = query.filter(Synthese.the_geom_4326.isnot(None)).order_by(Synthese.date_min.desc())

    # filter with profile
    if enable_profile:
        score = filters.pop("score", None)
        if score is not None:
            query = query.filter(profile.score == score)
        valid_distribution = filters.pop("valid_distribution", None)
        if valid_distribution is not None:
            query = query.filter(profile.valid_distribution.is_(valid_distribution))
        valid_altitude = filters.pop("valid_altitude", None)
        if valid_altitude is not None:
            query = query.filter(profile.valid_altitude.is_(valid_altitude))
        valid_phenology = filters.pop("valid_phenology", None)
        if valid_phenology is not None:
            query = query.filter(profile.valid_phenology.is_(valid_phenology))

    if filters.pop("modif_since_validation", None):
        query = query.filter(Synthese.meta_update_date > last_validation.validation_date)

    # Filter only validable dataset

    query = query.filter(dataset_alias.validable == True)

    # Step 2: give SyntheseQuery the Core selectable from ORM query
    assert len(query.selectable.froms) == 1

    query = (
        SyntheseQuery(Synthese, query.selectable, filters, query_joins=query.selectable.froms[0])
        .filter_query_all_filters(info_role)
        .limit(result_limit)
    )

    # Step 3: Construct Synthese model from query result
    syntheseModelQuery = Synthese.query.options(
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
        syntheseModelQuery = syntheseModelQuery.options(
            selectinload(Synthese.reports).joinedload(TReport.report_type)
        )

    query = syntheseModelQuery.from_statement(query)

    # The raise option ensure that we have correctly retrived relationships data at step 3
    return jsonify(query.as_geofeaturecollection(fields=fields))


@blueprint.route("/statusNames", methods=["GET"])
@permissions.check_cruved_scope("R", True, module_code="VALIDATION")
def get_statusNames(info_role):
    nomenclatures = (
        TNomenclatures.query.join(BibNomenclaturesTypes)
        .filter(BibNomenclaturesTypes.mnemonique == "STATUT_VALID")
        .filter(TNomenclatures.active == True)
        .order_by(TNomenclatures.cd_nomenclature)
    )
    return jsonify(
        [
            nomenc.as_dict(
                fields=["id_nomenclature", "mnemonique", "cd_nomenclature", "definition_default"]
            )
            for nomenc in nomenclatures.all()
        ]
    )


@blueprint.route("/<id_synthese>", methods=["POST"])
@permissions.check_cruved_scope("C", True, module_code="VALIDATION")
def post_status(info_role, id_synthese):
    data = dict(request.get_json())
    try:
        id_validation_status = data["statut"]
    except KeyError:
        raise BadRequest("Aucun statut de validation n'est sélectionné")
    try:
        validation_comment = data["comment"]
    except KeyError:
        raise BadRequest("Missing 'comment'")

    id_synthese = id_synthese.split(",")

    for id in id_synthese:
        # t_validations.id_validation:

        # t_validations.uuid_attached_row:
        synthese = Synthese.query.get_or_404(int(id))
        uuid = synthese.unique_id_sinp

        # t_validations.id_validator:
        id_validator = info_role.id_role

        # t_validations.validation_date
        val_date = datetime.datetime.now()

        # t_validations.validation_auto
        val_auto = False
        val_dict = {
            "uuid_attached_row": uuid,
            "id_nomenclature_valid_status": id_validation_status,
            "id_validator": id_validator,
            "validation_comment": validation_comment,
            "validation_date": str(val_date),
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
        notify_validation_state_change(synthese, validation)

        DB.session.commit()

    return jsonify(TNomenclatures.query.get(id_validation_status).as_dict())


@blueprint.route("/date/<uuid:uuid>", methods=["GET"])
def get_validation_date(uuid):
    """
    Retourne la date de validation
    pour l'observation uuid
    """
    s = Synthese.query.filter_by(unique_id_sinp=uuid).lateraljoin_last_validation().first_or_404()
    if s.last_validation:
        return jsonify(str(s.last_validation.validation_date))
    else:
        return "", 204


# Send notification
def notify_validation_state_change(synthese, validation):
    dispatch_notifications(
        code_categories=["VALIDATION-STATUS-CHANGED%"],
        id_roles=[synthese.id_digitiser],
        title="Changement de statut de validation",
        url=(
            current_app.config["URL_APPLICATION"]
            + "/#/synthese/occurrence/"
            + str(synthese.id_synthese),
        ),
        context={
            "synthese": synthese,
            "validation": validation,
            "status": validation.nomenclature_valid_status,
        },
    )
