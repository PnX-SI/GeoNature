
# coding: utf8
from __future__ import (unicode_literals, print_function,
                        absolute_import, division)

from sqlalchemy import ForeignKey


from geonature.utils.env import DB
from ...utils.utilssqlalchemy import serializableModel


class LAreasWithoutGeom(serializableModel):
    __tablename__ = 'l_areas'
    __table_args__ = {'schema': 'ref_geo'}
    id_area = DB.Column(DB.Integer, primary_key=True)
    id_type = DB.Column(DB.Integer)
    area_name = DB.Column(DB.Unicode)
    area_code = DB.Column(DB.Unicode)
    source = DB.Column(DB.Unicode)


class BibAreasTypes(serializableModel):
    __tablename__ = 'bib_areas_types'
    __table_args__ = {'schema': 'ref_geo'}
    id_type = DB.Column(DB.Integer, primary_key=True)
    type_name = DB.Column(DB.Unicode)
    type_code = DB.Column(DB.Unicode)
    type_desc = DB.Column(DB.Unicode)
    ref_name = DB.Column(DB.Unicode)
    ref_version = DB.Column(DB.Integer)
    num_version = DB.Column(DB.Unicode)
