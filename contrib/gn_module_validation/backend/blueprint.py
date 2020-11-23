
import ast
import logging
import datetime
from operator import itemgetter
from sqlalchemy import select, func, literal_column
from flask import Blueprint, request
from geojson import FeatureCollection

from utils_flask_sqla.response import json_resp
from utils_flask_sqla_geo.serializers import sqla_query_to_geojson
from pypnnomenclature.models import TNomenclatures, BibNomenclaturesTypes


from geonature.utils.env import DB
from geonature.utils.utilssqlalchemy import test_is_uuid
from geonature.core.gn_synthese.models import Synthese
from geonature.core.gn_synthese.utils.query_select_sqla import SyntheseQuery
from geonature.core.gn_permissions import decorators as permissions
from geonature.core.gn_commons.models import TValidations

from .models import VSyntheseValidation

blueprint = Blueprint("validation", __name__)
log = logging.getLogger()



@blueprint.route("", methods=["GET"])
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

    filters = {key: request.args.getlist(key)
               for key, value in request.args.items()}
    for key, value in filters.items():
        if "," in value[0] and key != "geoIntersection":
            filters[key] = value[0].split(",")

    if "limit" in filters:
        result_limit = filters.pop("limit")[0]
    else:
        result_limit = blueprint.config["NB_MAX_OBS_MAP"]

    # Construction de la requête select
    # Les champs correspondent aux champs obligatoires
    #       + champs définis par l'utilisateur
    columns = (
        blueprint.config["COLUMNS_API_VALIDATION_WEB_APP"]
        + blueprint.config["MANDATORY_COLUMNS"]
    )

    select_columns = []
    for c in columns:
        try:
            select_columns.append(getattr(VSyntheseValidation, c))
        except AttributeError as error:
            log.warning("Validation : colonne {} inexistante".format(c))

    # Construction de la requête avec SyntheseQuery
    #   Pour profiter des opérations CRUVED
    query = (
        select(select_columns)
        .where(VSyntheseValidation.the_geom_4326.isnot(None))
        .order_by(VSyntheseValidation.date_min.desc())
    )
    validation_query_class = SyntheseQuery(VSyntheseValidation, query, filters)
    validation_query_class.filter_query_all_filters(info_role)

    # TODO le transférer dans sqla-geo
    # Génération d'une requête sql générant un geojson valide
    geojson_features = sqla_query_to_geojson(
        session=DB.session,
        query=validation_query_class.query.limit(
            result_limit
        ),
        id_col="id_synthese",
        geom_col="geojson",
        geom_srid=4326,
        is_geojson=True,
        keep_id_col=True
    )
    # TODO nb_total pas vraiment traité
    nb_total = 0

    return {
        "data": geojson_features,
        "nb_obs_limited": nb_total == blueprint.config["NB_MAX_OBS_MAP"],
        "nb_total": nb_total,
    }



@blueprint.route("/statusNames", methods=["GET"])
@permissions.check_cruved_scope("R", True, module_code="VALIDATION")
@json_resp
def get_statusNames(info_role):
    try:
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
    except Exception as e:
        log.error(e)
        return (
            'INTERNAL SERVER ERROR ("get_status_names() error"): contactez l\'administrateur du site',
            500,
        )


@blueprint.route("/<id_synthese>", methods=["POST"])
@permissions.check_cruved_scope("C", True, module_code="VALIDATION")
@json_resp
def post_status(info_role, id_synthese):
    try:
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
            )

            # t_validations.id_validator:
            id_validator = info_role.id_role

            # t_validations.validation_date
            val_date = datetime.datetime.now()

            # t_validations.validation_auto
            val_auto = False

            # insert values in t_validations
            addValidation = TValidations(
                uuid,
                id_validation_status,
                id_validator,
                validation_comment,
                val_date,
                val_auto,
            )

            DB.session.add(addValidation)
            DB.session.commit()

        DB.session.close()

        return data

    except Exception as e:
        log.error(e)
        return (
            'INTERNAL SERVER ERROR ("post_status() error"): contactez l\'administrateur du site',
            500,
        )


@blueprint.route("/definitions", methods=["GET"])
@permissions.check_cruved_scope("R", True, module_code="VALIDATION")
@json_resp
def get_definitions(info_role):
    """
        return validation status definitions stored in t_nomenclatures
    """
    try:
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
    except Exception as e:
        log.error(e)
        return (
            'INTERNAL SERVER ERROR ("get_definitions() error") : contactez l\'administrateur du site',
            500,
        )



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
            'Value error uuid is not valid',
            500,
        )

    try:
        date = DB.session.execute(
            select([VSyntheseValidation.validation_date]).where(
                VSyntheseValidation.unique_id_sinp == uuid
            )
        ).fetchone()[0]
        return str(date)
    except (Exception) as e:
        log.error(e)
        return (
            'INTERNAL SERVER ERROR ("get_validation_date(uuid) error"): contactez l\'administrateur du site',
            500,
        )
