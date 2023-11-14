import logging

from werkzeug.exceptions import BadRequest

from pypnnomenclature.models import TNomenclatures, BibNomenclaturesTypes
from pypnusershub.db.models import User
from utils_flask_sqla.response import json_resp

from geonature.core.gn_commons.models import TValidations
from geonature.core.gn_permissions import decorators as permissions
from geonature.utils.env import DB
from geonature.utils.utilssqlalchemy import test_is_uuid


from ..routes import routes

log = logging.getLogger()


@routes.route("/history/<uuid_attached_row>", methods=["GET"])
@permissions.check_cruved_scope("R", module_code="SYNTHESE")
@json_resp
def get_hist(uuid_attached_row):
    # Test if uuid_attached_row is uuid
    if not test_is_uuid(uuid_attached_row):
        raise BadRequest("Value error uuid_attached_row is not valid")
    """
    Here we use execute() instead of scalars() because
    we need a list of sqlalchemy.engine.Row objects
    """
    data = DB.session.execute(
        DB.select(
            TValidations.id_nomenclature_valid_status,
            TValidations.validation_date,
            TValidations.validation_comment,
            User.nom_role + " " + User.prenom_role,
            TValidations.validation_auto,
            TNomenclatures.label_default,
            TNomenclatures.cd_nomenclature,
        )
        .join(
            TNomenclatures,
            TNomenclatures.id_nomenclature == TValidations.id_nomenclature_valid_status,
        )
        .join(User, User.id_role == TValidations.id_validator)
        .where(TValidations.uuid_attached_row == uuid_attached_row)
        .order_by(TValidations.validation_date)
    ).all()

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

    return history
