"""
    Modèles du schéma gn_commons
"""

import os
from pathlib import Path
from collections import defaultdict

from flask import current_app
from sqlalchemy import ForeignKey, text
from sqlalchemy.orm import relationship, aliased
from sqlalchemy.sql import select, func
from sqlalchemy.dialects.postgresql import UUID
from geoalchemy2 import Geometry

from pypnnomenclature.models import TNomenclatures
from pypnusershub.db.models import User
from utils_flask_sqla.serializers import serializable
from utils_flask_sqla_geo.serializers import geoserializable

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


cor_module_dataset = DB.Table(
    "cor_module_dataset",
    DB.Column(
        "id_module",
        DB.Integer,
        ForeignKey("gn_commons.t_modules.id_module"),
        primary_key=True,
    ),
    DB.Column(
        "id_dataset",
        DB.Integer,
        ForeignKey("gn_meta.t_datasets.id_dataset"),
        primary_key=True,
    ),
    schema="gn_commons",
)


@serializable
class CorModuleDataset(DB.Model):
    __tablename__ = "cor_module_dataset"
    __table_args__ = {"schema": "gn_commons", "extend_existing": True}
    id_module = DB.Column(
        DB.Integer,
        ForeignKey("gn_commons.t_modules.id_module"),
        primary_key=True,
    )
    id_dataset = DB.Column(
        DB.Integer,
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

    type = DB.Column(DB.Unicode, nullable=False, server_default="base")
    __mapper_args__ = {
        "polymorphic_on": "type",
        "polymorphic_identity": "base",
        "_polymorphic_map": base_defaultdict(),
    }

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
    module_order = DB.Column(DB.Integer)
    ng_module = DB.Column(DB.Unicode(length=500))
    meta_create_date = DB.Column(DB.DateTime)
    meta_update_date = DB.Column(DB.DateTime)

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
    id_media = DB.Column(DB.Integer, primary_key=True)
    id_nomenclature_media_type = DB.Column(
        DB.Integer, ForeignKey("ref_nomenclatures.t_nomenclatures.id_nomenclature")
    )
    id_table_location = DB.Column(
        DB.Integer, ForeignKey("gn_commons.bib_tables_location.id_table_location")
    )
    unique_id_media = DB.Column(UUID(as_uuid=True), default=select(func.uuid_generate_v4()))
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
    meta_create_date = DB.Column(DB.DateTime)
    meta_update_date = DB.Column(DB.DateTime)

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
    id_parameter = DB.Column(DB.Integer, primary_key=True)
    id_organism = DB.Column(DB.Integer, ForeignKey("utilisateurs.bib_organismes.id_organisme"))
    parameter_name = DB.Column(DB.Unicode)
    parameter_desc = DB.Column(DB.Unicode)
    parameter_value = DB.Column(DB.Unicode)
    parameter_extra_value = DB.Column(DB.Unicode)


@serializable
class TValidations(DB.Model):
    __tablename__ = "t_validations"
    __table_args__ = {"schema": "gn_commons"}

    id_validation = DB.Column(DB.Integer, primary_key=True)
    uuid_attached_row = DB.Column(
        UUID(as_uuid=True), ForeignKey("gn_synthese.synthese.unique_id_sinp")
    )
    id_nomenclature_valid_status = DB.Column(
        DB.Integer,
        ForeignKey(TNomenclatures.id_nomenclature),
    )
    nomenclature_valid_status = relationship(
        TNomenclatures,
        foreign_keys=[id_nomenclature_valid_status],
        lazy="joined",  # FIXME: remove and manually join when needed
    )
    id_validator = DB.Column(DB.Integer, ForeignKey(User.id_role))
    validator_role = DB.relationship(User)
    validation_auto = DB.Column(DB.Boolean)
    validation_comment = DB.Column(DB.Unicode)
    validation_date = DB.Column(DB.TIMESTAMP)
    validation_auto = DB.Column(DB.Boolean)
    # FIXME: remove and use nomenclature_valid_status
    validation_label = DB.relationship(
        TNomenclatures,
        foreign_keys=[id_nomenclature_valid_status],
        overlaps="nomenclature_valid_status",  # overlaps expected
    )

    @staticmethod
    def auto_validation(fct_auto_validation):
        stmt = text(
            f"""
            select routine_name, routine_schema 
            from information_schema.routines 
            where routine_name= '{fct_auto_validation}'
            and routine_type='FUNCTION';
         """
        )
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
    id_validation = DB.Column(DB.Integer, primary_key=True)
    uuid_attached_row = DB.Column(UUID(as_uuid=True))
    id_nomenclature_valid_status = DB.Column(DB.Integer)
    id_validator = DB.Column(DB.Integer)
    validation_comment = DB.Column(DB.Unicode)
    validation_date = DB.Column(DB.DateTime)


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


@serializable
class TMobileApps(DB.Model):
    __tablename__ = "t_mobile_apps"
    __table_args__ = {"schema": "gn_commons"}
    id_mobile_app = DB.Column(DB.Integer, primary_key=True)
    app_code = DB.Column(DB.Unicode)
    relative_path_apk = DB.Column(DB.Unicode)
    url_apk = DB.Column(DB.Unicode)
    url_settings = DB.Column(DB.Unicode)
    package = DB.Column(DB.Unicode)
    version_code = DB.Column(DB.Unicode)


@serializable
@geoserializable(geoCol="place_geom", idCol="id_place")
class TPlaces(DB.Model):
    __tablename__ = "t_places"
    __table_args__ = {"schema": "gn_commons"}
    id_place = DB.Column(DB.Integer, primary_key=True)
    id_role = DB.Column(DB.Integer, ForeignKey("utilisateurs.t_roles.id_role"))
    role = relationship(User)
    place_name = DB.Column(DB.String)
    place_geom = DB.Column(Geometry("GEOMETRY", 4326))


@serializable
class BibWidgets(DB.Model):
    __tablename__ = "bib_widgets"
    __table_args__ = {"schema": "gn_commons"}
    id_widget = DB.Column(DB.Integer, primary_key=True)
    widget_name = DB.Column(DB.String, nullable=False)

    def __str__(self):
        return self.widget_name.capitalize()


cor_field_object = DB.Table(
    "cor_field_object",
    DB.Column("id_field", DB.Integer, DB.ForeignKey("gn_commons.t_additional_fields.id_field")),
    DB.Column("id_object", DB.Integer, DB.ForeignKey("gn_permissions.t_objects.id_object")),
    schema="gn_commons",
)

cor_field_module = DB.Table(
    "cor_field_module",
    DB.Column("id_field", DB.Integer, DB.ForeignKey("gn_commons.t_additional_fields.id_field")),
    DB.Column("id_module", DB.Integer, DB.ForeignKey("gn_commons.t_modules.id_module")),
    schema="gn_commons",
)

cor_field_dataset = DB.Table(
    "cor_field_dataset",
    DB.Column("id_field", DB.Integer, DB.ForeignKey("gn_commons.t_additional_fields.id_field")),
    DB.Column("id_dataset", DB.Integer, DB.ForeignKey("gn_meta.t_datasets.id_dataset")),
    schema="gn_commons",
)
