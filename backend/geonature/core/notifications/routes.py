import json

import logging

from flask import (
    Blueprint,
    request,
    jsonify,
    g,
)
from werkzeug.exceptions import Forbidden, BadRequest
import sqlalchemy as sa
from sqlalchemy.orm import joinedload

from utils_flask_sqla.response import json_resp

from geonature.utils.env import DB

from geonature.core.gn_permissions import decorators as permissions
from geonature.core.notifications.models import (
    Notification,
    NotificationMethod,
    NotificationRule,
    NotificationTemplate,
    NotificationCategory,
)

routes = Blueprint("notifications", __name__)
log = logging.getLogger()

# Get all database notification for current user
@routes.route("/notifications", methods=["GET"])
@permissions.login_required
def list_database_notification():

    notifications = Notification.query.filter(Notification.id_role == g.current_user.id_role)
    notifications = notifications.order_by(
        Notification.code_status.desc(), Notification.creation_date.desc()
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

    notificationNumber = Notification.query.filter(
        Notification.id_role == g.current_user.id_role, Notification.code_status == "UNREAD"
    ).count()
    return jsonify(notificationNumber)


# Update status ( for the moment only UNREAD/READ)
@routes.route("/notifications/<int:id_notification>", methods=["POST"])
@json_resp
@permissions.login_required
def update_notification(id_notification):

    notification = Notification.query.get_or_404(id_notification)
    if notification.id_role != g.current_user.id_role:
        raise Forbidden
    notification.code_status = "READ"
    try:
        DB.session.commit()
    except:
        return json.dumps({"success": False, "information": "Could not update notification"})
    else:
        return json.dumps({"success": True}), 200, {"ContentType": "application/json"}


# Get all database notification for current user
@routes.route("/rules", methods=["GET"])
@permissions.login_required
def list_notification_rules():

    notificationsRules = NotificationRule.query.filter(
        NotificationRule.id_role == g.current_user.id_role
    )
    notificationsRules = notificationsRules.order_by(
        NotificationRule.code_category.desc(),
        NotificationRule.code_method.desc(),
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


# Delete all rules for current user
@routes.route("/notifications", methods=["DELETE"])
@permissions.login_required
def delete_all_notifications():

    nbNotificationsDeleted = Notification.query.filter(
        Notification.id_role == g.current_user.id_role
    ).delete()
    DB.session.commit()
    return jsonify(nbNotificationsDeleted)


# add rule for user
@routes.route("/rules", methods=["PUT"])
@permissions.login_required
def create_rule():

    requestData = request.get_json()
    if requestData is None:
        raise BadRequest("Empty request data")

    code_method = requestData.get("code_method", "")
    if not code_method:
        raise BadRequest("Missing method")

    code_category = requestData.get("code_category", "")
    if not code_category:
        raise BadRequest("Missing category")

    # Save notification in database as UNREAD
    new_rule = NotificationRule(
        id_role=g.current_user.id_role,
        code_method=code_method,
        code_category=code_category,
    )
    try:
        DB.session.add(new_rule)
        DB.session.commit()
    except:
        return json.dumps({"success": False, "information": "Could not save rule in database"})
    else:
        return json.dumps({"success": True}), 200, {"ContentType": "application/json"}


# Delete all rules for current user
@routes.route("/rules", methods=["DELETE"])
@permissions.login_required
def delete_all_rules():

    nbRulesDeleted = NotificationRule.query.filter(
        NotificationRule.id_role == g.current_user.id_role
    ).delete()
    DB.session.commit()
    return jsonify(nbRulesDeleted)


# Delete a specific rule
@routes.route("/rules/<int:id_notification_rules>", methods=["DELETE"])
@permissions.login_required
def delete_rule(id_notification_rules):

    nbRulesDeleted = NotificationRule.query.filter(
        NotificationRule.id_role == g.current_user.id_role,
        NotificationRule.id_notification_rules == id_notification_rules,
    ).delete()
    DB.session.commit()
    return jsonify(nbRulesDeleted)


# Get all availabe method for notification
@routes.route("/methods", methods=["GET"])
@permissions.login_required
def list_notification_methods():
    notificationMethods = NotificationMethod.query.order_by(NotificationMethod.code.asc()).all()
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
    notificationCategories = NotificationCategory.query.order_by(
        NotificationCategory.code.asc()
    ).all()
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
