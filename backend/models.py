from sqlalchemy import ForeignKey
from sqlalchemy.sql import select

from geonature.utils.utilssqlalchemy import serializable
from geonature.utils.env import DB


@serializable
class VSyntheseCommunes(DB.Model):
    __tablename__ = "vm_synthese_communes"
    __table_args__ = {"schema": "gn_dashboard"}
    area_name = DB.Column(DB.Unicode, primary_key=True)
    geom_area_4326 = DB.Column(DB.Unicode)
    id_type = DB.Column(DB.Unicode)
    nb_obs = DB.Column(DB.Integer)
    nb_taxons = DB.Column(DB.Integer)
