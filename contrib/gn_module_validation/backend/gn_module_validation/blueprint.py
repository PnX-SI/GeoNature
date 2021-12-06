import logging
import datetime
import json
from flask.globals import session
from flask.json import jsonify
from geonature.core.gn_commons.models.base import TValidations
from sqlalchemy import select, func
from flask import Blueprint, request, jsonify
from geojson import FeatureCollection
from sqlalchemy.sql.expression import cast
from sqlalchemy.sql.sqltypes import Integer
from marshmallow import ValidationError

from utils_flask_sqla.response import json_resp
from utils_flask_sqla.serializers import SERIALIZERS
from pypnnomenclature.models import TNomenclatures, BibNomenclaturesTypes


from geonature.utils.env import DB
from geonature.utils.utilssqlalchemy import test_is_uuid
from geonature.core.gn_synthese.models import Synthese
from geonature.core.gn_synthese.utils.query_select_sqla import SyntheseQuery
from geonature.core.gn_permissions import decorators as permissions
from geonature.core.gn_commons.schemas import TValidationSchema

from werkzeug.exceptions import BadRequest
from geonature.core.gn_commons.models import TValidations

from .models import VSyntheseValidation

blueprint = Blueprint("validation", __name__)
log = logging.getLogger()


@blueprint.route("", methods=["GET", "POST"])
@permissions.check_cruved_scope("R", True, module_code="VALIDATION")
@json_resp
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
    dict
        {
        "data": FeatureCollection
        "nb_obs_limited": int est-ce que le nombre de données retournée est > au nb limites
        "nb_total": nb_total,
        }

    """
    if request.json:
        filters = request.json
    elif request.data:
        #  decode byte to str - compat python 3.5
        filters = json.loads(request.data.decode("utf-8"))
    else:
        filters = {key: request.args.get(key) for key, value in request.args.items()}


    if "limit" in filters:
        result_limit = filters.pop("limit")
    else:
        result_limit = blueprint.config["NB_MAX_OBS_MAP"]
    # Construction de la requête select
    # Les champs correspondent aux champs obligatoires
    #       + champs définis par l'utilisateur
    columns = (
        blueprint.config["COLUMN_LIST"]
        + blueprint.config["MANDATORY_COLUMNS"]
    )
    # remove doublon
    columns = list({v['column_name']:v for v in columns}.values())
    select_columns = []
    serializer = {}
    for column_config in columns:
        try:
            if "func" in column_config:
                col = getattr(VSyntheseValidation, column_config["id_nomenclature_field"])
            else:
                col = getattr(VSyntheseValidation, column_config["column_name"])
        except AttributeError as error:
            log.error("Validation : colonne {} inexistante".format(col))
        else:
            if "func" in column_config:
                label = column_config.get("column_name")
                if column_config["func"] == "cd_nomenclature":
                    select_columns.append(
                        func.ref_nomenclatures.get_cd_nomenclature(col).label(label)
                    )
                else:
                    select_columns.append(
                        func.ref_nomenclatures.get_nomenclature_label(col).label(label)
                    )

                serializer[label] = lambda x: x
            else:
                select_columns.append(col)
                serializer[column_config["column_name"]] = SERIALIZERS.get(
                    col.type.__class__.__name__.lower(), lambda x: x
                )
    # Construction de la requête avec SyntheseQuery
    #  Pour profiter des opérations CRUVED
    query = (
        select(select_columns)
        .where(VSyntheseValidation.the_geom_4326.isnot(None))
        .order_by(VSyntheseValidation.date_min.desc())
    )
    valid_distribution = filters.pop("valid_distribution", None)
    valid_altitude = filters.pop("valid_altitude", None)
    valid_phenology = filters.pop("valid_phenology", None)
    score = filters.pop("score", None)
    validation_query_class = SyntheseQuery(VSyntheseValidation, query, filters)

    #filter with profile
    if score:
        validation_query_class.query = validation_query_class.query.where(
            VSyntheseValidation.valid_phenology.cast(Integer)+ 
            VSyntheseValidation.valid_altitude.cast(Integer) + 
            VSyntheseValidation.valid_distribution.cast(Integer)
             == score
        )

    if valid_distribution is not None:
        validation_query_class.query = validation_query_class.query.where(
            VSyntheseValidation.valid_distribution.is_(valid_distribution)
        )
    if valid_altitude is not None:
        validation_query_class.query = validation_query_class.query.where(
            VSyntheseValidation.valid_altitude.is_(valid_altitude)
        )
    if valid_phenology is not None:
        validation_query_class.query = validation_query_class.query.where(
            VSyntheseValidation.valid_phenology.is_(valid_phenology)
        )

    validation_query_class.filter_query_all_filters(info_role)
    result = DB.engine.execute(validation_query_class.query.limit(result_limit))
    nb_total = 0
    geojson_features = []
    properties = {}
    # TODO : add join on VConsistency data
    for r in result:
        properties = {k: serializer[k](r[k]) for k in serializer.keys()}
        properties["score"] = (
            r["valid_distribution"] or 0) + (
                r["valid_phenology"] or 0) + (
                    r["valid_altitude"] or 0)
        properties["nom_vern_or_lb_nom"] = (
            r["nom_vern"] if r["nom_vern"] else r["lb_nom"]
        )
        geojson = json.loads(r["geojson"])
        geojson["properties"] = properties
        geojson["id"] = r["id_synthese"]
        geojson_features.append(geojson)

    return {
        "data": FeatureCollection(geojson_features),
        "nb_obs_limited": nb_total == blueprint.config["NB_MAX_OBS_MAP"],
        "nb_total": nb_total,
    }


@blueprint.route("/statusNames", methods=["GET"])
@permissions.check_cruved_scope("R", True, module_code="VALIDATION")
def get_statusNames(info_role):
    nomenclatures = (
        TNomenclatures.query
        .join(BibNomenclaturesTypes)
        .filter(BibNomenclaturesTypes.mnemonique == "STATUT_VALID")
        .filter(TNomenclatures.active == True)
        .order_by(TNomenclatures.cd_nomenclature)
    )
    return jsonify([
            nomenc.as_dict(fields=['id_nomenclature', 'mnemonique',
                                   'cd_nomenclature', 'definition_default'])
            for nomenc in nomenclatures.all()
    ])


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
        uuid = DB.session.query(Synthese.unique_id_sinp).filter(
            Synthese.id_synthese == int(id)
        ).one()

        # t_validations.id_validator:
        id_validator = info_role.id_role

        # t_validations.validation_date
        val_date = datetime.datetime.now()

        # t_validations.validation_auto
        val_auto = False
        val_dict = {
            "uuid_attached_row": uuid[0],
            "id_nomenclature_valid_status": id_validation_status,
            "id_validator" : id_validator,
            "validation_comment" : validation_comment,
            "validation_date": str(val_date),
            "validation_auto" : val_auto,
        }
        # insert values in t_validations
        validationSchema = TValidationSchema()
        try:
            validation = validationSchema.load(
                val_dict, instance=TValidations(),
                session=DB.session
                )
        except ValidationError as error:
            raise BadRequest(error.messages)
        DB.session.add(validation)
        DB.session.commit()

    return jsonify(data)


@blueprint.route("/date/<uuid:uuid>", methods=["GET"])
def get_validation_date(uuid):
    """
    Retourne la date de validation
    pour l'observation uuid
    """
    v = VSyntheseValidation.query.filter_by(unique_id_sinp=uuid).first_or_404()
    return jsonify(str(v.validation_date))
