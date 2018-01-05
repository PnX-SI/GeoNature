
# coding: utf8
from __future__ import (unicode_literals, print_function,
                        absolute_import, division)

from flask_sqlalchemy import SQLAlchemy
from sqlalchemy import ForeignKey, UniqueConstraint
from sqlalchemy.sql import select, func
from sqlalchemy.orm import relationship
from ...utils.utilssqlalchemy import serializableModel
from pypnnomenclature.models import TNomenclatures


from sqlalchemy.dialects.postgresql import UUID

from ..users.models import BibOrganismes



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

class TAcquisitionFramework(serializableModel):
    __tablename__ = 't_acquisition_frameworks'
    __table_args__ = {'schema': 'gn_meta'}
    id_acquisition_framework = db.Column(db.Integer, primary_key=True)
    unique_acquisition_framework_id = db.Column(
        UUID(as_uuid=True),
        default=select([func.uuid_generate_v4()]))
    acquisition_framework_name = db.Column(db.Unicode)
    acquisition_framework_desc = db.Column(db.Unicode)
    id_nomenclature_territorial_level = db.Column(db.Integer)
    territory_desc = db.Column(db.Unicode)
    keywords = db.Column(db.Unicode)
    id_nomenclature_financing_type = db.Column(db.Integer)
    target_description = db.Column(db.Unicode)
    ecologic_or_geologic_target = db.Column(db.Unicode)
    acquisition_framework_parent_id = db.Column(db.Integer)
    is_parent = db.Column(db.Integer)
    acquisition_framework_start_date = db.Column(db.DateTime)
    acquisition_framework_end_date = db.Column(db.DateTime)

    meta_create_date = db.Column(db.DateTime)
    meta_update_date = db.Column(db.DateTime)

    @staticmethod
    def get_id(uuid_af):
        """return the acquisition framework's id from its UUID if exist or None"""
        af = db.session.query(TAcquisitionFramework.id_acquisition_framework
            ).filter(TAcquisitionFramework.unique_acquisition_framework_id == uuid_af
            ).first()
        return af

class CorAcquisitionFrameworkActor(serializableModel):
    __tablename__ = 'cor_acquisition_framework_actor'
    __table_args__ = {'schema': 'gn_meta'}
    id_acquisition_framework = db.Column(db.Integer, primary_key=True)
    id_actor = db.Column(db.Integer, primary_key=True)
    id_nomenclature_actor_role = db.Column(db.Integer, primary_key=True)


class TDatasets(serializableModel):
    __tablename__ = 't_datasets'
    __table_args__ = {'schema': 'gn_meta'}
    id_dataset = db.Column(db.Integer, primary_key=True)
    unique_dataset_id = db.Column(
        UUID(as_uuid=True),
        default=select([func.uuid_generate_v4()]))
    id_acquisition_framework = db.Column(
        db.Integer,
        ForeignKey('gn_meta.t_acquisition_frameworks.id_acquisition_framework')
    )
    dataset_name = db.Column(db.Unicode)
    dataset_shortname = db.Column(db.Unicode)
    dataset_desc = db.Column(db.Unicode)
    id_nomenclature_data_type = db.Column(
        db.Integer,
        default = TNomenclatures.get_default_nomenclature(103)
        )
    keywords = db.Column(db.Unicode)
    marine_domain = db.Column(db.Boolean)
    terrestrial_domain = db.Column(db.Boolean)
    id_nomenclature_dataset_objectif = db.Column(
        db.Integer,
        default = TNomenclatures.get_default_nomenclature(114)
        )
    bbox_west = db.Column(db.Unicode)
    bbox_east = db.Column(db.Unicode)
    bbox_south = db.Column(db.Unicode)
    bbox_north = db.Column(db.Unicode)
    id_nomenclature_collecting_method = db.Column(
        db.Integer,
        default = TNomenclatures.get_default_nomenclature(115)
        )
    id_nomenclature_data_origin = db.Column(
        db.Integer,
        default = TNomenclatures.get_default_nomenclature(2)
    )
    id_nomenclature_source_status = db.Column(
        db.Integer,
        default = TNomenclatures.get_default_nomenclature(19))
    id_nomenclature_resource_type = db.Column(
        db.Integer,
        default = TNomenclatures.get_default_nomenclature(102))
    id_program = db.Column(db.Integer,
        ForeignKey('gn_meta.t_programs.id_program'))
    default_validity = db.Column(db.Boolean)
    meta_create_date = db.Column(db.DateTime)
    meta_update_date = db.Column(db.DateTime)


    cor_datasets_actor = relationship(
        "CorDatasetsActor",
        lazy='joined',
        cascade="save-update, delete, delete-orphan"
    )


    @staticmethod
    def get_id(uuid_dataset):
        """Check if a dataset exist from its UIID
        return boolean """
        id_dataset = db.session.query(TDatasets.id_dataset
            ).filter(TDatasets.unique_dataset_id == uuid_dataset
            ).first()
        return id_dataset
        


class CorDatasetsActor(serializableModel):
    __tablename__ = 'cor_dataset_actor'
    __table_args__ = {'schema': 'gn_meta'}
    id_cda = db.Column(db.Integer, primary_key=True)
    id_dataset = db.Column(
        db.Integer,
        ForeignKey('gn_meta.t_datasets.id_dataset'))
    id_role = db.Column(db.Integer)
    id_organism = db.Column(db.Integer)
    id_nomenclature_actor_role = db.Column(db.Integer)



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
        
