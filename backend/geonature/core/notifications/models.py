"""
Models of gn_notifications schema
"""

from typing import Optional
import datetime
from math import perm

from geonature.core.gn_commons.models.base import TModules
from geonature.core.gn_permissions.models import PermAction, PermObject
from geonature.core.gn_permissions.tools import get_user_permissions
import sqlalchemy as sa
from sqlalchemy import ForeignKey
from sqlalchemy.orm import relationship, Mapped, mapped_column
from flask import g
from utils_flask_sqla.models import qfilter

from utils_flask_sqla.serializers import serializable
from pypnusershub.db.models import User

from geonature.utils.env import db


@serializable
class NotificationMethod(db.Model):
    __tablename__ = "bib_notifications_methods"
    __table_args__ = {"schema": "gn_notifications"}
    code: Mapped[str] = mapped_column(db.Unicode, primary_key=True)
    label: Mapped[Optional[str]] = mapped_column(db.Unicode)
    description: Mapped[Optional[str]] = mapped_column(db.UnicodeText)

    @property
    def display(self):
        if self.label:
            return f"{self} – {self.label}"
        else:
            return str(self)

    def __str__(self):
        return self.code


@serializable
class NotificationCategory(db.Model):
    __tablename__ = "bib_notifications_categories"
    __table_args__ = {"schema": "gn_notifications"}
    code: Mapped[str] = mapped_column(db.Unicode, primary_key=True)
    label: Mapped[Optional[str]] = mapped_column(db.Unicode)
    description: Mapped[Optional[str]] = mapped_column(db.UnicodeText)

    id_module: Mapped[Optional[int]] = mapped_column(
        db.Integer, ForeignKey("gn_commons.t_modules.id_module")
    )
    module = relationship(TModules)
    id_object: Mapped[Optional[int]] = mapped_column(
        db.Integer, ForeignKey("gn_permissions.t_objects.id_object")
    )
    object = relationship(PermObject)
    id_action: Mapped[Optional[int]] = mapped_column(
        db.Integer, ForeignKey("gn_permissions.bib_actions.id_action")
    )
    action = relationship(PermAction)

    def is_allowed(self, user=None) -> bool:
        if user is None:
            user = g.current_user
        id_role = user.id_role
        permissions = get_user_permissions(id_role)
        if self.id_module:
            permissions = [p for p in permissions if p.id_module == self.id_module]
        if self.id_object:
            permissions = [p for p in permissions if p.id_object == self.id_object]
        if self.id_action:
            permissions = [p for p in permissions if p.id_action == self.id_action]
        return bool(permissions)

    @property
    def display(self):
        if self.label:
            return f"{self} – {self.label}"
        else:
            return str(self)

    def __str__(self):
        return self.code


@serializable
class NotificationTemplate(db.Model):
    __tablename__ = "bib_notifications_templates"
    __table_args__ = {"schema": "gn_notifications"}
    code_category: Mapped[str] = mapped_column(
        db.Unicode,
        ForeignKey(NotificationCategory.code),
        primary_key=True,
    )
    code_method: Mapped[str] = mapped_column(
        db.Unicode, ForeignKey(NotificationMethod.code), primary_key=True
    )
    content: Mapped[Optional[str]] = mapped_column(db.UnicodeText)

    category = db.relationship(NotificationCategory)
    method = db.relationship(NotificationMethod)

    def __str__(self):
        return self.content


@serializable
class Notification(db.Model):
    __tablename__ = "t_notifications"
    __table_args__ = {"schema": "gn_notifications"}
    id_notification: Mapped[int] = mapped_column(db.Integer, primary_key=True)
    id_role: Mapped[int] = mapped_column(db.Integer, ForeignKey(User.id_role))
    title: Mapped[Optional[str]] = mapped_column(db.Unicode)
    content: Mapped[Optional[str]] = mapped_column(db.UnicodeText)
    url: Mapped[Optional[str]] = mapped_column(db.Unicode)
    code_status: Mapped[Optional[str]] = mapped_column(db.Unicode)
    creation_date: Mapped[Optional[datetime.datetime]] = mapped_column(
        db.DateTime(), default=datetime.datetime.utcnow
    )

    user = db.relationship(User)


@serializable
class NotificationRule(db.Model):
    __tablename__ = "t_notifications_rules"
    __table_args__ = (
        db.UniqueConstraint(
            "id_role", "code_method", "code_category", name="un_role_method_category"
        ),
        db.Index(
            "un_method_category",
            "code_method",
            "code_category",
            unique=True,
            postgresql_ops={
                "where": sa.text("id_role IS NULL"),
            },
        ),
        {"schema": "gn_notifications"},
    )

    id: Mapped[int] = mapped_column(db.Integer, primary_key=True)
    id_role: Mapped[Optional[int]] = mapped_column(db.Integer, ForeignKey(User.id_role))
    code_method: Mapped[str] = mapped_column(db.Unicode, ForeignKey(NotificationMethod.code))
    code_category: Mapped[str] = mapped_column(
        db.Unicode,
        ForeignKey(NotificationCategory.code),
    )
    subscribed: Mapped[bool]

    method = relationship(NotificationMethod)
    category = relationship(NotificationCategory)
    user = db.relationship(User)

    @qfilter(query=True)
    def filter_by_role_with_defaults(cls, *, query, id_role=None):
        if id_role is None:
            id_role = g.current_user.id_role
        cte = (
            sa.select(NotificationRule)
            .where(
                sa.or_(
                    NotificationRule.id_role.is_(None),
                    NotificationRule.id_role == id_role,
                )
            )
            .distinct(NotificationRule.code_category, NotificationRule.code_method)
            .order_by(
                NotificationRule.code_category.desc(),
                NotificationRule.code_method.desc(),
                NotificationRule.id_role.asc(),
            )
            .cte("cte")
        )
        return query.where(NotificationRule.id == cte.c.id)
