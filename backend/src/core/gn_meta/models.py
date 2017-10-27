
# coding: utf8
from __future__ import (unicode_literals, print_function,
                        absolute_import, division)

from flask_sqlalchemy import SQLAlchemy
from sqlalchemy import ForeignKey
from sqlalchemy.orm import relationship
from ...utils.utilssqlalchemy import serializableModel

from ..users.models import BibOrganismes


# from pypnnomenclature.models import TNomenclatures

db = SQLAlchemy()


class TPrograms(serializableModel):
    __tablename__ = 't_programs'
    __table_args__ = {'schema': 'gn_meta'}
    id_program = db.Column(db.Integer, primary_key=True)
    program_name = db.Column(db.Unicode)
    program_desc = db.Column(db.Unicode)
    active = db.Column(db.Boolean)

    datasets = relationship("TDatasets", lazy='joined')

    def get_programs(self, recursif=False):
        return self.as_dict(recursif)


class TDatasets(serializableModel):
    __tablename__ = 't_datasets'
    __table_args__ = {'schema': 'gn_meta'}
    id_dataset = db.Column(db.Integer, primary_key=True)
    id_program = db.Column(
        db.Integer,
        ForeignKey('gn_meta.t_programs.id_program')
    )
    dataset_name = db.Column(db.Unicode)
    dataset_desc = db.Column(db.Unicode)
    id_organism_owner = db.Column(
        db.Integer,
        ForeignKey('utilisateurs.bib_organismes.id_organisme')
    )
    id_organism_producer = db.Column(
        db.Integer,
        ForeignKey('utilisateurs.bib_organismes.id_organisme')
    )
    id_organism_administrator = db.Column(
        db.Integer,
        ForeignKey('utilisateurs.bib_organismes.id_organisme')
    )
    id_organism_funder = db.Column(
        db.Integer,
        ForeignKey('utilisateurs.bib_organismes.id_organisme')
    )
    public_data = db.Column(db.Boolean)
    default_validity = db.Column(db.Boolean)
    meta_create_date = db.Column(db.DateTime)
    meta_update_date = db.Column(db.DateTime)

    organism_producer = relationship(
        "BibOrganismes",
        foreign_keys=[id_organism_producer]
    )
    organism_owner = relationship(
        "BibOrganismes",
        foreign_keys=[id_organism_owner]
    )
    organism_administrator = relationship(
        "BibOrganismes",
        foreign_keys=[id_organism_administrator]
    )
    organism_funder = relationship(
        "BibOrganismes",
        foreign_keys=[id_organism_funder]
    )


class TParameters(serializableModel):
    __tablename__ = 't_parameters'
    __table_args__ = {'schema': 'gn_meta'}
    id_parameter = db.Column(db.Integer, primary_key=True)
    id_organism = db.Column(
        db.Integer,
        ForeignKey('utilisateurs.bib_organismes.id_organisme')
    )
    parameter_name = db.Column(db.Unicode)
    parameter_desc = db.Column(db.Unicode)
    parameter_value = db.Column(db.Unicode)
    parameter_extra_value = db.Column(db.Unicode)
