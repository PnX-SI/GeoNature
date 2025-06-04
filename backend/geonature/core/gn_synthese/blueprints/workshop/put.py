from sqlalchemy import select
from geonature.utils.env import db
from geonature.core.gn_synthese.models import Synthese
import sqlalchemy as sa
from werkzeug.exceptions import NotFound, BadRequest
from flask import request
from geonature.core.gn_permissions.decorators import permissions_required


@permissions_required("U", module_code="SYNTHESE")
def update_observation(id_synthese, permissions):
    modified_fields = request.json or {}

    observation_item = db.session.get(Synthese, id_synthese)
    if not observation_item:
        raise NotFound

    for attr in modified_fields:
        if not hasattr(observation_item, attr):
            raise BadRequest(f"Le champ '{attr}' n'existe pas dans le modèle Synthese.")
        value = modified_fields[attr]
        setattr(observation_item, attr, value)

    db.session.commit()

    return "", 204
