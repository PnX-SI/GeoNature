
# coding: utf8
from __future__ import (unicode_literals, print_function,
                        absolute_import, division)

from flask_sqlalchemy import SQLAlchemy
from sqlalchemy import ForeignKey
from sqlalchemy.orm import relationship
from ..utils.utilssqlalchemy import serializableModel, serializableGeoModel

from pypnnomenclature.models import TNomenclatures

from geoalchemy2 import Geometry

db = SQLAlchemy()


class TRelevesContact(serializableGeoModel, db.Model):
    __tablename__ = 't_releves_contact'
    __table_args__ = {'schema':'pr_contact'}
    id_releve_contact = db.Column(db.Integer, primary_key=True)
    id_dataset = db.Column(db.Integer)
    id_nomenclature_obs_technique = db.Column(db.Integer)
    id_digitiser = db.Column(db.Integer)
    date_min = db.Column(db.DateTime)
    date_max = db.Column(db.DateTime)
    altitude_min = db.Column(db.Integer)
    altitude_max = db.Column(db.Integer)
    meta_device_entry = db.Column(db.Unicode)
    deleted = db.Column(db.Boolean)
    meta_create_date = db.Column(db.DateTime)
    meta_update_date = db.Column(db.DateTime)
    comment = db.Column(db.Unicode)
    geom_local = db.Column(Geometry)
    geom_4326 = db.Column(Geometry)


    occurrences = relationship("TOccurrencesContact", lazy='joined')

    def get_geofeature(self):
        return self.as_geofeature('geom_4326', 'id_releve_contact')


class TOccurrencesContact(serializableModel, db.Model):
    __tablename__ = 't_occurrences_contact'
    __table_args__ = {'schema':'pr_contact'}
    id_occurrence_contact = db.Column(db.Integer, primary_key=True)
    id_releve_contact = db.Column(db.Integer, ForeignKey('pr_contact.t_releves_contact.id_releve_contact'))
    id_nomenclature_obs_meth = db.Column(db.Integer)
