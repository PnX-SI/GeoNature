
# coding: utf8
from __future__ import (unicode_literals, print_function,
                        absolute_import, division)

from flask_sqlalchemy import SQLAlchemy
from sqlalchemy import ForeignKey
from ...utils.utilssqlalchemy import serializableModel

db = SQLAlchemy()


class LMunicipalities(serializableModel):
    __tablename__ = 'l_municipalities'
    __table_args__ = {'schema':'ref_geo'}
    id_municipality = db.Column(db.Unicode, primary_key=True)
    municipality_name = db.Column(db.Unicode)
