"""
Models of gn_permissions schema
"""

from sqlalchemy import ForeignKey
from sqlalchemy.sql import select

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

    role = db.relationship(User)
    action = db.relationship(PermAction)
    module = db.relationship("TModules")
    object = db.relationship(PermObject)

    scope_value = db.Column(db.Integer, ForeignKey(PermScope.value), nullable=True)
    scope = db.relationship(PermScope)

    def has_other_filters_than(self, *args):
        if self.scope_value is not None and "SCOPE" not in args:
            return True
        return False
