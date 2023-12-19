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
from sqlalchemy import select, func, delete, exists

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
    notifications = select(Notification).where(Notification.id_role == g.current_user.id_role)
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
        for notificationsResult in db.session.scalars(notifications).all()
    ]
    return jsonify(result)


# count database unread notification for current user
@routes.route("/count", methods=["GET"])
@permissions.login_required
def count_notification():
    notificationNumber = db.session.execute(
        select(func.count("*"))
        .select_from(Notification)
        .where(
            Notification.id_role == g.current_user.id_role, Notification.code_status == "UNREAD"
        )
    ).scalar_one()
    return jsonify(notificationNumber)


# Update status ( for the moment only UNREAD/READ)
@routes.route("/notifications/<int:id_notification>", methods=["POST"])
@permissions.login_required
def update_notification(id_notification):
    notification = db.get_or_404(Notification, id_notification)
    if notification.id_role != g.current_user.id_role:
        raise Forbidden
    notification.code_status = "READ"
    db.session.commit()
    return jsonify(notification.as_dict())


# Get all database notification for current user
@routes.route("/rules", methods=["GET"])
@permissions.login_required
def list_notification_rules():
    rules = NotificationRule.filter_by_role_with_defaults().options(
        joinedload(NotificationRule.method),
        joinedload(NotificationRule.category),
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
        for rule in db.session.scalars(rules).all()
    ]
    return jsonify(result)


# Delete all rules for current user
@routes.route("/notifications", methods=["DELETE"])
@permissions.login_required
def delete_all_notifications():
    nbNotificationsDeleted = delete(Notification).where(
        Notification.id_role == g.current_user.id_role
    )
    nbNotificationsDeleted = db.session.execute(nbNotificationsDeleted).rowcount
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
    if not db.session.scalar(
        exists().where(NotificationCategory.code == str(code_category)).select()
    ):
        raise BadRequest("Invalid category")

    if not db.session.scalar(exists().where(NotificationMethod.code == str(code_method)).select()):
        raise BadRequest("Invalid method")

    # Create new rule for current user
    rule = db.session.scalars(
        select(NotificationRule).filter_by(
            id_role=g.current_user.id_role,
            code_method=code_method,
            code_category=code_category,
        )
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
    nb_rules_deleted = delete(NotificationRule).where(
        NotificationRule.id_role == g.current_user.id_role
    )
    nb_rules_deleted = db.session.execute(nb_rules_deleted).rowcount
    db.session.commit()
    return jsonify(nb_rules_deleted)


# Get all availabe method for notification
@routes.route("/methods", methods=["GET"])
@permissions.login_required
def list_notification_methods():
    notificationMethods = db.session.scalars(
        select(NotificationMethod).order_by(NotificationMethod.code.asc())
    ).all()
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
    notificationCategories = db.session.scalars(
        select(NotificationCategory).order_by(NotificationCategory.code.asc())
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
