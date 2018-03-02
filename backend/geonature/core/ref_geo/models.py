
from geonature.utils.env import DB
from geonature.utils.utilssqlalchemy import serializable


@serializable
class LAreasWithoutGeom(DB.Model):
    __tablename__ = 'l_areas'
    __table_args__ = {'schema': 'ref_geo'}
    id_area = DB.Column(DB.Integer, primary_key=True)
    id_type = DB.Column(DB.Integer)
    area_name = DB.Column(DB.Unicode)
    area_code = DB.Column(DB.Unicode)
    source = DB.Column(DB.Unicode)


@serializable
class BibAreasTypes(DB.Model):
    __tablename__ = 'bib_areas_types'
    __table_args__ = {'schema': 'ref_geo'}
    id_type = DB.Column(DB.Integer, primary_key=True)
    type_name = DB.Column(DB.Unicode)
    type_code = DB.Column(DB.Unicode)
    type_desc = DB.Column(DB.Unicode)
    ref_name = DB.Column(DB.Unicode)
    ref_version = DB.Column(DB.Integer)
    num_version = DB.Column(DB.Unicode)
