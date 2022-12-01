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

from geonature.utils.env import db

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
@permissions.login_required
def update_notification(id_notification):

    notification = Notification.query.get_or_404(id_notification)
    if notification.id_role != g.current_user.id_role:
        raise Forbidden
    notification.code_status = "READ"
    db.session.commit()
    return jsonify(notification.as_dict())


# Get all database notification for current user
@routes.route("/rules", methods=["GET"])
@permissions.login_required
def list_notification_rules():
    rules = (
        NotificationRule.query.filter(NotificationRule.id_role == g.current_user.id_role)
        .order_by(
            NotificationRule.code_category.desc(),
            NotificationRule.code_method.desc(),
        )
        .options(
            joinedload("method"),
            joinedload("category"),
        )
    )
    result = [
        rule.as_dict(
            fields=[
                "id",
                "id_role",
                "code_method",
                "code_category",
                "method.label",
                "method.description",
                "category.label",
                "category.description",
            ]
        )
        for rule in rules.all()
    ]
    return jsonify(result)


# Delete all rules for current user
@routes.route("/notifications", methods=["DELETE"])
@permissions.login_required
def delete_all_notifications():
    nbNotificationsDeleted = Notification.query.filter(
        Notification.id_role == g.current_user.id_role
    ).delete()
    db.session.commit()
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

    # Create new rule for current user
    new_rule = NotificationRule(
        id_role=g.current_user.id_role,
        code_method=code_method,
        code_category=code_category,
    )
    db.session.add(new_rule)
    db.session.commit()
    return jsonify(new_rule.as_dict())


# Delete all rules for current user
@routes.route("/rules", methods=["DELETE"])
@permissions.login_required
def delete_all_rules():
    nbRulesDeleted = NotificationRule.query.filter(
        NotificationRule.id_role == g.current_user.id_role
    ).delete()
    db.session.commit()
    return jsonify(nbRulesDeleted)


# Delete a specific rule
@routes.route("/rules/<int:id>", methods=["DELETE"])
@permissions.login_required
def delete_rule(id):
    rule = NotificationRule.query.get_or_404(id)
    if rule.user != g.current_user:
        raise Forbidden
    db.session.delete(rule)
    db.session.commit()
    return "", 204


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
