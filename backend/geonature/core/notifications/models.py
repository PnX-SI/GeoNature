"""
Models of gn_notifications schema
"""
import datetime

from sqlalchemy import ForeignKey
from sqlalchemy.sql import select
from sqlalchemy.orm import relationship

from utils_flask_sqla.serializers import serializable
from pypnusershub.db.models import User

from geonature.utils.env import DB


@serializable
class NotificationsMethods(DB.Model):
    __tablename__ = "bib_notifications_methods"
    __table_args__ = {"schema": "gn_notifications"}
    code = DB.Column(DB.Unicode, primary_key=True)
    label = DB.Column(DB.Unicode)
    description = DB.Column(DB.Unicode)

    def __str__(self):
        return self.code.capitalize()


@serializable
class NotificationsCategories(DB.Model):
    __tablename__ = "bib_notifications_categories"
    __table_args__ = {"schema": "gn_notifications"}
    code = DB.Column(DB.Unicode, primary_key=True)
    label = DB.Column(DB.Unicode)
    description = DB.Column(DB.Unicode)

    def __str__(self):
        return self.code.capitalize()


@serializable
class NotificationsTemplates(DB.Model):
    __tablename__ = "bib_notifications_templates"
    __table_args__ = {"schema": "gn_notifications"}
    code_category = DB.Column(
        DB.Unicode,
        ForeignKey(NotificationsCategories.code),
        primary_key=True,
    )
    code_method = DB.Column(DB.Unicode, ForeignKey(NotificationsMethods.code), primary_key=True)
    content = DB.Column(DB.Unicode)

    def __str__(self):
        return self.content


@serializable
class Notifications(DB.Model):
    __tablename__ = "t_notifications"
    __table_args__ = {"schema": "gn_notifications"}
    id_notification = DB.Column(DB.Integer, primary_key=True)
    id_role = DB.Column(DB.Integer, ForeignKey(User.id_role), nullable=False)
    title = DB.Column(DB.Unicode)
    content = DB.Column(DB.Unicode)
    url = DB.Column(DB.Unicode)
    code_status = DB.Column(DB.Unicode)
    creation_date = DB.Column(DB.DateTime(), default=datetime.datetime.utcnow)

    user = DB.relationship(User)


@serializable
class NotificationsRules(DB.Model):
    __tablename__ = "t_notifications_rules"
    __table_args__ = {"schema": "gn_notifications"}
    id_notification_rules = DB.Column(DB.Integer, primary_key=True)
    id_role = DB.Column(DB.Integer, ForeignKey(User.id_role), nullable=False)
    code_method = DB.Column(DB.Unicode, ForeignKey(NotificationsMethods.code), nullable=False)
    code_category = DB.Column(
        DB.Unicode,
        ForeignKey(NotificationsCategories.code),
        nullable=False,
    )

    notification_method = relationship(NotificationsMethods)
    notification_category = relationship(NotificationsCategories)

    user = DB.relationship(User)
