
from sqlalchemy import ForeignKey

from utils_flask_sqla.serializers import serializable

from geonature.utils.env import DB

@serializable
class CorAreaStatus(DB.Model):
    __tablename__ = "cor_area_status"
    __table_args__ = {"schema": "ref_geo"}
    cd_sig = DB.Column(DB.Unicode, primary_key=True)
    id_area = DB.Column(DB.Integer, ForeignKey("ref_geo.l_areas.id_area"), primary_key=True)
