"""
Modèles du schéma gn_commons
"""

import os
from typing import Any, Optional
from datetime import datetime
from pathlib import Path
from collections import defaultdict

from flask import current_app
from sqlalchemy import (
    TIMESTAMP,
    Boolean,
    Column,
    DateTime,
    ForeignKey,
    Integer,
    String,
    Table,
    Unicode,
    false,
    text,
)
from sqlalchemy.orm import relationship, aliased, Mapped, mapped_column
from sqlalchemy.sql import select, func
from sqlalchemy.dialects.postgresql import UUID
from geoalchemy2 import Geometry
from sqlalchemy.schema import FetchedValue
from pypnnomenclature.models import TNomenclatures
from pypnusershub.db.models import User
from utils_flask_sqla.serializers import serializable
from utils_flask_sqla_geo.serializers import geoserializable

from geonature.utils.env import DB


@serializable
class BibTablesLocation(DB.Model):
    __tablename__ = "bib_tables_location"
    __table_args__ = {"schema": "gn_commons"}
    id_table_location: Mapped[int] = mapped_column(Integer, primary_key=True)
    table_desc: Mapped[Optional[str]] = mapped_column(Unicode)
    schema_name: Mapped[str] = mapped_column(Unicode)
    table_name: Mapped[str] = mapped_column(Unicode)
    pk_field: Mapped[str] = mapped_column(Unicode)
    uuid_field_name: Mapped[str] = mapped_column(Unicode)


cor_module_dataset = Table(
    "cor_module_dataset",
    DB.metadata,
    Column(
        "id_module",
        Integer,
        ForeignKey("gn_commons.t_modules.id_module"),
        primary_key=True,
    ),
    Column(
        "id_dataset",
        Integer,
        ForeignKey("gn_meta.t_datasets.id_dataset"),
        primary_key=True,
    ),
    schema="gn_commons",
)


@serializable
class CorModuleDataset(DB.Model):
    __tablename__ = "cor_module_dataset"
    __table_args__ = {"schema": "gn_commons", "extend_existing": True}
    id_module: Mapped[int] = mapped_column(
        Integer,
        ForeignKey("gn_commons.t_modules.id_module"),
        primary_key=True,
    )
    id_dataset: Mapped[int] = mapped_column(
        Integer,
        ForeignKey("gn_meta.t_datasets.id_dataset"),
        primary_key=True,
    )


# see https://docs.sqlalchemy.org/en/14/orm/basic_relationships.html#late-evaluation-of-relationship-arguments
def _resolve_import_cor_object_module():
    from geonature.core.gn_permissions.models import cor_object_module

    return cor_object_module


@serializable
class TModules(DB.Model):
    __tablename__ = "t_modules"
    __table_args__ = {"schema": "gn_commons"}

    class base_defaultdict(defaultdict):
        """
        Avoid polymorphic error when polymorphic identities are declared
        in database but absent from venv: fallback on base identity.
        Taken from CTFd.
        """

        def __missing__(self, key):
            return self["base"]

    type: Mapped[str] = mapped_column(Unicode, server_default="base")
    __mapper_args__ = {
        "polymorphic_on": "type",
        "polymorphic_identity": "base",
        "_polymorphic_map": base_defaultdict(),
    }

    id_module: Mapped[int] = mapped_column(Integer, primary_key=True)
    module_code: Mapped[str] = mapped_column(Unicode)
    module_label: Mapped[str] = mapped_column(Unicode)
    module_picto: Mapped[Optional[str]] = mapped_column(Unicode)
    module_desc: Mapped[Optional[str]] = mapped_column(Unicode)
    module_group: Mapped[Optional[str]] = mapped_column(Unicode)
    module_path: Mapped[Optional[str]] = mapped_column(Unicode)
    module_external_url: Mapped[Optional[str]] = mapped_column(Unicode)
    module_target: Mapped[Optional[str]] = mapped_column(Unicode)
    module_comment: Mapped[Optional[str]] = mapped_column(Unicode)
    active_frontend: Mapped[bool] = mapped_column(Boolean)
    active_backend: Mapped[bool] = mapped_column(Boolean)
    module_doc_url: Mapped[Optional[str]] = mapped_column(Unicode)
    module_order: Mapped[Optional[int]] = mapped_column(Integer)
    ng_module: Mapped[Optional[str]] = mapped_column(Unicode(length=500))
    meta_create_date: Mapped[Optional[datetime]] = mapped_column(DateTime)
    meta_update_date: Mapped[Optional[datetime]] = mapped_column(DateTime)
    support_additional_fields: Mapped[Optional[bool]] = mapped_column(
        Boolean, server_default=false()
    )

    objects = DB.relationship(
        "PermObject", secondary=lambda: _resolve_import_cor_object_module(), backref="modules"
    )
    # relationship datasets add via backref

    def __str__(self):
        return self.module_label.capitalize()


@serializable(exclude=["base_dir"])
class TMedias(DB.Model):
    __tablename__ = "t_medias"
    __table_args__ = {"schema": "gn_commons"}
    id_media: Mapped[int] = mapped_column(Integer, primary_key=True)
    id_nomenclature_media_type: Mapped[int] = mapped_column(
        Integer, ForeignKey("ref_nomenclatures.t_nomenclatures.id_nomenclature")
    )
    id_table_location: Mapped[int] = mapped_column(
        Integer, ForeignKey("gn_commons.bib_tables_location.id_table_location")
    )
    unique_id_media: Mapped[Any] = mapped_column(
        UUID(as_uuid=True), default=select(func.uuid_generate_v4())
    )
    uuid_attached_row: Mapped[Optional[Any]] = mapped_column(UUID(as_uuid=True))
    title_fr: Mapped[Optional[str]] = mapped_column(Unicode)
    title_en: Mapped[Optional[str]] = mapped_column(Unicode)
    title_it: Mapped[Optional[str]] = mapped_column(Unicode)
    title_es: Mapped[Optional[str]] = mapped_column(Unicode)
    title_de: Mapped[Optional[str]] = mapped_column(Unicode)
    media_url: Mapped[Optional[str]] = mapped_column(Unicode)
    media_path: Mapped[Optional[str]] = mapped_column(Unicode)
    author: Mapped[Optional[str]] = mapped_column(Unicode)
    description_fr: Mapped[Optional[str]] = mapped_column(Unicode)
    description_en: Mapped[Optional[str]] = mapped_column(Unicode)
    description_it: Mapped[Optional[str]] = mapped_column(Unicode)
    description_es: Mapped[Optional[str]] = mapped_column(Unicode)
    description_de: Mapped[Optional[str]] = mapped_column(Unicode)
    is_public: Mapped[bool] = mapped_column(Boolean, default=True)
    meta_create_date: Mapped[Optional[datetime]] = mapped_column(DateTime)
    meta_update_date: Mapped[Optional[datetime]] = mapped_column(DateTime)

    @staticmethod
    def base_dir():
        return Path(current_app.config["MEDIA_FOLDER"]) / "attachments"

    def __before_commit_delete__(self):
        # déclenché sur un DELETE : on supprime le fichier
        if self.media_path and (self.base_dir() / self.media_path).exists():
            # delete file
            self.remove_file()
            # delete thumbnail
            self.remove_thumbnails()

    def remove_file(self, move=True):
        if not self.media_path:
            return
        path = self.base_dir() / self.media_path
        if move:
            new_path = path.parent / f"deleted_{path.name}"
            path.rename(new_path)
            self.media_path = str(new_path.relative_to(self.base_dir()))
        else:
            path.unlink()

    def remove_thumbnails(self):
        # delete thumbnail test sur nom des fichiers avec id dans le dossier thumbnail
        dir_thumbnail = os.path.join(
            str(self.base_dir()),
            "thumbnails",
            str(self.id_table_location),
        )
        if not os.path.isdir(dir_thumbnail):
            return
        for f in os.listdir(dir_thumbnail):
            if f.split("_")[0] == str(self.id_media):
                abs_path = os.path.join(dir_thumbnail, f)
                os.path.exists(abs_path) and os.remove(abs_path)


@serializable
class TParameters(DB.Model):
    __tablename__ = "t_parameters"
    __table_args__ = {"schema": "gn_commons"}
    id_parameter: Mapped[int] = mapped_column(Integer, primary_key=True)
    id_organism: Mapped[Optional[int]] = mapped_column(
        Integer, ForeignKey("utilisateurs.bib_organismes.id_organisme")
    )
    parameter_name: Mapped[str] = mapped_column(Unicode)
    parameter_desc: Mapped[Optional[str]] = mapped_column(Unicode)
    parameter_value: Mapped[str] = mapped_column(Unicode)
    parameter_extra_value: Mapped[Optional[str]] = mapped_column(Unicode)


@serializable
class TValidations(DB.Model):
    __tablename__ = "t_validations"
    __table_args__ = {"schema": "gn_commons"}

    id_validation: Mapped[int] = mapped_column(Integer, primary_key=True)
    uuid_attached_row: Mapped[Any] = mapped_column(
        UUID(as_uuid=True), ForeignKey("gn_synthese.synthese.unique_id_sinp")
    )
    id_nomenclature_valid_status: Mapped[Optional[int]] = mapped_column(
        Integer,
        ForeignKey(TNomenclatures.id_nomenclature),
    )
    nomenclature_valid_status = relationship(
        TNomenclatures,
        foreign_keys=[id_nomenclature_valid_status],
        lazy="joined",  # FIXME: remove and manually join when needed
    )
    id_validator: Mapped[Optional[int]] = mapped_column(Integer, ForeignKey(User.id_role))
    validator_role = DB.relationship(User)
    validation_auto: Mapped[bool] = mapped_column(Boolean)
    validation_comment: Mapped[Optional[str]] = mapped_column(Unicode)
    validation_date: Mapped[Optional[datetime]] = mapped_column(
        TIMESTAMP, server_default=FetchedValue()
    )
    # FIXME: remove and use nomenclature_valid_status
    validation_label = DB.relationship(
        TNomenclatures,
        foreign_keys=[id_nomenclature_valid_status],
        overlaps="nomenclature_valid_status",  # overlaps expected
    )

    @staticmethod
    def auto_validation(fct_auto_validation):
        stmt = text(f"""
            select routine_name, routine_schema 
            from information_schema.routines 
            where routine_name= '{fct_auto_validation}'
            and routine_type='FUNCTION';
         """)
        result = DB.session.execute(stmt).fetchall()
        if not result:
            return
        stmt_auto_validation = text(f"SELECT gn_profiles.{fct_auto_validation}()")
        DB.session.execute(stmt_auto_validation)
        DB.session.commit()


last_validation_query = (
    select(TValidations)
    .order_by(TValidations.validation_date.desc())
    .limit(1)
    .alias("last_validation")
)
last_validation = aliased(TValidations, last_validation_query)


@serializable
@geoserializable
class VLatestValidations(DB.Model):
    __tablename__ = "v_latest_validation"
    __table_args__ = {"schema": "gn_commons"}
    id_validation: Mapped[int] = mapped_column(Integer, primary_key=True)
    uuid_attached_row: Mapped[Optional[Any]] = mapped_column(UUID(as_uuid=True))
    id_nomenclature_valid_status: Mapped[Optional[int]] = mapped_column(Integer)
    id_validator: Mapped[Optional[int]] = mapped_column(Integer)
    validation_comment: Mapped[Optional[str]] = mapped_column(Unicode)
    validation_date: Mapped[Optional[datetime]] = mapped_column(DateTime)


@serializable
class THistoryActions(DB.Model):
    __tablename__ = "t_history_actions"
    __table_args__ = {"schema": "gn_commons"}

    id_history_action: Mapped[int] = mapped_column(Integer, primary_key=True)
    id_table_location: Mapped[int] = mapped_column(Integer)
    uuid_attached_row: Mapped[Any] = mapped_column(UUID(as_uuid=True))
    operation_type: Mapped[Optional[str]] = mapped_column(Unicode)
    operation_date: Mapped[Optional[datetime]] = mapped_column(DateTime)
    table_content: Mapped[Optional[str]] = mapped_column(Unicode)


@serializable
class TMobileApps(DB.Model):
    __tablename__ = "t_mobile_apps"
    __table_args__ = {"schema": "gn_commons"}
    id_mobile_app: Mapped[int] = mapped_column(Integer, primary_key=True)
    app_code: Mapped[Optional[str]] = mapped_column(Unicode)
    relative_path_apk: Mapped[Optional[str]] = mapped_column(Unicode)
    url_apk: Mapped[Optional[str]] = mapped_column(Unicode)
    url_settings: Mapped[Optional[str]] = mapped_column(Unicode)
    package: Mapped[Optional[str]] = mapped_column(Unicode)
    version_code: Mapped[Optional[str]] = mapped_column(Unicode)


@serializable
@geoserializable(geoCol="place_geom", idCol="id_place")
class TPlaces(DB.Model):
    __tablename__ = "t_places"
    __table_args__ = {"schema": "gn_commons"}
    id_place: Mapped[int] = mapped_column(Integer, primary_key=True)
    id_role: Mapped[int] = mapped_column(Integer, ForeignKey("utilisateurs.t_roles.id_role"))
    role = relationship(User)
    place_name: Mapped[Optional[str]] = mapped_column(String)
    place_geom: Mapped[Optional[Any]] = mapped_column(Geometry("GEOMETRY", 4326))


@serializable
class BibWidgets(DB.Model):
    __tablename__ = "bib_widgets"
    __table_args__ = {"schema": "gn_commons"}
    id_widget: Mapped[int] = mapped_column(Integer, primary_key=True)
    widget_name: Mapped[str] = mapped_column(String)

    def __str__(self):
        return self.widget_name.capitalize()


cor_field_object = Table(
    "cor_field_object",
    DB.metadata,
    Column("id_field", Integer, ForeignKey("gn_commons.t_additional_fields.id_field")),
    Column("id_object", Integer, ForeignKey("gn_permissions.t_objects.id_object")),
    schema="gn_commons",
)

cor_field_module = Table(
    "cor_field_module",
    DB.metadata,
    Column("id_field", Integer, ForeignKey("gn_commons.t_additional_fields.id_field")),
    Column("id_module", Integer, ForeignKey("gn_commons.t_modules.id_module")),
    schema="gn_commons",
)

cor_field_dataset = Table(
    "cor_field_dataset",
    DB.metadata,
    Column("id_field", Integer, ForeignKey("gn_commons.t_additional_fields.id_field")),
    Column("id_dataset", Integer, ForeignKey("gn_meta.t_datasets.id_dataset")),
    schema="gn_commons",
)
