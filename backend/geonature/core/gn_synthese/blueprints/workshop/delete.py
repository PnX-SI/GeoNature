from sqlalchemy import select
from geonature.utils.env import db
from geonature.core.gn_synthese.models import Synthese
import sqlalchemy as sa
from werkzeug.exceptions import NotFound

def delete_observation(id_synthese):
    observation_item = db.session.scalar(sa.exists(Synthese).where(Synthese.id_synthese == id_synthese).select())
    if not observation_item :
        raise NotFound
    db.session.execute(sa.delete(Synthese).where(Synthese.id_synthese == id_synthese))
    db.session.commit()
    return "",204

