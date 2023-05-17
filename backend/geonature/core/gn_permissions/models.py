"""
Models of gn_permissions schema
"""

import sqlalchemy as sa
from sqlalchemy import ForeignKey
from sqlalchemy.sql import select
from sqlalchemy.orm import foreign

from utils_flask_sqla.serializers import serializable
from pypnusershub.db.models import User

from geonature.utils.env import db


@serializable
class PermFilterType(db.Model):
    __tablename__ = "bib_filters_type"
    __table_args__ = {"schema": "gn_permissions"}
    id_filter_type = db.Column(db.Integer, primary_key=True)
    code_filter_type = db.Column(db.Unicode)
    label_filter_type = db.Column(db.Unicode)
    description_filter_type = db.Column(db.Unicode)


@serializable
class PermScope(db.Model):
    __tablename__ = "bib_filters_scope"
    __table_args__ = {"schema": "gn_permissions"}
    value = db.Column(db.Integer, primary_key=True)
    label = db.Column(db.Unicode)
    description = db.Column(db.Unicode)

    def __str__(self):
        return self.description


@serializable
class PermAction(db.Model):
    __tablename__ = "bib_actions"
    __table_args__ = {"schema": "gn_permissions"}
    id_action = db.Column(db.Integer, primary_key=True)
    code_action = db.Column(db.Unicode)
    description_action = db.Column(db.Unicode)

    def __str__(self):
        return self.description_action


cor_object_module = db.Table(
    "cor_object_module",
    db.Column(
        "id_cor_object_module",
        db.Integer,
        primary_key=True,
    ),
    db.Column(
        "id_object",
        db.Integer,
        ForeignKey("gn_permissions.t_objects.id_object"),
    ),
    db.Column(
        "id_module",
        db.Integer,
        ForeignKey("gn_commons.t_modules.id_module"),
    ),
    schema="gn_permissions",
)


@serializable
class PermObject(db.Model):
    __tablename__ = "t_objects"
    __table_args__ = {"schema": "gn_permissions"}
    id_object = db.Column(db.Integer, primary_key=True)
    code_object = db.Column(db.Unicode)
    description_object = db.Column(db.Unicode)

    def __str__(self):
        return f"{self.code_object} ({self.description_object})"


# compat.
TObjects = PermObject


class PermissionAvailable(db.Model):
    __tablename__ = "t_permissions_available"
    __table_args__ = {"schema": "gn_permissions"}
    id_module = db.Column(
        db.Integer, ForeignKey("gn_commons.t_modules.id_module"), primary_key=True
    )
    id_object = db.Column(
        db.Integer,
        ForeignKey(PermObject.id_object),
        default=select([PermObject.id_object]).where(PermObject.code_object == "ALL"),
        primary_key=True,
    )
    id_action = db.Column(db.Integer, ForeignKey(PermAction.id_action), primary_key=True)
    label = db.Column(db.Unicode)

    module = db.relationship("TModules")
    object = db.relationship(PermObject)
    action = db.relationship(PermAction)

    scope_filter = db.Column(db.Boolean, server_default=sa.false())
    sensitivity_filter = db.Column(db.Boolean, server_default=sa.false(), nullable=False)

    filters_fields = {
        "SCOPE": scope_filter,
        "SENSITIVITY": sensitivity_filter,
    }

    @property
    def filters(self):
        return [k for k, v in self.filters_fields.items() if getattr(self, v.name)]

    def __str__(self):
        return self.label


class PermFilter:
    def __init__(self, name, value):
        self.name = name
        self.value = value

    def __str__(self):
        if self.name == "SCOPE":
            if self.value == 1:
                return """<i class="fa fa-user" aria-hidden="true"></i> à moi"""
            elif self.value == 2:
                return """<i class="fa fa-users" aria-hidden="true"></i> de mon organisme"""
        elif self.name == "SENSITIVITY":
            if self.value:
                return """<i class="fa fa-low-vision" aria-hidden="true"></i>  non sensible"""


@serializable
class Permission(db.Model):
    __tablename__ = "t_permissions"
    __table_args__ = {"schema": "gn_permissions"}
    id_permission = db.Column(db.Integer, primary_key=True)
    id_role = db.Column(db.Integer, ForeignKey("utilisateurs.t_roles.id_role"))
    id_action = db.Column(db.Integer, ForeignKey(PermAction.id_action))
    id_module = db.Column(db.Integer, ForeignKey("gn_commons.t_modules.id_module"))
    id_object = db.Column(
        db.Integer,
        ForeignKey(PermObject.id_object),
        default=select([PermObject.id_object]).where(PermObject.code_object == "ALL"),
    )

    role = db.relationship(User, backref="permissions")
    action = db.relationship(PermAction)
    module = db.relationship("TModules")
    object = db.relationship(PermObject)

    scope_value = db.Column(db.Integer, ForeignKey(PermScope.value), nullable=True)
    scope = db.relationship(PermScope)
    sensitivity_filter = db.Column(db.Boolean, server_default=sa.false(), nullable=False)

    availability = db.relationship(
        PermissionAvailable,
        primaryjoin=sa.and_(
            foreign(id_module) == PermissionAvailable.id_module,
            foreign(id_object) == PermissionAvailable.id_object,
            foreign(id_action) == PermissionAvailable.id_action,
        ),
    )

    filters_fields = {
        "SCOPE": scope_value,
        "SENSITIVITY": sensitivity_filter,
    }

    @staticmethod
    def __SCOPE_le__(a, b):
        return b is None or (a is not None and a <= b)

    @staticmethod
    def __SENSITIVITY_le__(a, b):
        # False only if: A is False and b is True
        return (not a) <= (not b)

    @staticmethod
    def __default_le__(a, b):
        return a == b or b is None

    def __le__(self, other):
        """
        Return True if this permission is supersed by 'other' permission.
        This requires all filters to be supersed by 'other' filters.
        """
        for name, field in self.filters_fields.items():
            # Get filter comparison function or use default comparison function
            __le_fct__ = getattr(self, f"__{name}_le__", Permission.__default_le__)
            self_value, other_value = getattr(self, field.name), getattr(other, field.name)
            if not __le_fct__(self_value, other_value):
                return False
        return True

    @property
    def filters(self):
        filters = []
        for name, field in self.filters_fields.items():
            value = getattr(self, field.name)
            if field.nullable:
                if value is None:
                    continue
            if field.type.python_type == bool:
                if not value:
                    continue
            filters.append(PermFilter(name, value))
        return filters

    def filters_display(self):
        display = []
        for name, value in self.filters:
            if name == "SCOPE":
                if value == 1:
                    display.append("m’appartenant")
                elif value == 2:
                    display.append("appartenant à mon organisme")
            elif name == "SENSITIVITY":
                if value:
                    display.append("non sensible")
        return ", ".join(display)

    def has_other_filters_than(self, *expected_filters):
        for flt in self.filters:
            if flt.name not in expected_filters:
                return True
        return False
