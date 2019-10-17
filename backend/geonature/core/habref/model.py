"""
Models for ref_habitat schema
"""
from sqlalchemy import ForeignKey
from utils_flask_sqla.serializers import serializable

from geonature.utils.env import DB


@serializable
class Habref(DB.Model):
    __tablename__ = "habref"
    __table_args__ = {"schema": "ref_habitat"}
    cd_hab = DB.Column(DB.Integer, primary_key=True)
    fg_validite = DB.Column(DB.Unicode)
    cd_typo = DB.Column(DB.Integer, ForeignKey("ref_habitat.typoref.cd_typo"))
    lb_code = DB.Column(DB.Unicode)
    lb_hab_fr = DB.Column(DB.Unicode)
    lb_hab_fr_complet = DB.Column(DB.Unicode)
    lb_hab_en = DB.Column(DB.Unicode)
    lb_auteur = DB.Column(DB.Unicode)
    niveau = DB.Column(DB.Integer)
    lb_niveau = DB.Column(DB.Unicode)
    cd_hab_sup = DB.Column(DB.Integer)
    path_cd_hab = DB.Column(DB.Unicode)
    france = DB.Column(DB.Unicode)
    lb_description = DB.Column(DB.Unicode)
