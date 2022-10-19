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
from werkzeug.exceptions import Forbidden, NotFound, BadRequest, Conflict
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

from geonature.core.notifications.models import (
    TNotifications,
    BibNotificationsMethods,
    BibNotificationsStatus,
    TNotificationsRules,
    BibNotificationsTemplates,
)
from geonature.core.notifications.utils import Notification

routes = Blueprint("notifications", __name__)
log = logging.getLogger()

# Notification input in Json
# Mandatory attribut (category, method)
# reserved attribut (title, url, content)
# if attribut content exist no templating
# otherwise all other attribut will be used in templating
@routes.route("/notification", methods=["PUT"])
@json_resp
def create_notification_from_api():

    requestData = request.get_json()
    if requestData is None:
        raise BadRequest("Empty request data")

    Notification.create_notification(requestData)


# Get all database notification for current user
@routes.route("/notifications", methods=["GET"])
def list_database_notification():

    notifications = TNotifications.query.filter(TNotifications.id_role == g.current_user.id_role)
    notifications = notifications.order_by(
        TNotifications.code_status.desc(), TNotifications.creation_date.desc()
    )
    notifications = notifications.options(joinedload("notification_status"))
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
                "notification_status.code_notification_status",
                "notification_status.label_notification_status",
            ]
        )
        for notificationsResult in notifications.all()
    ]
    return jsonify(result)


# count database unread notification for current user
@routes.route("/count", methods=["GET"])
def count_notification():

    notificationNumber = TNotifications.query.filter(
        TNotifications.id_role == g.current_user.id_role, TNotifications.code_status == "UNREAD"
    ).count()
    return jsonify(notificationNumber)


# Update status ( for the moment only UNREAD/READ)
@routes.route("/notification", methods=["POST"])
@json_resp
def update_notification():

    session = DB.session
    data = request.get_json()
    if data is None:
        raise BadRequest("Empty request data")

    # Information to check if notification is need
    id_notification = data["id_notification"]
    notification = TNotifications.query.get_or_404(id_notification)
    if notification.id_role != g.current_user.id_role:
        raise Forbidden
    notification.code_status = "READ"
    session.commit()
