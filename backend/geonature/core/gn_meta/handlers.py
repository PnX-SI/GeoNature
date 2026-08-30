import logging

from flask import g
from marshmallow import ValidationError, EXCLUDE
from psycopg2.errors import UniqueViolation
from sqlalchemy.exc import IntegrityError
from werkzeug.exceptions import BadRequest, Conflict, InternalServerError, Forbidden

from geonature.core.gn_meta.schemas import (
    PublicationSchema,
    DatasetSchema,
    AcquisitionFrameworkSchema,
)
from geonature.core.gn_permissions.tools import get_scopes_by_action
from geonature.utils.env import db

log = logging.getLogger()


def _load_or_400(schema, data, instance):
    try:
        return schema.load(data, instance=instance)
    except ValidationError as error:
        log.exception(error)
        raise BadRequest(error.messages) from error


def _save_or_raise(instance, error_message):
    db.session.add(instance)
    try:
        db.session.commit()
    except IntegrityError as err:
        db.session.rollback()
        # If the error is because of a unique constraint violation, we raise the detail of the uniqueness error
        if isinstance(err.orig, UniqueViolation):
            detail = getattr(getattr(err.orig, "diag", None), "message_detail", None)
            if not detail:
                detail = str(err.orig).splitlines()[0]
            raise Conflict(detail) from err
        raise InternalServerError(error_message) from err
    return instance


def publication_handler(publication, data, partial=False):
    publication_schema = PublicationSchema(
        only=[
            "publication_reference",
            "publication_url",
            "description_publication",
            "id_nomenclature_type_publication",
        ],
        partial=partial,
    )
    publication = _load_or_400(publication_schema, data, publication)
    return _save_or_raise(publication, "An error occured while creating/updating a publication !")


def dataset_handler(dataset, data, partial=False):
    dataset_schema = DatasetSchema(
        only=[
            "cor_dataset_actor",
            "modules",
            "cor_objectifs",
            "cor_territories",
            "cor_classes_ebv",
        ],
        unknown=EXCLUDE,
        partial=partial,
    )
    dataset = _load_or_400(dataset_schema, data, dataset)
    return _save_or_raise(dataset, "An error occured while creating/updating a dataset !")


def acquisition_framework_handler(request, *, acquisition_framework, partial=False):
    # Test des droits d'édition du acquisition framework si modification

    # 🔎 Récupération des données brutes du body

    if acquisition_framework.id_acquisition_framework is not None:
        user_cruved = get_scopes_by_action(module_code="METADATA")

        # verification des droits d'édition pour le acquisition framework
        if not acquisition_framework.has_instance_permission(user_cruved["U"]):
            raise Forbidden(
                "User {} has no right in acquisition_framework {}".format(
                    g.current_user, acquisition_framework.id_acquisition_framework
                )
            )
    else:
        acquisition_framework.id_digitizer = g.current_user.id_role

    acquisitionFrameworkSchema = AcquisitionFrameworkSchema(
        only=["cor_af_actor", "cor_objectifs", "cor_territories"],
        unknown=EXCLUDE,
        partial=partial,
    )

    acquisition_framework = _load_or_400(
        acquisitionFrameworkSchema, request.get_json(), acquisition_framework
    )

    return _save_or_raise(
        acquisition_framework,
        "An error occured while creating/updating an acquisition framework !",
    )
