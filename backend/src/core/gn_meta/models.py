
# coding: utf8
from __future__ import (unicode_literals, print_function,
                        absolute_import, division)

from flask_sqlalchemy import SQLAlchemy
from sqlalchemy import ForeignKey
from sqlalchemy.orm import relationship
from ...utils.utilssqlalchemy import serializableModel

from ..users.models import BibOrganismes


#from pypnnomenclature.models import TNomenclatures

db = SQLAlchemy()


class TProgrammes(serializableModel):
    __tablename__ = 't_programmes'
    __table_args__ = {'schema':'gn_meta'}
    id_programme = db.Column(db.Integer, primary_key=True)
    programme_name = db.Column(db.Unicode)
    programme_desc = db.Column(db.Unicode)
    active = db.Column(db.Boolean)
    

    datasets = relationship("TDatasets", lazy='joined')

    def get_programmes(self, recursif=False):
        return self.as_dict(recursif)
   

class TDatasets(serializableModel):
    __tablename__ = 't_datasets'
    __table_args__ = {'schema':'gn_meta'}
    id_dataset = db.Column(db.Integer, primary_key=True)
    id_programme = db.Column(db.Integer, ForeignKey('gn_meta.t_programmes.id_programme'))
    dataset_name = db.Column(db.Unicode)
    dataset_desc = db.Column(db.Unicode)
    id_organisme_owner = db.Column(db.Integer, ForeignKey('utilisateurs.bib_organismes.id_organisme'))
    id_organisme_producer = db.Column(db.Integer, ForeignKey('utilisateurs.bib_organismes.id_organisme'))
    id_organisme_administrator = db.Column(db.Integer, ForeignKey('utilisateurs.bib_organismes.id_organisme'))
    id_organisme_funder = db.Column(db.Integer, ForeignKey('utilisateurs.bib_organismes.id_organisme'))
    public_data = db.Column(db.Boolean)
    default_validity = db.Column(db.Boolean)
    meta_create_date = db.Column(db.DateTime)
    meta_update_date = db.Column(db.DateTime)

    owner = relationship("BibOrganismes", foreign_keys=[id_organisme_owner])
    producer = relationship("BibOrganismes", foreign_keys=[id_organisme_producer])