from sqlalchemy import select
from geonature.utils.env import db
from geonature.core.gn_synthese.models import Synthese
import sqlalchemy as sa
from werkzeug.exceptions import NotFound
from geonature.core.gn_permissions.decorators import permissions_required

@permissions_required("D", module_code="SYNTHESE")
def delete_observation(id_synthese, permissions):
    observation_item = db.session.scalar(sa.exists(Synthese).where(Synthese.id_synthese == id_synthese).select())
    if not observation_item :
        raise NotFound
    db.session.execute(sa.delete(Synthese).where(Synthese.id_synthese == id_synthese))
    db.session.commit()
    return "",204

