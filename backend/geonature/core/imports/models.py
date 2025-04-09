from datetime import datetime
from collections.abc import Mapping
import re
from typing import Any, Iterable, List, Optional
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

from utils_flask_sqla.models import qfilter
from utils_flask_sqla.serializers import serializable

from geonature.utils.env import db
from geonature.utils.celery import celery_app
from geonature.core.gn_permissions.tools import get_scopes_by_action
from geonature.core.gn_commons.models import TModules
from pypnnomenclature.models import BibNomenclaturesTypes
from pypnusershub.db.models import User


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
    id_entity = db.Column(
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

    id_destination = db.Column(db.Integer, primary_key=True, autoincrement=True)
    id_module = db.Column(db.Integer, ForeignKey(TModules.id_module), nullable=True)
    code = db.Column(db.String(64), unique=True)
    label = db.Column(db.String(128))
    table_name = db.Column(db.String(64))

    module = relationship(TModules, backref="destination")
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
        all_destination = db.session.scalars(sa.select(Destination)).all()
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
    id_unique_column = db.Column(
        db.Integer, db.ForeignKey("gn_imports.bib_fields.id_field"), primary_key=True
    )
    id_parent = db.Column(db.Integer, ForeignKey("gn_imports.bib_entities.id_entity"))

    parent = relationship("Entity", back_populates="childs", remote_side=[id_entity])
    childs = relationship("Entity", back_populates="parent")
    fields = relationship("EntityField", back_populates="entity")
    unique_column = relationship("BibFields")

    id_object = db.Column(db.Integer, db.ForeignKey("gn_permissions.t_objects.id_object"))
    object = relationship("PermObject")

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


@serializable(
    fields=[
        "authors.nom_complet",
        "destination.code",
        "destination.label",
        "destination.statistics_labels",
        "destination.module",
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
    date_create_import = db.Column(db.DateTime, default=datetime.now)
    date_update_import = db.Column(db.DateTime, default=datetime.now, onupdate=datetime.now)
    date_end_import = db.Column(db.DateTime, nullable=True)
    source_count = db.Column(db.Integer, nullable=True)
    erroneous_rows = deferred(db.Column(ARRAY(db.Integer), nullable=True))
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
    type_field_params = db.Column(MutableDict.as_mutable(JSON))
    mandatory = db.Column(db.Boolean, nullable=False)
    autogenerated = db.Column(db.Boolean, nullable=False)
    mnemonique = db.Column(db.Unicode, db.ForeignKey(BibNomenclaturesTypes.mnemonique))
    nomenclature_type = relationship("BibNomenclaturesTypes")
    display = db.Column(db.Boolean, nullable=False)
    multi = db.Column(db.Boolean)
    optional_conditions = db.Column(db.ARRAY(db.Unicode), nullable=True)
    mandatory_conditions = db.Column(db.ARRAY(db.Unicode), nullable=True)

    entities = relationship("EntityField", back_populates="field")

    @property
    def source_column(self):
        return self.source_field if self.source_field else self.dest_field

    @property
    def dest_column(self):
        return self.dest_field if self.dest_field else self.source_field

    def __str__(self):
        return self.fr_label


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

    id = db.Column(db.Integer, primary_key=True)
    id_destination = db.Column(db.Integer, ForeignKey(Destination.id_destination), nullable=False)
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
                    ),
                    BibFields.name_field.in_(field_mapping_json.keys()),
                ),
            )

            # no field --> nothing to check. next entity !
            if not fields_of_ent:
                continue

            # if the only column corresponds to id_columns, we only do the validation on the latter
            if [entity.unique_column.name_field] == [f.name_field for f in fields_of_ent]:
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
