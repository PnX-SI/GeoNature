"""
Models of gn_notifications schema
"""
import datetime

from sqlalchemy import ForeignKey
from sqlalchemy.sql import select
from sqlalchemy.orm import (
    relationship
)

from utils_flask_sqla.serializers import serializable
from pypnusershub.db.models import User

from geonature.utils.env import DB

@serializable
class BibNotificationsMethods(DB.Model):
    __tablename__ = "bib_notifications_methods"
    __table_args__ = {"schema": "gn_notifications"}
    code_notification_method = DB.Column(DB.Unicode, primary_key=True)
    label_notification_method = DB.Column(DB.Unicode)
    description_notification_method = DB.Column(DB.Unicode)

    def __str__(self):
        return self.code_notification_method.capitalize()


@serializable
class BibNotificationsCategories(DB.Model):
    __tablename__ = "bib_notifications_categories"
    __table_args__ = {"schema": "gn_notifications"}
    code_notification_category = DB.Column(DB.Unicode, primary_key=True)
    label_notification_category = DB.Column(DB.Unicode)
    description_notification_category = DB.Column(DB.Unicode)

    def __str__(self):
        return self.code_notification_category.capitalize()

@serializable
class BibNotificationsTemplates(DB.Model):
    __tablename__ = "bib_notifications_templates"
    __table_args__ = {"schema": "gn_notifications"}
    notification_template_category = DB.Column(DB.Unicode, ForeignKey(BibNotificationsCategories.code_notification_category), primary_key=True)
    notification_template_method = DB.Column(DB.Unicode, ForeignKey(BibNotificationsMethods.code_notification_method), primary_key=True)
    notification_template_content = DB.Column(DB.Unicode)

    def __str__(self):
        return self.notification_template_content()

# Status type example ( read/unread/sent)
@serializable
class BibNotificationsStatus(DB.Model):
    __tablename__ = "bib_notifications_status"
    __table_args__ = {"schema": "gn_notifications"}
    code_notification_status = DB.Column(DB.Unicode, primary_key=True)
    label_notification_status = DB.Column(DB.Unicode)
    description_notification_status = DB.Column(DB.Unicode)

@serializable
class TNotifications(DB.Model):
    __tablename__ = "t_notifications"
    __table_args__ = {"schema": "gn_notifications"}
    id_notification = DB.Column(DB.Integer, primary_key=True)
    id_role = DB.Column(DB.Integer, ForeignKey(User.id_role))
    title = DB.Column(DB.Unicode)
    content = DB.Column(DB.Unicode)
    url = DB.Column(DB.Unicode)
    code_status = DB.Column(DB.Unicode, ForeignKey(BibNotificationsStatus.code_notification_status))
    creation_date = DB.Column(DB.DateTime(), default=datetime.datetime.utcnow)

    notification_status = relationship(BibNotificationsStatus)
    user = DB.relationship(User)

@serializable
class TNotificationsRules(DB.Model):
    __tablename__ = "t_notifications_rules"
    __table_args__ = {"schema": "gn_notifications"}
    id_notification_rules = DB.Column(DB.Integer, primary_key=True)
    id_role = DB.Column(DB.Integer, ForeignKey(User.id_role))
    code_notification_method = DB.Column(DB.Unicode, ForeignKey(BibNotificationsMethods.code_notification_method))
    code_notification_category = DB.Column(DB.Unicode, ForeignKey(BibNotificationsCategories.code_notification_category))
    
