from datetime import datetime

from geoalchemy2 import Geometry
from sqlalchemy import ForeignKey

from utils_flask_sqla.serializers import serializable
from utils_flask_sqla_geo.serializers import geoserializable

from .env import db

from sqlalchemy.ext.hybrid import hybrid_property


@serializable
class BibAreasTypes(db.Model):
    __tablename__ = "bib_areas_types"
    __table_args__ = {"schema": "ref_geo"}
    id_type = db.Column(db.Integer, primary_key=True)
    type_name = db.Column(db.Unicode)
    type_code = db.Column(db.Unicode)
    type_desc = db.Column(db.Unicode)
    ref_name = db.Column(db.Unicode)
    ref_version = db.Column(db.Integer)
    num_version = db.Column(db.Unicode)


@geoserializable
class LAreas(db.Model):
    __tablename__ = "l_areas"
    __table_args__ = {"schema": "ref_geo"}
    id_area = db.Column(db.Integer, primary_key=True)
    id_type = db.Column(db.Integer, ForeignKey("ref_geo.bib_areas_types.id_type"))
    area_name = db.Column(db.Unicode)
    area_code = db.Column(db.Unicode)
    geom = db.Column(Geometry("GEOMETRY"))
    centroid = db.Column(Geometry("POINT"))
    geojson_4326 = db.Column(db.Unicode)
    source = db.Column(db.Unicode)
    enable = db.Column(db.Boolean, nullable=False, default=True)
    meta_create_date = db.Column(db.DateTime, default=datetime.now)
    meta_update_date = db.Column(db.DateTime, default=datetime.now, onupdate=datetime.now)
    area_type = db.relationship("BibAreasTypes", lazy="select")


@serializable
class LiMunicipalities(db.Model):
    __tablename__ = "li_municipalities"
    __table_args__ = {"schema": "ref_geo"}
    id_municipality = db.Column(db.Integer, primary_key=True)
    id_area = db.Column(db.Integer)
    status = db.Column(db.Unicode)
    insee_com = db.Column(db.Unicode)
    nom_com = db.Column(db.Unicode)
    insee_arr = db.Column(db.Unicode)
    nom_dep = db.Column(db.Unicode)
    insee_dep = db.Column(db.Unicode)
    nom_reg = db.Column(db.Unicode)
    insee_reg = db.Column(db.Unicode)
    code_epci = db.Column(db.Unicode)
    plani_precision = db.Column(db.Float)
    siren_code = db.Column(db.Unicode)
    canton = db.Column(db.Unicode)
    population = db.Column(db.Integer)
    multican = db.Column(db.Unicode)
    cc_nom = db.Column(db.Unicode)
    cc_siren = db.Column(db.BigInteger)
    cc_nature = db.Column(db.Unicode)
    cc_date_creation = db.Column(db.Unicode)
    cc_date_effet = db.Column(db.Unicode)
    insee_commune_nouvelle = db.Column(db.Unicode)
    meta_create_date = db.Column(db.DateTime)
    meta_update_date = db.Column(db.DateTime)

    @hybrid_property
    def nom_com_dept(self):
        return "{} ({})".format(self.nom_com, self.insee_dep)
