from datetime import datetime
from collections.abc import Mapping
import re
from packaging import version

from flask import g
import sqlalchemy as sa
from sqlalchemy import func, ForeignKey, Table
from sqlalchemy.orm import relationship, deferred, joinedload
from sqlalchemy.types import ARRAY
from sqlalchemy.dialects.postgresql import JSON
from sqlalchemy.ext.mutable import MutableDict
from sqlalchemy.orm import column_property
from jsonschema.exceptions import ValidationError as JSONValidationError
from jsonschema import validate as validate_json
from celery.result import AsyncResult
import flask_sqlalchemy

if version.parse(flask_sqlalchemy.__version__) >= version.parse("3"):
    from flask_sqlalchemy.query import Query
else:  # retro-compatibility Flask-SQLAlchemy 2
    from flask_sqlalchemy import BaseQuery as Query

from utils_flask_sqla.serializers import serializable

from geonature.utils.env import db
from geonature.utils.celery import celery_app
from geonature.core.gn_permissions.tools import get_scopes_by_action
from geonature.core.gn_commons.models import TModules
from geonature.core.gn_meta.models import TDatasets
from pypnnomenclature.models import BibNomenclaturesTypes
from pypnusershub.db.models import User


class ImportModule(TModules):
    __mapper_args__ = {
        "polymorphic_identity": "import",
    }

    def generate_input_url_for_dataset(self, dataset):
        return f"/import/process/upload?datasetId={dataset.id_dataset}"

    generate_input_url_for_dataset.label = "Importer des données"
    generate_input_url_for_dataset.object_code = "IMPORT"

    def generate_module_url_for_source(self, source):
        id_import = re.search(r"^Import\(id=(?P<id>\d+)\)$", source.name_source).group("id")
        return f"/import/{id_import}/report"


"""
Erreurs
=======

ImportErrorType = un type d’erreur, avec sa description
ImportErrorType.category = la catégorie auquelle est rattaché ce type d’erreur
  ex: le type d’erreur « date invalide » est rattaché à la catégorie « erreur de format »
  note: c’est un champs texte libre, il n’y a pas de modèle ImportErrorCategory
ImportError = occurance d’un genre d’erreur, associé à une ou plusieurs ligne d’un import précis
"""


@serializable
class ImportUserErrorType(db.Model):
    __tablename__ = "bib_errors_types"
    __table_args__ = {"schema": "gn_imports"}

    pk = db.Column("id_error", db.Integer, primary_key=True)
    category = db.Column("error_type", db.Unicode, nullable=False)
    name = db.Column(db.Unicode, nullable=False, unique=True)
    description = db.Column(db.Unicode)
    level = db.Column("error_level", db.Unicode)

    def __str__(self):
        return f"<ImportErrorType {self.name}>"


@serializable
class ImportUserError(db.Model):
    __tablename__ = "t_user_errors"
    __table_args__ = {"schema": "gn_imports"}

    pk = db.Column("id_user_error", db.Integer, primary_key=True)
    id_import = db.Column(
        db.Integer,
        db.ForeignKey("gn_imports.t_imports.id_import", onupdate="CASCADE", ondelete="CASCADE"),
    )
    imprt = db.relationship("TImports", back_populates="errors")
    id_type = db.Column(
        "id_error",
        db.Integer,
        db.ForeignKey(ImportUserErrorType.pk, onupdate="CASCADE", ondelete="CASCADE"),
    )
    type = db.relationship("ImportUserErrorType")
    column = db.Column("column_error", db.Unicode)
    rows = db.Column("id_rows", db.ARRAY(db.Integer))
    comment = db.Column(db.UnicodeText)

    def __str__(self):
        return f"<ImportError import={self.id_import},type={self.type.name},rows={self.rows}>"


class Destination(db.Model):
    __tablename__ = "bib_destinations"
    __table_args__ = {"schema": "gn_imports"}

    id_destination = db.Column(db.Integer, primary_key=True, autoincrement=True)
    id_module = db.Column(db.Integer, ForeignKey(TModules.id_module), nullable=True)
    code = db.Column(db.String(64), unique=True)
    label = db.Column(db.String(128))
    table_name = db.Column(db.String(64))

    module = relationship(TModules)
    entities = relationship("Entity", back_populates="destination")

    def get_transient_table(self):
        return Table(
            self.table_name,
            db.metadata,
            autoload=True,
            autoload_with=db.session.connection(),
            schema="gn_imports",
        )

    @property
    def validity_columns(self):
        return [entity.validity_column for entity in self.entities]

    @property
    def preprocess_transient_data(self):
        if "preprocess_transient_data" in self.module._imports_:
            return self.module._imports_["preprocess_transient_data"]
        else:
            return lambda *args, **kwargs: None

    @property
    def check_transient_data(self):
        return self.module._imports_["check_transient_data"]

    @property
    def import_data_to_destination(self):
        return self.module._imports_["import_data_to_destination"]

    @property
    def remove_data_from_destination(self):
        return self.module._imports_["remove_data_from_destination"]


@serializable
class BibThemes(db.Model):
    __tablename__ = "bib_themes"
    __table_args__ = {"schema": "gn_imports"}

    id_theme = db.Column(db.Integer, primary_key=True)
    name_theme = db.Column(db.Unicode, nullable=False)
    fr_label_theme = db.Column(db.Unicode, nullable=False)
    eng_label_theme = db.Column(db.Unicode, nullable=True)
    desc_theme = db.Column(db.Unicode, nullable=True)
    order_theme = db.Column(db.Integer, nullable=False)


@serializable
class EntityField(db.Model):
    __tablename__ = "cor_entity_field"
    __table_args__ = {"schema": "gn_imports"}

    id_entity = db.Column(
        db.Integer, db.ForeignKey("gn_imports.bib_entities.id_entity"), primary_key=True
    )
    entity = relationship("Entity", back_populates="fields")
    id_field = db.Column(
        db.Integer, db.ForeignKey("gn_imports.bib_fields.id_field"), primary_key=True
    )
    field = relationship("BibFields", back_populates="entities")

    desc_field = db.Column(db.Unicode, nullable=True)
    id_theme = db.Column(db.Integer, db.ForeignKey(BibThemes.id_theme), nullable=False)
    theme = relationship(BibThemes)
    order_field = db.Column(db.Integer, nullable=False)
    comment = db.Column(db.Unicode)


@serializable
class Entity(db.Model):
    __tablename__ = "bib_entities"
    __table_args__ = {"schema": "gn_imports"}

    id_entity = db.Column(db.Integer, primary_key=True, autoincrement=True)
    id_destination = db.Column(db.Integer, ForeignKey(Destination.id_destination))
    destination = relationship(Destination, back_populates="entities")
    code = db.Column(db.String(16))
    label = db.Column(db.String(64))
    order = db.Column(db.Integer)
    validity_column = db.Column(db.String(64))
    destination_table_schema = db.Column(db.String(63))
    destination_table_name = db.Column(db.String(63))

    fields = relationship("EntityField", back_populates="entity")

    def get_destination_table(self):
        return Table(
            self.destination_table_name,
            db.metadata,
            autoload=True,
            autoload_with=db.session.connection(),
            schema=self.destination_table_schema,
        )


class InstancePermissionMixin:
    def get_instance_permissions(self, scopes, user=None):
        if user is None:
            user = g.current_user
        if isinstance(scopes, Mapping):
            return {
                key: self.has_instance_permission(scope, user=user) for key, scope in scopes.items()
            }
        else:
            return [self.has_instance_permission(scope, user=user) for scope in scopes]


cor_role_import = db.Table(
    "cor_role_import",
    db.Column("id_role", db.Integer, db.ForeignKey(User.id_role), primary_key=True),
    db.Column(
        "id_import",
        db.Integer,
        db.ForeignKey("gn_imports.t_imports.id_import"),
        primary_key=True,
    ),
    schema="gn_imports",
)


class ImportQuery(Query):
    def filter_by_scope(self, scope, user=None):
        if user is None:
            user = g.current_user
        if scope == 0:
            return self.filter(sa.false())
        elif scope in (1, 2):
            filters = [User.id_role == user.id_role]
            if scope == 2 and user.id_organisme is not None:
                filters += [User.id_organisme == user.id_organisme]
            return self.filter(TImports.authors.any(sa.or_(*filters)))
        elif scope == 3:
            return self
        else:
            raise Exception(f"Unexpected scope {scope}")


@serializable(fields=["authors.nom_complet", "dataset.dataset_name", "dataset.active"])
class TImports(InstancePermissionMixin, db.Model):
    __tablename__ = "t_imports"
    __table_args__ = {"schema": "gn_imports"}
    query_class = ImportQuery

    # https://docs.python.org/3/library/codecs.html
    # https://chardet.readthedocs.io/en/latest/supported-encodings.html
    # TODO: move in configuration file
    AVAILABLE_ENCODINGS = {
        "utf-8",
        "iso-8859-1",
        "iso-8859-15",
    }
    AVAILABLE_FORMATS = ["csv", "geojson"]
    AVAILABLE_SEPARATORS = [",", ";"]

    id_import = db.Column(db.Integer, primary_key=True, autoincrement=True)
    id_destination = db.Column(db.Integer, ForeignKey(Destination.id_destination))
    destination = relationship(Destination)
    format_source_file = db.Column(db.Unicode, nullable=True)
    srid = db.Column(db.Integer, nullable=True)
    separator = db.Column(db.Unicode, nullable=True)
    detected_separator = db.Column(db.Unicode, nullable=True)
    encoding = db.Column(db.Unicode, nullable=True)
    detected_encoding = db.Column(db.Unicode, nullable=True)
    # import_table = db.Column(db.Unicode, nullable=True)
    full_file_name = db.Column(db.Unicode, nullable=True)
    id_dataset = db.Column(db.Integer, ForeignKey("gn_meta.t_datasets.id_dataset"), nullable=True)
    date_create_import = db.Column(db.DateTime, default=datetime.now)
    date_update_import = db.Column(db.DateTime, default=datetime.now, onupdate=datetime.now)
    date_end_import = db.Column(db.DateTime, nullable=True)
    source_count = db.Column(db.Integer, nullable=True)
    erroneous_rows = deferred(db.Column(ARRAY(db.Integer), nullable=True))
    import_count = db.Column(db.Integer, nullable=True)
    statistics = db.Column(
        MutableDict.as_mutable(JSON), nullable=False, server_default="'{}'::jsonb"
    )
    date_min_data = db.Column(db.DateTime, nullable=True)
    date_max_data = db.Column(db.DateTime, nullable=True)
    uuid_autogenerated = db.Column(db.Boolean)
    altitude_autogenerated = db.Column(db.Boolean)
    authors = db.relationship(
        User,
        lazy="joined",
        secondary=cor_role_import,
    )
    loaded = db.Column(db.Boolean, nullable=False, default=False)
    processed = db.Column(db.Boolean, nullable=False, default=False)
    dataset = db.relationship(TDatasets, lazy="joined")
    source_file = deferred(db.Column(db.LargeBinary))
    columns = db.Column(ARRAY(db.Unicode))
    # keys are target names, values are source names
    fieldmapping = db.Column(MutableDict.as_mutable(JSON))
    contentmapping = db.Column(MutableDict.as_mutable(JSON))
    task_id = db.Column(sa.String(155))

    errors = db.relationship(
        "ImportUserError",
        back_populates="imprt",
        order_by="ImportUserError.id_type",  # TODO order by type.category
        cascade="all, delete-orphan",
    )

    @property
    def cruved(self):
        scopes_by_action = get_scopes_by_action(module_code="IMPORT", object_code="IMPORT")
        return {
            action: self.has_instance_permission(scope)
            for action, scope in scopes_by_action.items()
        }

    errors_count = column_property(func.array_length(erroneous_rows, 1))

    @property
    def task_progress(self):
        if self.task_id is None:
            return None
        result = AsyncResult(self.task_id, app=celery_app)
        if result.state in ["PENDING", "STARTED"]:
            return 0
        elif result.state == "PROGRESS":
            return result.result["progress"]
        elif result.state == "SUCCESS":
            return None
        else:
            return -1

    def has_instance_permission(self, scope, user=None):
        if user is None:
            user = g.current_user
        if scope == 0:  # pragma: no cover (should not happen as already checked by the decorator)
            return False
        elif scope == 1:  # self
            return user.id_role in [author.id_role for author in self.authors]
        elif scope == 2:  # organism
            return user.id_role in [author.id_role for author in self.authors] or (
                user.id_organisme is not None
                and user.id_organisme in [author.id_organisme for author in self.authors]
            )
        elif scope == 3:  # all
            return True

    def as_dict(self, import_as_dict):
        import_as_dict["authors_name"] = "; ".join([author.nom_complet for author in self.authors])
        if self.detected_encoding:
            import_as_dict["available_encodings"] = sorted(
                TImports.AVAILABLE_ENCODINGS
                | {
                    self.detected_encoding,
                }
            )
        else:
            import_as_dict["available_encodings"] = sorted(TImports.AVAILABLE_ENCODINGS)
        import_as_dict["available_formats"] = TImports.AVAILABLE_FORMATS
        import_as_dict["available_separators"] = TImports.AVAILABLE_SEPARATORS
        if self.full_file_name and "." in self.full_file_name:
            extension = self.full_file_name.rsplit(".", 1)[-1]
            if extension in TImports.AVAILABLE_FORMATS:
                import_as_dict["detected_format"] = extension
        return import_as_dict


@serializable
class BibFields(db.Model):
    __tablename__ = "bib_fields"
    __table_args__ = {"schema": "gn_imports"}

    id_field = db.Column(db.Integer, primary_key=True)
    id_destination = db.Column(db.Integer, ForeignKey(Destination.id_destination))
    destination = relationship(Destination)
    name_field = db.Column(db.Unicode, nullable=False, unique=True)
    source_field = db.Column(db.Unicode, unique=True)
    dest_field = db.Column(db.Unicode, unique=True)
    fr_label = db.Column(db.Unicode, nullable=False)
    eng_label = db.Column(db.Unicode, nullable=True)
    type_field = db.Column(db.Unicode, nullable=True)
    mandatory = db.Column(db.Boolean, nullable=False)
    autogenerated = db.Column(db.Boolean, nullable=False)
    mnemonique = db.Column(db.Unicode, db.ForeignKey(BibNomenclaturesTypes.mnemonique))
    nomenclature_type = relationship("BibNomenclaturesTypes")
    display = db.Column(db.Boolean, nullable=False)
    multi = db.Column(db.Boolean)

    entities = relationship("EntityField", back_populates="field")

    @property
    def source_column(self):
        return self.source_field if self.source_field else self.dest_field

    @property
    def dest_column(self):
        return self.dest_field if self.dest_field else self.source_field

    def __str__(self):
        return self.fr_label


class MappingQuery(Query):
    def filter_by_scope(self, scope, user=None):
        if user is None:
            user = g.current_user
        if scope == 0:
            return self.filter(sa.false())
        elif scope in (1, 2):
            filters = [
                MappingTemplate.public == True,
                MappingTemplate.owners.any(id_role=user.id_role),
            ]
            if scope == 2 and user.id_organisme is not None:
                filters.append(MappingTemplate.owners.any(id_organisme=user.id_organisme))
            return self.filter(sa.or_(*filters)).distinct()
        elif scope == 3:
            return self
        else:
            raise Exception(f"Unexpected scope {scope}")


cor_role_mapping = db.Table(
    "cor_role_mapping",
    db.Column("id_role", db.Integer, db.ForeignKey(User.id_role), primary_key=True),
    db.Column(
        "id_mapping",
        db.Integer,
        db.ForeignKey("gn_imports.t_mappings.id"),
        primary_key=True,
    ),
    schema="gn_imports",
)


class MappingTemplate(db.Model):
    __tablename__ = "t_mappings"
    __table_args__ = {"schema": "gn_imports"}

    query_class = MappingQuery

    id = db.Column(db.Integer, primary_key=True)
    id_destination = db.Column(db.Integer, ForeignKey(Destination.id_destination))
    destination = relationship(Destination)
    label = db.Column(db.Unicode(255), nullable=False)
    type = db.Column(db.Unicode(10), nullable=False)
    active = db.Column(db.Boolean, nullable=False, default=True, server_default="true")
    public = db.Column(db.Boolean, nullable=False, default=False, server_default="false")

    @property
    def cruved(self):
        scopes_by_action = get_scopes_by_action(module_code="IMPORT", object_code="MAPPING")
        return {
            action: self.has_instance_permission(scope)
            for action, scope in scopes_by_action.items()
        }

    __mapper_args__ = {
        "polymorphic_on": type,
    }

    owners = relationship(
        User,
        lazy="joined",
        secondary=cor_role_mapping,
    )

    def has_instance_permission(self, scope: int, user=None):
        if user is None:
            user = g.current_user
        if scope == 0:
            return False
        elif scope in (1, 2):
            return user in self.owners or (
                scope == 2
                and user.id_organisme is not None
                and user.id_organisme in [owner.id_organisme for owner in self.owners]
            )
        elif scope == 3:
            return True


@serializable
class FieldMapping(MappingTemplate):
    __tablename__ = "t_fieldmappings"
    __table_args__ = {"schema": "gn_imports"}

    id = db.Column(db.Integer, ForeignKey(MappingTemplate.id), primary_key=True)
    values = db.Column(MutableDict.as_mutable(JSON))

    __mapper_args__ = {
        "polymorphic_identity": "FIELD",
    }

    @staticmethod
    def validate_values(values):
        fields = (
            BibFields.query.filter_by(destination=g.destination, display=True)
            .with_entities(
                BibFields.name_field,
                BibFields.autogenerated,
                BibFields.mandatory,
                BibFields.multi,
            )
            .all()
        )
        schema = {
            "type": "object",
            "properties": {
                field.name_field: {
                    "type": "boolean"
                    if field.autogenerated
                    else ("array" if field.multi else "string"),
                }
                for field in fields
            },
            "required": [field.name_field for field in fields if field.mandatory],
            "additionalProperties": False,
        }
        try:
            validate_json(values, schema)
        except JSONValidationError as e:
            raise ValueError(e.message)


@serializable
class ContentMapping(MappingTemplate):
    __tablename__ = "t_contentmappings"
    __table_args__ = {"schema": "gn_imports"}

    id = db.Column(db.Integer, ForeignKey(MappingTemplate.id), primary_key=True)
    values = db.Column(MutableDict.as_mutable(JSON))

    __mapper_args__ = {
        "polymorphic_identity": "CONTENT",
    }

    @staticmethod
    def validate_values(values):
        nomenclature_fields = (
            BibFields.query.filter(
                BibFields.destination == g.destination, BibFields.nomenclature_type != None
            )
            .options(
                joinedload(BibFields.nomenclature_type).joinedload(
                    BibNomenclaturesTypes.nomenclatures
                ),
            )
            .all()
        )
        properties = {}
        for nomenclature_field in nomenclature_fields:
            cd_nomenclatures = [
                nomenclature.cd_nomenclature
                for nomenclature in nomenclature_field.nomenclature_type.nomenclatures
            ]
            properties[nomenclature_field.mnemonique] = {
                "type": "object",
                "patternProperties": {
                    "^.*$": {
                        "type": "string",
                        "enum": cd_nomenclatures,
                    },
                },
            }
        schema = {
            "type": "object",
            "properties": properties,
            "additionalProperties": False,
        }
        try:
            validate_json(values, schema)
        except JSONValidationError as e:
            raise ValueError(e.message)
