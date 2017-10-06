
# coding: utf8
from __future__ import (unicode_literals, print_function,
                        absolute_import, division)

from flask_sqlalchemy import SQLAlchemy
from sqlalchemy import ForeignKey
from ...utils.utilssqlalchemy import serializableModel

db = SQLAlchemy()

class LAreasWithoutGeom(serializableModel):
    __tablename__ = 'l_areas'
    __table_args__ = {'schema':'ref_geo'}
    id_area = db.Column(db.Integer, primary_key=True)
    id_type = db.Column(db.Integer)
    area_name = db.Column(db.Unicode)
    area_code = db.Column(db.Unicode)
    source = db.Column(db.Unicode)

class BibAreasTypes(serializableModel):
    __tablename__ = 'bib_areas_types'
    __table_args__ = {'schema':'ref_geo'}
    id_type = db.Column(db.Integer, primary_key=True)
    type_name = db.Column(db.Unicode)
    type_code = db.Column(db.Unicode)
    type_desc = db.Column(db.Unicode)
    ref_name = db.Column(db.Unicode)
    ref_version = db.Column(db.Integer)
    num_version = db.Column(db.Unicode)
