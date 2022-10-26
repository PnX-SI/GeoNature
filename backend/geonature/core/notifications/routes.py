import json

import time
import logging

from flask import (
    Blueprint,
    request,
    Response,
    current_app,
    send_from_directory,
    render_template,
    jsonify,
    g,
)
from werkzeug.exceptions import Forbidden, BadRequest
from sqlalchemy import distinct, func, desc, asc, select, text, update
import sqlalchemy as sa
from sqlalchemy.orm import joinedload

from utils_flask_sqla.generic import serializeQuery, GenericTable
from utils_flask_sqla.response import to_csv_resp, to_json_resp, json_resp

from geonature.utils import filemanager
from geonature.utils.env import DB
from geonature.utils.errors import GeonatureApiError

from pypnusershub.db.tools import user_from_token
from pypnusershub.db.models import User

from geonature.core.gn_permissions import decorators as permissions
from geonature.core.notifications.models import (
    Notifications,
    NotificationsMethods,
    NotificationsRules,
    NotificationsTemplates,
    NotificationsCategories,
)
from geonature.core.notifications.utils import Notification

routes = Blueprint("notifications", __name__)
log = logging.getLogger()

# Get all database notification for current user
@routes.route("/notifications", methods=["GET"])
@permissions.login_required
def list_database_notification():

    notifications = Notifications.query.filter(Notifications.id_role == g.current_user.id_role)
    notifications = notifications.order_by(
        Notifications.code_status.desc(), Notifications.creation_date.desc()
    )
    result = [
        notificationsResult.as_dict(
            fields=[
                "id_notification",
                "id_role",
                "title",
                "content",
                "url",
                "code_status",
                "creation_date",
            ]
        )
        for notificationsResult in notifications.all()
    ]
    return jsonify(result)


# count database unread notification for current user
@routes.route("/count", methods=["GET"])
@permissions.login_required
def count_notification():

    notificationNumber = Notifications.query.filter(
        Notifications.id_role == g.current_user.id_role, Notifications.code_status == "UNREAD"
    ).count()
    return jsonify(notificationNumber)


# Update status ( for the moment only UNREAD/READ)
@routes.route("/notification/<int:id_notification>", methods=["POST"])
@json_resp
@permissions.login_required
def update_notification(id_notification):

    notification = Notifications.query.get_or_404(id_notification)
    if notification.id_role != g.current_user.id_role:
        raise Forbidden
    notification.code_status = "READ"
    DB.session.commit()


# Get all database notification for current user
@routes.route("/rules", methods=["GET"])
@permissions.login_required
def list_notification_rules():

    notificationsRules = NotificationsRules.query.filter(
        NotificationsRules.id_role == g.current_user.id_role
    )
    notificationsRules = notificationsRules.order_by(
        NotificationsRules.code_category.desc(),
        NotificationsRules.code_method.desc(),
    )
    notificationsRules = notificationsRules.options(joinedload("notification_method"))
    notificationsRules = notificationsRules.options(joinedload("notification_category"))

    result = [
        notificationsRulesResult.as_dict(
            fields=[
                "id_notification_rules",
                "id_role",
                "code_method",
                "code_category",
                "notification_method.label",
                "notification_method.description",
                "notification_category.label",
                "notification_category.description",
            ]
        )
        for notificationsRulesResult in notificationsRules.all()
    ]
    return jsonify(result)


# add rule for user
@routes.route("/rules", methods=["PUT"])
@permissions.login_required
def create_rule():

    requestData = request.get_json()
    if requestData is None:
        raise BadRequest("Empty request data")

    code_method = requestData.get("code_method", "")
    code_category = requestData.get("code_category", "")

    # Save notification in database as UNREAD
    new_rule = NotificationsRules(
        id_role=g.current_user.id_role,
        code_method=code_method,
        code_category=code_category,
    )

    DB.session.add(new_rule)
    DB.session.commit()

    return jsonify(1)


# Delete all rules for current user
@routes.route("/rules", methods=["DELETE"])
@permissions.login_required
def delete_all_rules():

    nbRulesDeleted = NotificationsRules.query.filter(
        NotificationsRules.id_role == g.current_user.id_role
    ).delete()
    DB.session.commit()
    return jsonify(nbRulesDeleted)


# Delete a specific rule
@routes.route("/rules/<int:id_notification_rules>", methods=["DELETE"])
@permissions.login_required
def delete_rule(id_notification_rules):

    nbRulesDeleted = NotificationsRules.query.filter(
        NotificationsRules.id_role == g.current_user.id_role,
        NotificationsRules.id_notification_rules == id_notification_rules,
    ).delete()
    DB.session.commit()
    return jsonify(nbRulesDeleted)


# Get all availabe method for notification
@routes.route("/methods", methods=["GET"])
@permissions.login_required
def list_notification_methods():
    notificationMethods = NotificationsMethods.query.all()
    result = [
        notificationsMethod.as_dict(
            fields=[
                "code",
                "label",
                "description",
            ]
        )
        for notificationsMethod in notificationMethods
    ]
    return jsonify(result)


# Get all availabe category for notification
@routes.route("/categories", methods=["GET"])
@permissions.login_required
def list_notification_categories():
    notificationCategories = NotificationsCategories.query.all()
    result = [
        notificationsCategory.as_dict(
            fields=[
                "code",
                "label",
                "description",
            ]
        )
        for notificationsCategory in notificationCategories
    ]
    return jsonify(result)
