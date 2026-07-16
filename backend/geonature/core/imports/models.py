from datetime import datetime
from collections.abc import Mapping
import re
from typing import Any, Iterable, List, Optional
from packaging import version

from flask import g
import sqlalchemy as sa
from sqlalchemy import func, ForeignKey, Table
from sqlalchemy.orm import relationship, deferred, joinedload, Mapped, mapped_column
from sqlalchemy.types import ARRAY
from sqlalchemy.dialects.postgresql import JSON
from sqlalchemy.ext.mutable import MutableDict
from sqlalchemy.orm import column_property
from jsonschema.exceptions import ValidationError as JSONValidationError
from jsonschema import validate as validate_json
from celery.result import AsyncResult
import flask_sqlalchemy
from werkzeug.exceptions import Conflict

if version.parse(flask_sqlalchemy.__version__) >= version.parse("3"):
    from flask_sqlalchemy.query import Query
else:  # retro-compatibility Flask-SQLAlchemy 2
    from flask_sqlalchemy import BaseQuery as Query

from utils_flask_sqla.models import qfilter
from utils_flask_sqla.serializers import serializable

from geonature.utils.env import db
from geonature.utils.celery import celery_app
from geonature.core.gn_permissions.tools import get_scopes_by_action
from geonature.core.gn_commons.models import TModules
from pypnnomenclature.models import BibNomenclaturesTypes
from pypnusershub.db.models import User
from sqlalchemy import select, exists
from geonature.core.gn_meta.models import TDatasets, TAcquisitionFramework


class ImportModule(TModules):
    __mapper_args__ = {
        "polymorphic_identity": "import",
    }

    def generate_module_url_for_source(self, source):
        id_import = re.search(r"^Import\(id=(?P<id>\d+)\)$", source.name_source).group("id")
        destination = db.session.scalars(
            db.select(Destination.code)
            .where(Destination.id_destination == TImports.id_destination)
            .where(TImports.id_import == id_import)
        ).one_or_none()
        return f"/import/{destination}/{id_import}/report"


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

    pk: Mapped[int] = mapped_column("id_error", db.Integer, primary_key=True)
    category: Mapped[str] = mapped_column("error_type", db.Unicode)
    name: Mapped[str] = mapped_column(db.Unicode, unique=True)
    description: Mapped[Optional[str]] = mapped_column(db.Unicode)
    level: Mapped[Optional[str]] = mapped_column("error_level", db.Unicode)

    def __str__(self):
        return f"<ImportErrorType {self.name}>"


@serializable
class ImportUserError(db.Model):
    __tablename__ = "t_user_errors"
    __table_args__ = {"schema": "gn_imports"}

    pk: Mapped[int] = mapped_column("id_user_error", db.Integer, primary_key=True)
    id_import: Mapped[Optional[int]] = mapped_column(
        db.Integer,
        db.ForeignKey("gn_imports.t_imports.id_import", onupdate="CASCADE", ondelete="CASCADE"),
    )
    imprt = db.relationship("TImports", back_populates="errors")
    id_type: Mapped[Optional[int]] = mapped_column(
        "id_error",
        db.Integer,
        db.ForeignKey(ImportUserErrorType.pk, onupdate="CASCADE", ondelete="CASCADE"),
    )
    type = db.relationship("ImportUserErrorType")
    column: Mapped[Optional[str]] = mapped_column("column_error", db.Unicode)
    rows: Mapped[Optional[Any]] = mapped_column("id_rows", db.ARRAY(db.Integer))
    comment: Mapped[Optional[str]] = mapped_column(db.UnicodeText)
    id_entity: Mapped[Optional[int]] = mapped_column(
        db.Integer,
        db.ForeignKey("gn_imports.bib_entities.id_entity", onupdate="CASCADE", ondelete="CASCADE"),
    )
    entity = db.relationship("Entity")

    def __str__(self):
        return f"<ImportError import={self.id_import},type={self.type.name},rows={self.rows}>"


@serializable
class Destination(db.Model):
    __tablename__ = "bib_destinations"
    __table_args__ = {"schema": "gn_imports"}

    id_destination: Mapped[int] = mapped_column(db.Integer, primary_key=True, autoincrement=True)
    id_module: Mapped[Optional[int]] = mapped_column(db.Integer, ForeignKey(TModules.id_module))
    code: Mapped[Optional[str]] = mapped_column(db.String(64), unique=True)
    label: Mapped[Optional[str]] = mapped_column(db.String(128))
    table_name: Mapped[Optional[str]] = mapped_column(db.String(64))
    active: Mapped[Optional[bool]] = mapped_column(sa.Boolean, server_default=sa.true())

    module = relationship(TModules, backref="destination")
    entities = relationship("Entity", back_populates="destination")

    def get_transient_table(self):
        return Table(
            self.table_name,
            db.metadata,
            autoload_replace=True,
            autoload_with=db.session.connection(),
            schema="gn_imports",
        )

    @property
    def validity_columns(self):
        return [entity.validity_column for entity in self.entities]

    @property
    def statistics_labels(self):
        return self.actions.statistics_labels()

    @property
    def actions(self):
        # TODO Find a proper way to type the return of the function
        # Imported here to avoid circular dependencies
        from geonature.core.imports.actions import ImportActions

        try:
            _actions: ImportActions = self.module.__import_actions__
            return _actions
        except AttributeError as exc:
            """
            This error is likely to occurs when you have some imports to a destination
            for which the corresponding module is missing in the venv.
            As a result, sqlalchemy fail to find the proper polymorphic identity,
            and fallback on TModules which does not have __import_actions__ property.
            """
            raise AttributeError(f"Is your module of type '{self.module.type}' installed?") from exc

    @staticmethod
    def allowed_destinations(
        user: Optional[User] = None, action_code: str = "C"
    ) -> List["Destination"]:
        """
        Return a list of allowed destinations for a given user and an action.

        Parameters
        ----------
        user : User, optional
            The user to filter destinations for. If not provided, the current_user is used.
        action : str
            The action to filter destinations for. Possible values are 'C', 'R', 'U', 'V', 'E', 'D'.

        Returns
        -------
        allowed_destination : List of Destination
            List of allowed destinations for the given user.
        """
        # If no user is provided, use the current user
        if not user:
            user = g.current_user

        # Retrieve all destinations
        all_destination = db.session.scalars(
            sa.select(Destination).where(Destination.active == True)
        ).all()
        return [dest for dest in all_destination if dest.has_instance_permission(user, action_code)]

    @qfilter
    def filter_by_role(cls, user: Optional[User] = None, action_code: str = "C", **kwargs):
        """
        Filter Destination by role.

        Parameters
        ----------
        user : User, optional
            The user to filter destinations for. If not provided, the current_user is used.

        Returns
        -------
        sqlalchemy.sql.elements.BinaryExpression
            A filter criterion for the ``id_destination`` column of the ``Destination`` table.
        """
        allowed_destination = Destination.allowed_destinations(user=user, action_code=action_code)
        return Destination.id_destination.in_(map(lambda x: x.id_destination, allowed_destination))

    def has_instance_permission(self, user: Optional[User] = None, action_code: str = "C"):
        """
        Check if a user has the permissions to do an action on this destination.

        Parameters
        ----------
        user : User, optional
            The user to check the permission for. If not provided, the current_user is used.
        action_code : str
            The action to check the permission for. Possible values are 'C', 'R', 'U', 'V', 'E', 'D'.

        Returns
        -------
        bool
            True if the user has the right to do the action on this destination, False otherwise.
        """
        if not user:
            user = g.current_user

        scopes = [0]
        for entity in self.entities:
            scopes.append(
                get_scopes_by_action(
                    id_role=user.id_role,
                    module_code=self.module.module_code,
                    object_code=entity.object.code_object,
                )[action_code]
            )
        max_scope = max(scopes)
        return max_scope > 0

    def __repr__(self):
        return self.label


@serializable
class BibThemes(db.Model):
    __tablename__ = "bib_themes"
    __table_args__ = {"schema": "gn_imports"}

    id_theme: Mapped[int] = mapped_column(db.Integer, primary_key=True)
    name_theme: Mapped[str] = mapped_column(db.Unicode)
    fr_label_theme: Mapped[str] = mapped_column(db.Unicode)
    eng_label_theme: Mapped[Optional[str]] = mapped_column(db.Unicode)
    desc_theme: Mapped[Optional[str]] = mapped_column(db.Unicode)
    order_theme: Mapped[int]


@serializable
class EntityField(db.Model):
    __tablename__ = "cor_entity_field"
    __table_args__ = {"schema": "gn_imports"}

    id_entity: Mapped[int] = mapped_column(
        db.Integer, db.ForeignKey("gn_imports.bib_entities.id_entity"), primary_key=True
    )
    entity = relationship("Entity", back_populates="fields")
    id_field: Mapped[int] = mapped_column(
        db.Integer, db.ForeignKey("gn_imports.bib_fields.id_field"), primary_key=True
    )
    field = relationship("BibFields", back_populates="entities")

    desc_field: Mapped[Optional[str]] = mapped_column(db.Unicode)
    id_theme: Mapped[int] = mapped_column(db.Integer, db.ForeignKey(BibThemes.id_theme))
    theme = relationship(BibThemes)
    order_field: Mapped[int]
    comment: Mapped[Optional[str]] = mapped_column(db.Unicode)


@serializable
class Entity(db.Model):
    __tablename__ = "bib_entities"
    __table_args__ = {"schema": "gn_imports"}

    id_entity: Mapped[int] = mapped_column(db.Integer, primary_key=True, autoincrement=True)
    id_destination: Mapped[Optional[int]] = mapped_column(
        db.Integer, ForeignKey(Destination.id_destination)
    )
    destination = relationship(Destination, back_populates="entities")
    code: Mapped[Optional[str]] = mapped_column(db.String(16))
    label: Mapped[Optional[str]] = mapped_column(db.String(64))
    order: Mapped[Optional[int]]
    validity_column: Mapped[Optional[str]] = mapped_column(db.String(64))
    destination_table_schema: Mapped[Optional[str]] = mapped_column(db.String(63))
    destination_table_name: Mapped[Optional[str]] = mapped_column(db.String(63))
    id_unique_column: Mapped[int] = mapped_column(
        db.Integer, db.ForeignKey("gn_imports.bib_fields.id_field"), primary_key=True
    )
    id_uuid_column: Mapped[int] = mapped_column(
        db.Integer, db.ForeignKey("gn_imports.bib_fields.id_field"), primary_key=True
    )
    id_parent: Mapped[Optional[int]] = mapped_column(
        db.Integer, ForeignKey("gn_imports.bib_entities.id_entity")
    )

    parent = relationship("Entity", back_populates="childs", remote_side=[id_entity])
    childs = relationship("Entity", back_populates="parent")
    fields = relationship("EntityField", back_populates="entity")
    unique_column = relationship("BibFields", foreign_keys=[id_unique_column])
    uuid_column = relationship("BibFields", foreign_keys=[id_uuid_column])
    id_object: Mapped[Optional[int]] = mapped_column(
        db.Integer, db.ForeignKey("gn_permissions.t_objects.id_object")
    )
    object = relationship("PermObject")

    def get_destination_table(self):
        return Table(
            self.destination_table_name,
            db.metadata,
            autoload=True,
            autoload_with=db.session.connection(),
            schema=self.destination_table_schema,
        )

    def __repr__(self):
        return f"{self.label}, {self.code}, {self.validity_column}"


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


@serializable(
    fields=[
        "authors.nom_complet",
        "destination.code",
        "destination.label",
        "destination.statistics_labels",
        "destination.module",
        "datasets.dataset.unique_dataset_id",
        "datasets.dataset.dataset_name",
    ]
)
class TImports(InstancePermissionMixin, db.Model):
    __tablename__ = "t_imports"
    __table_args__ = {"schema": "gn_imports"}
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

    id_import: Mapped[int] = mapped_column(db.Integer, primary_key=True, autoincrement=True)
    id_destination: Mapped[Optional[int]] = mapped_column(
        db.Integer, ForeignKey(Destination.id_destination)
    )
    destination = relationship(Destination)
    format_source_file: Mapped[Optional[str]] = mapped_column(db.Unicode)
    srid: Mapped[Optional[int]]
    separator: Mapped[Optional[str]] = mapped_column(db.Unicode)
    detected_separator: Mapped[Optional[str]] = mapped_column(db.Unicode)
    encoding: Mapped[Optional[str]] = mapped_column(db.Unicode)
    detected_encoding: Mapped[Optional[str]] = mapped_column(db.Unicode)
    # import_table = db.Column(db.Unicode, nullable=True)
    full_file_name: Mapped[Optional[str]] = mapped_column(db.Unicode)
    date_create_import: Mapped[Optional[datetime]] = mapped_column(
        db.DateTime, default=datetime.now
    )
    date_update_import: Mapped[Optional[datetime]] = mapped_column(
        db.DateTime, default=datetime.now, onupdate=datetime.now
    )
    date_end_import: Mapped[Optional[datetime]] = mapped_column(db.DateTime)
    source_count: Mapped[Optional[int]]
    erroneous_rows: Mapped[Optional[Any]] = deferred(mapped_column(ARRAY(db.Integer)))
    statistics: Mapped[Any] = mapped_column(
        MutableDict.as_mutable(JSON), server_default=sa.text("'{}'::jsonb")
    )
    date_min_data: Mapped[Optional[datetime]] = mapped_column(db.DateTime)
    date_max_data: Mapped[Optional[datetime]] = mapped_column(db.DateTime)
    uuid_autogenerated: Mapped[Optional[bool]]
    altitude_autogenerated: Mapped[Optional[bool]]
    authors = db.relationship(
        User,
        lazy="joined",
        secondary=cor_role_import,
    )
    loaded: Mapped[bool] = mapped_column(db.Boolean, default=False)
    processed: Mapped[bool] = mapped_column(db.Boolean, default=False)
    source_file: Mapped[Optional[Any]] = deferred(mapped_column(db.LargeBinary))
    columns: Mapped[Optional[Any]] = mapped_column(ARRAY(db.Unicode))
    # keys are target names, values are source names
    fieldmapping: Mapped[Optional[Any]] = mapped_column(MutableDict.as_mutable(JSON))
    contentmapping: Mapped[Optional[Any]] = mapped_column(MutableDict.as_mutable(JSON))
    observermapping: Mapped[Optional[Any]] = mapped_column(MutableDict.as_mutable(JSON))
    task_id: Mapped[Optional[str]] = mapped_column(sa.String(155))

    errors = db.relationship(
        "ImportUserError",
        back_populates="imprt",
        order_by="ImportUserError.id_type",  # TODO order by type.category
        cascade="all, delete-orphan",
    )
    datasets = db.relationship(
        "CorImportDataset",
        back_populates="imprt",
        cascade="all, delete-orphan",
        passive_deletes=True,
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

    @property
    def has_closed_af(self):
        """
        Check if one AF of the import has been closed.
        Returns
        -------

        """
        return db.session.scalar(
            select(
                exists().where(
                    CorImportDataset.id_import == self.id_import,
                    CorImportDataset.id_dataset == TDatasets.id_dataset,
                    TDatasets.id_acquisition_framework
                    == TAcquisitionFramework.id_acquisition_framework,
                    TAcquisitionFramework.opened.is_(False),
                )
            )
        )

    def raise_on_closed_af(self):
        if self.has_closed_af:
            raise Conflict(description="This import is linked to a closed acquisition framework.")

    def has_instance_permission(self, scope, user=None, action_code="C"):

        if user is None:
            user = g.current_user

        if not self.destination.has_instance_permission(user, action_code) and action_code != "R":
            return False

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

    @staticmethod
    def filter_by_scope(scope, user=None, **kwargs):
        if user is None:
            user = g.current_user
        if scope == 0:
            return sa.false()
        elif scope in (1, 2):
            filters = [User.id_role == user.id_role]
            if scope == 2 and user.id_organisme is not None:
                filters += [User.id_organisme == user.id_organisme]
            return TImports.authors.any(sa.or_(*filters))
        elif scope == 3:
            return sa.true()
        else:
            raise Exception(f"Unexpected scope {scope}")

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
class CorImportDataset(db.Model):
    __tablename__ = "cor_import_datasets"
    __table_args__ = {"schema": "gn_imports"}

    id_import = db.Column(
        db.Integer,
        db.ForeignKey("gn_imports.t_imports.id_import", ondelete="CASCADE"),
        primary_key=True,
        nullable=False,
    )
    id_dataset = db.Column(
        db.Integer,
        db.ForeignKey("gn_meta.t_datasets.id_dataset", ondelete="CASCADE"),
        primary_key=True,
        nullable=False,
    )

    imprt = db.relationship("TImports", back_populates="datasets")
    dataset = db.relationship("TDatasets")


@serializable
class BibFields(db.Model):
    __tablename__ = "bib_fields"
    __table_args__ = {"schema": "gn_imports"}

    id_field: Mapped[int] = mapped_column(db.Integer, primary_key=True)
    id_destination: Mapped[Optional[int]] = mapped_column(
        db.Integer, ForeignKey(Destination.id_destination)
    )
    destination = relationship(Destination)
    name_field: Mapped[str] = mapped_column(db.Unicode, unique=True)
    source_field: Mapped[Optional[str]] = mapped_column(db.Unicode, unique=True)
    dest_field: Mapped[Optional[str]] = mapped_column(db.Unicode, unique=True)
    fr_label: Mapped[str] = mapped_column(db.Unicode)
    eng_label: Mapped[Optional[str]] = mapped_column(db.Unicode)
    type_field: Mapped[Optional[str]] = mapped_column(db.Unicode)
    type_field_params: Mapped[Optional[Any]] = mapped_column(MutableDict.as_mutable(JSON))
    mandatory: Mapped[bool] = mapped_column(db.Boolean)
    autogenerated: Mapped[bool] = mapped_column(db.Boolean)
    mnemonique: Mapped[Optional[str]] = mapped_column(
        db.Unicode, db.ForeignKey(BibNomenclaturesTypes.mnemonique)
    )
    nomenclature_type = relationship("BibNomenclaturesTypes")
    display: Mapped[bool] = mapped_column(db.Boolean)
    multi: Mapped[Optional[bool]]
    optional_conditions: Mapped[Optional[Any]] = mapped_column(db.ARRAY(db.Unicode))
    mandatory_conditions: Mapped[Optional[Any]] = mapped_column(db.ARRAY(db.Unicode))

    entities = relationship("EntityField", back_populates="field")

    @property
    def source_column(self):
        return self.source_field if self.source_field else self.dest_field

    @property
    def dest_column(self):
        return self.dest_field if self.dest_field else self.source_field

    def __repr__(self):
        return f"{self.name_field}"


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

    id: Mapped[int] = mapped_column(db.Integer, primary_key=True)
    id_destination: Mapped[int] = mapped_column(db.Integer, ForeignKey(Destination.id_destination))
    destination = relationship(Destination)
    label: Mapped[str] = mapped_column(db.Unicode(255))
    type: Mapped[str] = mapped_column(db.Unicode(10))
    active: Mapped[bool] = mapped_column(db.Boolean, default=True, server_default="true")
    public: Mapped[bool] = mapped_column(db.Boolean, default=False, server_default="false")

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

    @staticmethod
    def filter_by_scope(scope, user=None):
        if user is None:
            user = g.current_user
        if scope == 0:
            return sa.false()
        elif scope in (1, 2):
            filters = [
                MappingTemplate.public == True,
                MappingTemplate.owners.any(id_role=user.id_role),
            ]
            if scope == 2 and user.id_organisme is not None:
                filters.append(MappingTemplate.owners.any(id_organisme=user.id_organisme))
            return sa.or_(*filters)
        elif scope == 3:
            return sa.true()
        else:
            raise Exception(f"Unexpected scope {scope}")


def optional_conditions_to_jsonschema(name_field: str, optional_conditions: Iterable[str]) -> dict:
    """
    Convert optional conditions into a JSON schema.

    Parameters
    ----------
    name_field : str
        The name of the field.
    optional_conditions : Iterable[str]
        The optional conditions.

    Returns
    -------
    dict
        The JSON schema.

    Notes
    -----
    The JSON schema is created to ensure that if any of the optional conditions is not provided,
    the name_field is required.
    """
    assert isinstance(optional_conditions, list)
    assert len(optional_conditions) > 0
    return {
        "anyOf": [
            {
                "if": {
                    "not": {
                        "properties": {
                            field_opt: {"type": "object"} for field_opt in optional_conditions
                        }
                    }
                },
                "then": {"required": [name_field]},
            }
        ]
    }


# TODO move to utils lib
def get_fields_of_an_entity(
    entity: "Entity",
    columns: Optional[List[str]] = None,
    optional_where_clause: Optional[Any] = None,
) -> List["BibFields"]:
    """
    Get all BibFields associated with a given entity.

    Parameters
    ----------
    entity : Entity
        The entity to get the fields for.
    columns : Optional[List[str]], optional
        The columns to retrieve. If None, all columns are retrieved.
    optional_where_clause : Optional[Any], optional
        An optional where clause to apply to the query.

    Returns
    -------
    List[BibFields]
        The BibFields associated with the given entity.
    """
    select_args = [BibFields]
    query = sa.select(BibFields).where(
        BibFields.entities.any(EntityField.entity == entity),
    )
    if columns:
        select_args = [getattr(BibFields, col) for col in columns]
        query.with_only_columns(*select_args)
    if optional_where_clause is not None:
        query = query.where(optional_where_clause)

    return db.session.scalars(query).all()


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
    def validate_values(field_mapping_json, destination=None):
        """
        Validate the field mapping values returned by the client form.

        Parameters
        ----------
        field_mapping_json : dict
            The field mapping values.

        Raises
        ------
        ValueError
            If the field mapping values are invalid.
        """
        bib_fields_col = [
            "name_field",
            "autogenerated",
            "mandatory",
            "multi",
            "optional_conditions",
            "mandatory_conditions",
        ]
        (g.destination if (destination is None) else destination)
        entities_for_destination: List[Entity] = (
            Entity.query.filter_by(
                destination=(g.destination if (destination is None) else destination)
            )
            .order_by(sa.desc(Entity.order))
            .all()
        )
        fields = []
        for entity in entities_for_destination:
            # Get fields associated to this entity and exists in the given field mapping
            fields_of_ent = get_fields_of_an_entity(
                entity,
                columns=bib_fields_col,
                optional_where_clause=sa.and_(
                    sa.or_(
                        ~BibFields.entities.any(EntityField.entity != entity),
                        BibFields.name_field == entity.unique_column.name_field,
                        BibFields.name_field.ilike("uuid%"),
                    ),
                    BibFields.name_field.in_(field_mapping_json.keys()),
                ),
            )
            # no field --> nothing to check. next entity !
            if not fields_of_ent:
                continue

            uuid_field = set([entity.uuid_column.name_field])
            uuid_parent = set([entity.parent.uuid_column.name_field]) if entity.parent else None
            id_fields = set([entity.unique_column.name_field])
            name_fields = set([f.name_field for f in fields_of_ent])
            # if the only column corresponds to id_columns, we only do the validation on the latter
            if id_fields == name_fields or uuid_field == name_fields or uuid_parent == name_fields:
                fields.extend(fields_of_ent)
            else:
                # if other columns than the id_columns are used, we need to check every fields of this entity
                fields.extend(
                    get_fields_of_an_entity(
                        entity,
                        columns=bib_fields_col,
                        optional_where_clause=sa.and_(
                            BibFields.destination
                            == (g.destination if (destination is None) else destination),
                            BibFields.display == True,
                        ),
                    )
                )

        schema = {
            "type": "object",
            "properties": {
                field.name_field: {
                    "type": "object",
                    "properties": {
                        "column_src": {
                            "type": ("array" if field.multi else "string"),
                        },
                        "constant_value": {
                            "oneOf": [
                                {"type": "boolean"},
                                {"type": "number"},
                                {"type": "string"},
                                {"type": "array"},
                                {"type": "object"},
                            ]
                        },
                    },
                    "required": [],
                    "additionalProperties": False,
                    "oneOf": [{"required": ["column_src"]}, {"required": ["constant_value"]}],
                }
                for field in fields
            },
            "required": list(
                set(
                    [
                        field.name_field
                        for field in fields
                        if field.mandatory and not field.optional_conditions
                    ]
                )
            ),
            "dependentRequired": {
                field.name_field: field.mandatory_conditions
                for field in fields
                if field.mandatory_conditions
            },
            "additionalProperties": False,
        }
        optional_conditions = [
            optional_conditions_to_jsonschema(field.name_field, field.optional_conditions)
            for field in fields
            if type(field.optional_conditions) == list
        ]

        if optional_conditions:
            schema["allOf"] = optional_conditions
        try:
            validate_json(field_mapping_json, schema)
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
    def validate_values(values, destination=None):
        nomenclature_fields = (
            BibFields.query.filter(
                BibFields.destination == (g.destination if (destination is None) else destination),
                BibFields.nomenclature_type != None,
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


@serializable
class ObserverMapping(MappingTemplate):
    __tablename__ = "t_observermappings"
    __table_args__ = {"schema": "gn_imports"}

    id = db.Column(db.Integer, ForeignKey(MappingTemplate.id), primary_key=True)
    values = db.Column(MutableDict.as_mutable(JSON))

    __mapper_args__ = {
        "polymorphic_identity": "OBSERVER",
    }

    @staticmethod
    def validate_values(values, destination=None):
        return True
