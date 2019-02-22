"""
    Modèles du schéma gn_commons
"""

from sqlalchemy import ForeignKey
from sqlalchemy.sql import select, func
from sqlalchemy.dialects.postgresql import UUID

from pypnnomenclature.models import TNomenclatures
from pypnusershub.db.models import User

from geonature.utils.utilssqlalchemy import serializable
from geonature.utils.env import DB


@serializable
class BibTablesLocation(DB.Model):
    __tablename__ = "bib_tables_location"
    __table_args__ = {"schema": "gn_commons"}
    id_table_location = DB.Column(DB.Integer, primary_key=True)
    table_desc = DB.Column(DB.Unicode)
    schema_name = DB.Column(DB.Unicode)
    table_name = DB.Column(DB.Unicode)
    pk_field = DB.Column(DB.Unicode)
    uuid_field_name = DB.Column(DB.Unicode)


@serializable
class TModules(DB.Model):
    __tablename__ = "t_modules"
    __table_args__ = {"schema": "gn_commons"}
    id_module = DB.Column(DB.Integer, primary_key=True)
    module_code = DB.Column(DB.Unicode)
    module_label = DB.Column(DB.Unicode)
    module_picto = DB.Column(DB.Unicode)
    module_desc = DB.Column(DB.Unicode)
    module_group = DB.Column(DB.Unicode)
    module_path = DB.Column(DB.Unicode)
    module_external_url = DB.Column(DB.Unicode)
    module_target = DB.Column(DB.Unicode)
    module_comment = DB.Column(DB.Unicode)
    active_frontend = DB.Column(DB.Boolean)
    active_backend = DB.Column(DB.Boolean)
    module_doc_url = DB.Column(DB.Unicode)


@serializable
class TMedias(DB.Model):
    __tablename__ = "t_medias"
    __table_args__ = {"schema": "gn_commons"}
    id_media = DB.Column(DB.Integer, primary_key=True)
    id_nomenclature_media_type = DB.Column(
        DB.Integer
        # ,
        # ForeignKey('ref_nomenclatures.t_nomenclatures.id_nomenclature')
    )
    id_table_location = DB.Column(
        DB.Integer, ForeignKey("gn_commons.bib_tables_location.id_table_location")
    )
    unique_id_media = DB.Column(
        UUID(as_uuid=True), default=select([func.uuid_generate_v4()])
    )
    uuid_attached_row = DB.Column(UUID(as_uuid=True))
    title_fr = DB.Column(DB.Unicode)
    title_en = DB.Column(DB.Unicode)
    title_it = DB.Column(DB.Unicode)
    title_es = DB.Column(DB.Unicode)
    title_de = DB.Column(DB.Unicode)
    media_url = DB.Column(DB.Unicode)
    media_path = DB.Column(DB.Unicode)
    author = DB.Column(DB.Unicode)
    description_fr = DB.Column(DB.Unicode)
    description_en = DB.Column(DB.Unicode)
    description_it = DB.Column(DB.Unicode)
    description_es = DB.Column(DB.Unicode)
    description_de = DB.Column(DB.Unicode)
    is_public = DB.Column(DB.Boolean, default=True)


@serializable
class TParameters(DB.Model):
    __tablename__ = "t_parameters"
    __table_args__ = {"schema": "gn_commons"}
    id_parameter = DB.Column(DB.Integer, primary_key=True)
    id_organism = DB.Column(
        DB.Integer, ForeignKey("utilisateurs.bib_organismes.id_organisme")
    )
    parameter_name = DB.Column(DB.Unicode)
    parameter_desc = DB.Column(DB.Unicode)
    parameter_value = DB.Column(DB.Unicode)
    parameter_extra_value = DB.Column(DB.Unicode)


@serializable
class VLastestValidation(DB.Model):
    __tablename__ = "v_lastest_validation"
    __table_args__ = {"schema": "gn_commons"}

    id_validation = DB.Column(DB.Integer, primary_key=True)
    id_table_location = DB.Column(DB.Integer)
    uuid_attached_row = DB.Column(UUID(as_uuid=True))
    id_nomenclature_valid_status = DB.Column(DB.Integer)
    id_validator = DB.Column(DB.Integer)
    validation_comment = DB.Column(DB.Unicode)
    validation_date = DB.Column(DB.DateTime)
    validation_auto = DB.Column(DB.Boolean)
    label_default = DB.Column(DB.Unicode)

@serializable
class TValidations(DB.Model):
    __tablename__ = "t_validations"
    __table_args__ = {"schema": "gn_commons", "extend_existing":True}

    id_validation = DB.Column(DB.Integer, primary_key=True)
    id_table_location = DB.Column(DB.Integer)
    uuid_attached_row = DB.Column(UUID(as_uuid=True))
    id_nomenclature_valid_status = DB.Column(DB.Integer)
    id_validator = DB.Column(DB.Integer)
    validation_auto = DB.Column(DB.Boolean)
    validation_comment = DB.Column(DB.Unicode)
    validation_date = DB.Column(DB.DateTime)
    validation_auto = DB.Column(DB.Boolean)
    validation_label = DB.relationship(
        TNomenclatures,
        primaryjoin=(TNomenclatures.id_nomenclature == id_nomenclature_valid_status),
        foreign_keys=[id_nomenclature_valid_status]
    )
    validator_role = DB.relationship(
        User,
        primaryjoin=(User.id_role == id_validator),
        foreign_keys=[id_validator]
    )



@serializable
class THistoryActions(DB.Model):
    __tablename__ = "t_history_actions"
    __table_args__ = {"schema": "gn_commons"}

    id_history_action = DB.Column(DB.Integer, primary_key=True)
    id_table_location = DB.Column(DB.Integer)
    uuid_attached_row = DB.Column(UUID(as_uuid=True))
    operation_type = DB.Column(DB.Unicode)
    operation_date = DB.Column(DB.DateTime)
    table_content = DB.Column(DB.Unicode)
