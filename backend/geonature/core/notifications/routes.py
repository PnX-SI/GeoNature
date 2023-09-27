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
    rules = NotificationRule.query.filter_by_role_with_defaults().options(
        joinedload("method"),
        joinedload("category"),
    )
    result = [
        rule.as_dict(
            fields=[
                "code_method",
                "code_category",
                "method.label",
                "method.description",
                "category.label",
                "category.description",
                "subscribed",
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
@routes.route(
    "/rules/category/<code_category>/method/<code_method>/subscribe",
    methods=["POST"],
    defaults={"subscribe": True},
)
@routes.route(
    "/rules/category/<code_category>/method/<code_method>/unsubscribe",
    methods=["POST"],
    defaults={"subscribe": False},
)
@permissions.login_required
def update_rule(code_category, code_method, subscribe):
    if not db.session.query(
        NotificationCategory.query.filter_by(code=str(code_category)).exists()
    ).scalar():
        raise BadRequest("Invalid category")
    if not db.session.query(
        NotificationMethod.query.filter_by(code=str(code_method)).exists()
    ).scalar():
        raise BadRequest("Invalid method")

    # Create new rule for current user
    rule = NotificationRule.query.filter_by(
        id_role=g.current_user.id_role,
        code_method=code_method,
        code_category=code_category,
    ).one_or_none()
    if rule:
        rule.subscribed = subscribe
    else:
        rule = NotificationRule(
            id_role=g.current_user.id_role,
            code_method=code_method,
            code_category=code_category,
            subscribed=subscribe,
        )
        db.session.add(rule)
    db.session.commit()
    return jsonify(rule.as_dict(fields=["code_method", "code_category", "subscribed"]))


# Delete all rules for current user
@routes.route("/rules", methods=["DELETE"])
@permissions.login_required
def delete_all_rules():
    nbRulesDeleted = NotificationRule.query.filter(
        NotificationRule.id_role == g.current_user.id_role
    ).delete()
    db.session.commit()
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
