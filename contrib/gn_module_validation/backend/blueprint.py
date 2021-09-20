import ast
import logging
import datetime
import json
from flask.globals import session
from flask.json import jsonify
from geonature.core.gn_commons.models.base import TValidations
from sqlalchemy import select, func
from flask import Blueprint, request
from geojson import FeatureCollection
from sqlalchemy.sql.expression import cast
from sqlalchemy.sql.sqltypes import Integer

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
from geonature.core.gn_profiles.models import VConsistancyData

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
    result_limit = 100
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
    # add profiles columns
    columns_profile = ["valid_distribution", "valid_phenology", "valid_altitude"]
    for col in columns_profile:
        select_columns.append(
            getattr(VConsistancyData, col)
        )
        serializer[col] = lambda x : x
    # Construction de la requête avec SyntheseQuery
    #   Pour profiter des opérations CRUVED
    query = (
        select(select_columns)
        .where(VSyntheseValidation.the_geom_4326.isnot(None))
        .order_by(VSyntheseValidation.date_min.desc())
    )
    score = None
    if "score" in filters :
        score = filters.pop("score")

    validation_query_class = SyntheseQuery(VSyntheseValidation, query, filters)
    validation_query_class.add_join(
        VConsistancyData, VConsistancyData.id_synthese,
        VSyntheseValidation.id_synthese, join_type="left"
    )

    #filter with profile
    if score:
        validation_query_class.query = validation_query_class.query.where(
            VConsistancyData.valid_phenology.cast(Integer)+ 
            VConsistancyData.valid_altitude.cast(Integer) + 
            VConsistancyData.valid_distribution.cast(Integer)
             == score
        )

    validation_query_class.filter_query_all_filters(info_role)
    print(validation_query_class.query)
    result = DB.engine.execute(validation_query_class.query.limit(100))
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
        geojson = ast.literal_eval(r["geojson"])
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
@json_resp
def get_statusNames(info_role):
    nomenclatures = (
        DB.session.query(TNomenclatures)
        .join(
            BibNomenclaturesTypes,
            BibNomenclaturesTypes.id_type == TNomenclatures.id_type,
        )
        .filter(BibNomenclaturesTypes.mnemonique == "STATUT_VALID")
        .filter(TNomenclatures.active == True)
        .order_by(TNomenclatures.cd_nomenclature)
        .all()
    )
    return [
        {
            "id_nomenclature": n.id_nomenclature,
            "mnemonique": n.mnemonique,
            "cd_nomenclature": n.cd_nomenclature,
        }
        for n in nomenclatures
    ]


@blueprint.route("/<id_synthese>", methods=["POST"])
@permissions.check_cruved_scope("C", True, module_code="VALIDATION")
def post_status(info_role, id_synthese):
    data = dict(request.get_json())
    id_validation_status = data["statut"]
    validation_comment = data["comment"]

    if id_validation_status == "":
        return "Aucun statut de validation n'est sélectionné", 400

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
        validation, errors = validationSchema.load(
            val_dict, instance=TValidations(),
            session=DB.session
            )
        if bool(errors):
            log.error(errors)
            raise BadRequest(errors)
        DB.session.add(validation)
        DB.session.commit()

    return jsonify(data)



@blueprint.route("/definitions", methods=["GET"])
@permissions.check_cruved_scope("R", True, module_code="VALIDATION")
@json_resp
def get_definitions(info_role):
    """
    return validation status definitions stored in t_nomenclatures
    """
    definitions = []
    for key in blueprint.config["STATUS_INFO"].keys():
        nomenclature_statut = DB.session.execute(
            select([TNomenclatures.mnemonique]).where(
                TNomenclatures.id_nomenclature == int(key)
            )
        ).fetchone()
        nomenclature_definitions = DB.session.execute(
            select([TNomenclatures.definition_default]).where(
                TNomenclatures.id_nomenclature == int(key)
            )
        ).fetchone()
        definitions.append(
            {
                "status_id": key,
                "status": nomenclature_statut[0],
                "definition": nomenclature_definitions[0],
            }
        )
    nomenclatures = (
        DB.session.query(TNomenclatures)
        .join(
            BibNomenclaturesTypes,
            BibNomenclaturesTypes.id_type == TNomenclatures.id_type,
        )
        .filter(BibNomenclaturesTypes.mnemonique == "STATUT_VALID")
        .filter(TNomenclatures.active == True)
        .all()
    )

    return [
        {
            "status_id": n.id_nomenclature,
            "cd_nomenclature": n.cd_nomenclature,
            "status": n.mnemonique,
            "definition": n.definition_default,
        }
        for n in nomenclatures
    ]


@blueprint.route("/date/<uuid>", methods=["GET"])
@json_resp
def get_validation_date(uuid):
    """
    Retourne la date de validation
    pour l'observation uuid
    """

    # Test if uuid_attached_row is uuid
    if not test_is_uuid(uuid):
        return (
            "Value error uuid is not valid",
            500,
        )

    date = DB.session.execute(
        select([VSyntheseValidation.validation_date]).where(
            VSyntheseValidation.unique_id_sinp == uuid
        )
    ).fetchone()[0]
    return str(date)

