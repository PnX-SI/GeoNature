from geoalchemy2 import Geometry
from sqlalchemy import ForeignKey
from flask import current_app

from geonature.utils.env import DB
from geonature.utils.utilssqlalchemy import serializable

from geonature.utils.env import DB
from geonature.utils.utilssqlalchemy import serializable, geoserializable
from geonature.utils.env import DB


@serializable
class BibAreasTypes(DB.Model):
    __tablename__ = "bib_areas_types"
    __table_args__ = {"schema": "ref_geo"}
    id_type = DB.Column(DB.Integer, primary_key=True)
    type_name = DB.Column(DB.Unicode)
    type_code = DB.Column(DB.Unicode)
    type_desc = DB.Column(DB.Unicode)
    ref_name = DB.Column(DB.Unicode)
    ref_version = DB.Column(DB.Integer)
    num_version = DB.Column(DB.Unicode)


@serializable
class LAreas(DB.Model):
    __tablename__ = "l_areas"
    __table_args__ = {"schema": "ref_geo"}
    id_area = DB.Column(DB.Integer, primary_key=True)
    id_type = DB.Column(DB.Integer, ForeignKey("ref_geo.bib_areas_types.id_type"))
    area_name = DB.Column(DB.Unicode)
    area_code = DB.Column(DB.Unicode)
    geom = DB.Column(Geometry("GEOMETRY", current_app.config["LOCAL_SRID"]))
    source = DB.Column(DB.Unicode)
    geom = DB.Column(Geometry("GEOMETRY", 4326))
    area_type = DB.relationship("BibAreasTypes", lazy="select")


@serializable
class LiMunicipalities(DB.Model):
    __tablename__ = "li_municipalities"
    __table_args__ = {"schema": "ref_geo"}
    id_municipality = DB.Column(DB.Integer, primary_key=True)
    id_area = DB.Column(DB.Integer)
    status = DB.Column(DB.Unicode)
    insee_com = DB.Column(DB.Unicode)
    nom_com = DB.Column(DB.Unicode)
    insee_arr = DB.Column(DB.Unicode)
    nom_dep = DB.Column(DB.Unicode)
    insee_dep = DB.Column(DB.Unicode)
    nom_reg = DB.Column(DB.Unicode)
    insee_reg = DB.Column(DB.Unicode)
    code_epci = DB.Column(DB.Unicode)
    plani_precision = DB.Column(DB.Float)
    siren_code = DB.Column(DB.Unicode)
    canton = DB.Column(DB.Unicode)
    population = DB.Column(DB.Integer)
    multican = DB.Column(DB.Unicode)
    cc_nom = DB.Column(DB.Unicode)
    cc_siren = DB.Column(DB.BigInteger)
    cc_nature = DB.Column(DB.Unicode)
    cc_date_creation = DB.Column(DB.Unicode)
    cc_date_effet = DB.Column(DB.Unicode)
    insee_commune_nouvelle = DB.Column(DB.Unicode)
    meta_create_date = DB.Column(DB.DateTime)
    meta_update_date = DB.Column(DB.DateTime)
