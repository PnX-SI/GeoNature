from datetime import datetime

from geoalchemy2 import Geometry
from sqlalchemy import ForeignKey

from utils_flask_sqla.serializers import serializable
from utils_flask_sqla_geo.serializers import geoserializable

from geonature.utils.env import DB
from geonature.utils.config import config

from sqlalchemy.ext.hybrid import hybrid_property

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

@geoserializable
class LAreas(DB.Model):
    __tablename__ = "l_areas"
    __table_args__ = {"schema": "ref_geo"}
    id_area = DB.Column(DB.Integer, primary_key=True)
    id_type = DB.Column(DB.Integer, ForeignKey("ref_geo.bib_areas_types.id_type"))
    area_name = DB.Column(DB.Unicode)
    area_code = DB.Column(DB.Unicode)
    geom = DB.Column(Geometry("GEOMETRY", config["LOCAL_SRID"]))
    source = DB.Column(DB.Unicode)
    enable = DB.Column(DB.Boolean, nullable=False, default=True)
    meta_create_date = DB.Column(DB.DateTime, default=datetime.now)
    meta_update_date = DB.Column(DB.DateTime, default=datetime.now, onupdate=datetime.now)
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

    @hybrid_property
    def nom_com_dept(self):
        return '{} ({})'.format(self.nom_com, self.insee_dep)