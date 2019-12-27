import logging
from flask import Blueprint, current_app, request

from operator import itemgetter

import re

from sqlalchemy import select, desc, cast, DATE, func

import datetime

from geojson import FeatureCollection

from utils_flask_sqla.response import json_resp

from geonature.core.gn_meta.models import TDatasets

from geonature.core.gn_synthese.models import (
    Synthese,
    TSources,
    VMTaxonsSyntheseAutocomplete,
    VSyntheseForWebApp,
)

from geonature.core.gn_commons.models import BibTablesLocation

from .query import filter_query_all_filters

from geonature.utils.env import DB

from geonature.core.gn_permissions import decorators as permissions
from geonature.core.gn_commons.models import TValidations

from .models import VSyntheseValidation

# from geonature.core.gn_synthese.utils import query as synthese_query

from pypnnomenclature.models import TNomenclatures, BibNomenclaturesTypes

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
    truc (int): 
        essai
    

    Returns
    -------
    dict
        test

    """

    try:
        filters = {
            key: request.args.getlist(key) for key, value in request.args.items()
        }
        for key, value in filters.items():
            if "," in value[0] and key != "geoIntersection":
                filters[key] = value[0].split(",")

        result_limit = blueprint.config["NB_MAX_OBS_MAP"]

        q = DB.session.query(VSyntheseValidation)

        q = filter_query_all_filters(VSyntheseValidation, q, filters, info_role)

        q = q.order_by(VSyntheseValidation.date_min.desc())

        nb_total = 0

        data = q.limit(result_limit)
        columns = (
            blueprint.config["COLUMNS_API_VALIDATION_WEB_APP"]
            + blueprint.config["MANDATORY_COLUMNS"]
        )

        features = []

        for d in data:
            feature = d.get_geofeature(columns=columns)
            feature["properties"]["nom_vern_or_lb_nom"] = (
                d.nom_vern if d.lb_nom is None else d.lb_nom
            )
            features.append(feature)

        return {
            "data": FeatureCollection(features),
            "nb_obs_limited": nb_total == blueprint.config["NB_MAX_OBS_MAP"],
            "nb_total": nb_total,
        }
    except Exception as e:
        log.error(e)
        return (
            'INTERNAL SERVER ERROR ("get_synthese_data() error"): contactez l\'administrateur du site',
            500,
        )


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


@blueprint.route("/taxons_autocomplete", methods=["GET"])
@json_resp
def get_autocomplete_taxons_synthese():

    search_name = request.args.get("search_name")
    q = DB.session.query(VMTaxonsSyntheseAutocomplete)
    if search_name:
        search_name = search_name.replace(" ", "%")
        q = q.filter(VMTaxonsSyntheseAutocomplete.search_name.ilike(search_name + "%"))
    regne = request.args.get("regne")
    if regne:
        q = q.filter(VMTaxonsSyntheseAutocomplete.regne == regne)

    group2_inpn = request.args.get("group2_inpn")
    if group2_inpn:
        q = q.filter(VMTaxonsSyntheseAutocomplete.group2_inpn == group2_inpn)

    q = q.order_by(
        desc(VMTaxonsSyntheseAutocomplete.cd_nom == VMTaxonsSyntheseAutocomplete.cd_ref)
    )

    data = q.limit(20).all()
    return [d.as_dict() for d in data]


@blueprint.route("/history/<uuid_attached_row>", methods=["GET"])
@permissions.check_cruved_scope("R", True, module_code="VALIDATION")
@json_resp
def get_hist(info_role, uuid_attached_row):

    try:
        data = (
            DB.session.query(
                TValidations.id_nomenclature_valid_status,
                TValidations.validation_date,
                TValidations.validation_comment,
                Synthese.validator,
                TValidations.validation_auto,
                TNomenclatures.label_default,
                TNomenclatures.cd_nomenclature,
            )
            .join(
                TNomenclatures,
                TNomenclatures.id_nomenclature
                == TValidations.id_nomenclature_valid_status,
            )
            .join(Synthese, Synthese.unique_id_sinp == TValidations.uuid_attached_row)
            .filter(TValidations.uuid_attached_row == uuid_attached_row)
            .all()
        )

        history = []
        for row in data:
            line = {}
            line.update(
                {
                    "id_status": str(row[0]),
                    "date": str(row[1]),
                    "comment": str(row[2]),
                    "validator": str(row[3]),
                    "typeValidation": str(row[4]),
                    "label_default": str(row[5]),
                    "cd_nomenclature": str(row[6]),
                }
            )
            history.append(line)

        history = sorted(history, key=itemgetter("date"), reverse=True)
        return history

    except (Exception) as e:
        log.error(e)
        return (
            'INTERNAL SERVER ERROR ("get_hist() error"): contactez l\'administrateur du site',
            500,
        )


@blueprint.route("/date/<uuid>", methods=["GET"])
@json_resp
def get_validation_date(uuid):
    """
        Retourne la date de validation
        pour l'observation uuid
    """
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

