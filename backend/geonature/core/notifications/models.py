"""
Models of gn_notifications schema
"""
import datetime

from sqlalchemy import ForeignKey
from sqlalchemy.sql import select
from sqlalchemy.orm import relationship

from utils_flask_sqla.serializers import serializable
from pypnusershub.db.models import User

from geonature.utils.env import db


@serializable
class NotificationMethod(db.Model):
    __tablename__ = "bib_notifications_methods"
    __table_args__ = {"schema": "gn_notifications"}
    code = db.Column(db.Unicode, primary_key=True)
    label = db.Column(db.Unicode)
    description = db.Column(db.Unicode)

    def __str__(self):
        return self.code.capitalize()


@serializable
class NotificationCategory(db.Model):
    __tablename__ = "bib_notifications_categories"
    __table_args__ = {"schema": "gn_notifications"}
    code = db.Column(db.Unicode, primary_key=True)
    label = db.Column(db.Unicode)
    description = db.Column(db.Unicode)

    def __str__(self):
        return self.code.capitalize()


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
    content = db.Column(db.Unicode)

    def __str__(self):
        return self.content


@serializable
class Notification(db.Model):
    __tablename__ = "t_notifications"
    __table_args__ = {"schema": "gn_notifications"}
    id_notification = db.Column(db.Integer, primary_key=True)
    id_role = db.Column(db.Integer, ForeignKey(User.id_role), nullable=False)
    title = db.Column(db.Unicode)
    content = db.Column(db.Unicode)
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
        {"schema": "gn_notifications"},
    )
    id_notification_rules = db.Column(db.Integer, primary_key=True)
    id_role = db.Column(db.Integer, ForeignKey(User.id_role), nullable=False)
    code_method = db.Column(db.Unicode, ForeignKey(NotificationMethod.code), nullable=False)
    code_category = db.Column(
        db.Unicode,
        ForeignKey(NotificationCategory.code),
        nullable=False,
    )

    notification_method = relationship(NotificationMethod)
    notification_category = relationship(NotificationCategory)

    user = db.relationship(User)
