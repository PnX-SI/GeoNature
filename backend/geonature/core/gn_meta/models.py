from sqlalchemy import ForeignKey, or_
from sqlalchemy.sql import select, func
from sqlalchemy.orm import relationship, exc
from sqlalchemy.dialects.postgresql import UUID

from werkzeug.exceptions import NotFound

from pypnnomenclature.models import TNomenclatures

from geonature.utils.utilssqlalchemy import serializable
from geonature.utils.env import DB


@serializable
class CorAcquisitionFrameworkActor(DB.Model):
    __tablename__ = 'cor_acquisition_framework_actor'
    __table_args__ = {'schema': 'gn_meta'}
    id_cafa = DB.Column(DB.Integer, primary_key=True)
    id_acquisition_framework = DB.Column(
        DB.Integer,
        ForeignKey('gn_meta.t_acquisition_frameworks.id_acquisition_framework'))
    id_role = DB.Column(DB.Integer)
    id_organism = DB.Column(DB.Integer)
    id_nomenclature_actor_role = DB.Column(DB.Integer)


@serializable
class CorDatasetsActor(DB.Model):
    __tablename__ = 'cor_dataset_actor'
    __table_args__ = {'schema': 'gn_meta'}
    id_cda = DB.Column(DB.Integer, primary_key=True)
    id_dataset = DB.Column(
        DB.Integer,
        ForeignKey('gn_meta.t_datasets.id_dataset')
    )
    id_role = DB.Column(DB.Integer)
    id_organism = DB.Column(DB.Integer)
    id_nomenclature_actor_role = DB.Column(DB.Integer)


@serializable
class TDatasets(DB.Model):
    __tablename__ = 't_datasets'
    __table_args__ = {'schema': 'gn_meta'}
    id_dataset = DB.Column(DB.Integer, primary_key=True)
    unique_dataset_id = DB.Column(
        UUID(as_uuid=True),
        default=select([func.uuid_generate_v4()]))
    id_acquisition_framework = DB.Column(
        DB.Integer,
        ForeignKey('gn_meta.t_acquisition_frameworks.id_acquisition_framework')
    )
    dataset_name = DB.Column(DB.Unicode)
    dataset_shortname = DB.Column(DB.Unicode)
    dataset_desc = DB.Column(DB.Unicode)
    id_nomenclature_data_type = DB.Column(
        DB.Integer,
        default=TNomenclatures.get_default_nomenclature(103)
    )
    keywords = DB.Column(DB.Unicode)
    marine_domain = DB.Column(DB.Boolean)
    terrestrial_domain = DB.Column(DB.Boolean)
    id_nomenclature_dataset_objectif = DB.Column(
        DB.Integer,
        default=TNomenclatures.get_default_nomenclature(114)
    )
    bbox_west = DB.Column(DB.Unicode)
    bbox_east = DB.Column(DB.Unicode)
    bbox_south = DB.Column(DB.Unicode)
    bbox_north = DB.Column(DB.Unicode)
    id_nomenclature_collecting_method = DB.Column(
        DB.Integer,
        default=TNomenclatures.get_default_nomenclature(115)
    )
    id_nomenclature_data_origin = DB.Column(
        DB.Integer,
        default=TNomenclatures.get_default_nomenclature(2)
    )
    id_nomenclature_source_status = DB.Column(
        DB.Integer,
        default=TNomenclatures.get_default_nomenclature(19)
    )
    id_nomenclature_resource_type = DB.Column(
        DB.Integer,
        default=TNomenclatures.get_default_nomenclature(102)
    )
    default_validity = DB.Column(DB.Boolean)
    meta_create_date = DB.Column(DB.DateTime)
    meta_update_date = DB.Column(DB.DateTime)

    cor_datasets_actor = relationship(
        "CorDatasetsActor",
        lazy='joined',
        cascade="save-update, delete, delete-orphan"
    )

    @staticmethod
    def get_id(uuid_dataset):
        id_dataset = DB.session.query(
            TDatasets.id_dataset
        ).filter(
            TDatasets.unique_dataset_id == uuid_dataset
        ).first()
        if id_dataset:
            return id_dataset[0]
        return id_dataset


    @staticmethod
    def get_uuid(id_dataset):
        uuid_dataset = DB.session.query(
            TDatasets.unique_dataset_id
        ).filter(
            TDatasets.id_dataset == id_dataset
        ).first()
        if uuid_dataset:
            return uuid_dataset[0]
        return uuid_dataset


    @staticmethod
    def get_user_datasets(user):
        """get the dataset(s) where the user is actor
            param: user from TRole model
            return: a list of id_dataset """
        q = DB.session.query(
            CorDatasetsActor,
            CorDatasetsActor.id_dataset
        )
        if user.id_organisme is None:
            q = q.filter(
                CorDatasetsActor.id_role == user.id_role
            )
        else:
            q = q.filter(
                or_(
                    CorDatasetsActor.id_organism == user.id_organisme,
                    CorDatasetsActor.id_role == user.id_role
                )
            )
        return [d.id_dataset for d in q.all()]


@serializable
class TAcquisitionFramework(DB.Model):
    __tablename__ = 't_acquisition_frameworks'
    __table_args__ = {'schema': 'gn_meta'}
    id_acquisition_framework = DB.Column(DB.Integer, primary_key=True)
    unique_acquisition_framework_id = DB.Column(
        UUID(as_uuid=True),
        default=select([func.uuid_generate_v4()]))
    acquisition_framework_name = DB.Column(DB.Unicode)
    acquisition_framework_desc = DB.Column(DB.Unicode)
    id_nomenclature_territorial_level = DB.Column(DB.Integer)
    territory_desc = DB.Column(DB.Unicode)
    keywords = DB.Column(DB.Unicode)
    id_nomenclature_financing_type = DB.Column(DB.Integer)
    target_description = DB.Column(DB.Unicode)
    ecologic_or_geologic_target = DB.Column(DB.Unicode)
    acquisition_framework_parent_id = DB.Column(DB.Integer)
    is_parent = DB.Column(DB.Integer)
    acquisition_framework_start_date = DB.Column(DB.DateTime)
    acquisition_framework_end_date = DB.Column(DB.DateTime)

    meta_create_date = DB.Column(DB.DateTime)
    meta_update_date = DB.Column(DB.DateTime)

    cor_af_actor = relationship(
        "CorAcquisitionFrameworkActor",
        lazy='joined',
        cascade="save-update, delete, delete-orphan"
    )

    @staticmethod
    def get_id(uuid_af):
        """
            return the acquisition framework's id
            from its UUID if exist or None
        """
        a_f = DB.session.query(
            TAcquisitionFramework.id_acquisition_framework
        ).filter(
            TAcquisitionFramework.unique_acquisition_framework_id == uuid_af
        ).first()
        return a_f


@serializable
class TParameters(DB.Model):
    __tablename__ = 't_parameters'
    __table_args__ = {'schema': 'gn_meta'}
    id_parameter = DB.Column(DB.Integer, primary_key=True)
    id_organism = DB.Column(
        DB.Integer,
        ForeignKey('utilisateurs.bib_organismes.id_organisme')
    )
    parameter_name = DB.Column(DB.Unicode)
    parameter_desc = DB.Column(DB.Unicode)
    parameter_value = DB.Column(DB.Unicode)
    parameter_extra_value = DB.Column(DB.Unicode)
