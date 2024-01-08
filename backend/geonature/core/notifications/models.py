"""
Models of gn_notifications schema
"""
import datetime

import sqlalchemy as sa
from sqlalchemy import ForeignKey
from sqlalchemy.sql import select
from sqlalchemy.orm import relationship
from flask import g
from utils_flask_sqla.models import qfilter

from utils_flask_sqla.serializers import serializable
from pypnusershub.db.models import User

from geonature.utils.env import db


@serializable
class NotificationMethod(db.Model):
    __tablename__ = "bib_notifications_methods"
    __table_args__ = {"schema": "gn_notifications"}
    code = db.Column(db.Unicode, primary_key=True)
    label = db.Column(db.Unicode)
    description = db.Column(db.UnicodeText)

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
    code = db.Column(db.Unicode, primary_key=True)
    label = db.Column(db.Unicode)
    description = db.Column(db.UnicodeText)

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
    code_category = db.Column(
        db.Unicode,
        ForeignKey(NotificationCategory.code),
        primary_key=True,
    )
    code_method = db.Column(db.Unicode, ForeignKey(NotificationMethod.code), primary_key=True)
    content = db.Column(db.UnicodeText)

    category = db.relationship(NotificationCategory)
    method = db.relationship(NotificationMethod)

    def __str__(self):
        return self.content


@serializable
class Notification(db.Model):
    __tablename__ = "t_notifications"
    __table_args__ = {"schema": "gn_notifications"}
    id_notification = db.Column(db.Integer, primary_key=True)
    id_role = db.Column(db.Integer, ForeignKey(User.id_role), nullable=False)
    title = db.Column(db.Unicode)
    content = db.Column(db.UnicodeText)
    url = db.Column(db.Unicode)
    code_status = db.Column(db.Unicode)
    creation_date = db.Column(db.DateTime(), default=datetime.datetime.utcnow)

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

    id = db.Column(db.Integer, primary_key=True)
    id_role = db.Column(db.Integer, ForeignKey(User.id_role), nullable=True)
    code_method = db.Column(db.Unicode, ForeignKey(NotificationMethod.code), nullable=False)
    code_category = db.Column(
        db.Unicode,
        ForeignKey(NotificationCategory.code),
        nullable=False,
    )
    subscribed = db.Column(db.Boolean, nullable=False)

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
