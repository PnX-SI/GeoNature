import json
import datetime
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

from geonature.core.notifications.models import TNotifications, BibNotificationsMethods, BibNotificationsStatus, TNotificationsRules

routes = Blueprint("notifications", __name__)
log = logging.getLogger()

# Notification input in Json
# Mandatory attribut (category, method)
# reserved attribut (title, url, content)
# if attribut content exist no templating
# otherwise all other attribut will be used in templating
@routes.route("/notification", methods=["PUT"])
@json_resp
def create_notification():

    data = request.get_json()
    log.info(data)
    if data is None:
        raise BadRequest("Empty request data")
   
    # Check if category is in the list
    category = data["category"]
    if not category :
        raise BadRequest("Category is missing from the request")

    # Get notification method for current user for the given category
    user_notifications_rules = TNotificationsRules.query.filter(TNotificationsRules.id_role == g.current_user.id_role, TNotificationsRules.code_notification_category == category)

    # if no information then no rules return OK with information
    if user_notifications_rules.all() == []:
        return json.dumps({'success':True, 'information':'No rules for this user/category'}), 200, {'ContentType':'application/json'} 

    # else get all methods 
    for rule in user_notifications_rules.all():
        log.info(rule.code_notification_method)
        method = rule.code_notification_method
       
        # Check if method exist in config
        method_exists = BibNotificationsMethods.query.filter_by(code_notification_method=method).first()
        if not method_exists:
            raise BadRequest("This type of notification in not implement yet")
    
        title = data["title"]
        content = data["content"]
        url = data["url"]

        # if method is type BDD
        if method == "BDD": 
                
            session = DB.session
            # Save notification in database as UNREAD
            new_notification = TNotifications(
                id_role=g.current_user.id_role,
                title=title,
                content=content,
                url=url,
                creation_date=datetime.datetime.now(),
                code_status="UNREAD"
            )
            session.add(new_notification)
            session.commit()

        # if method is type MAIL
        #if method == "MAIL": 
            # get category

            # get templates

            # replace information in templates

            # Send mail via celery


    
    
# Get all database notification for current user
@routes.route("/notifications", methods=["GET"])
def list_database_notification():

    notifications = TNotifications.query.filter(TNotifications.id_role == g.current_user.id_role)
    notifications = notifications.order_by(TNotifications.code_status.desc(), TNotifications.creation_date.desc())
    notifications = notifications.options(
        joinedload("notification_status")
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

    notificationNumber = TNotifications.query.filter(TNotifications.id_role == g.current_user.id_role, TNotifications.code_status == "UNREAD").count()
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
