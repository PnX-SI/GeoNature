from geonature.core.notifications.models import (
    Notifications,
    NotificationsMethods,
    NotificationsRules,
    NotificationsTemplates,
)
from geonature.utils.env import DB
from jinja2 import Template
from pypnusershub.db.models import User
from werkzeug.exceptions import BadRequest
from geonature.core.notifications.tasks import send_notification_mail
import geonature.utils.utilsmails as mail
import datetime
import logging
import json


class Notification:
    def create_notification(requestData):
        log = logging.getLogger()
        # for all categories given
        categories = requestData.get("categories")
        if not categories:
            json.dumps({"success": False, "information": "Category is missing from the request"})

        for category in categories:
            # Get notification method for wanted users
            # Can be several user to notify ( exemple multi digitiser for an observation)
            idRoles = requestData.get("id_roles")
            log.info("Notification search for category code %s", category)
            if not idRoles:
                return (json.dumps({"success": False, "information": "Notification is missing id_role to be notify"}))

            for role in idRoles:
                userNotificationsRules = NotificationsRules.query.filter(
                    NotificationsRules.id_role == role,
                    NotificationsRules.code_category == category,
                )

                # if no information then no rules return OK with information
                if userNotificationsRules.all() == []:
                    return (json.dumps({"success": False, "information": "No rules for this user/category"}))

                # else get all methods
                for rule in userNotificationsRules.all():
                    method = rule.code_method

                    # Check if method exist in config
                    method_exists = NotificationsMethods.query.filter_by(code=method).one()
                    if not method_exists:
                        return (json.dumps({"success": False, "information": "This method of notification in not implement yet"}))

                    title = requestData.get("title", "")
                    content = requestData.get("content", "")

                    # get template for this method and category
                    notificationTemplate = NotificationsTemplates.query.filter_by(
                        code_method=method,
                        code_category=category,
                    ).one()
                    if notificationTemplate:
                        # erase existing content with template
                        template = Template(notificationTemplate.content)
                        content = template.render(requestData)

                    # if method is type BDD
                    if method == "BDD":

                        session = DB.session
                        # Save notification in database as UNREAD
                        new_notification = Notifications(
                            id_role=role,
                            title=title,
                            content=content,
                            url=requestData.get("url", ""),
                            creation_date=datetime.datetime.now(),
                            code_status="UNREAD",
                        )
                        session.add(new_notification)
                        session.commit()

                    # if method is type MAIL
                    if method == "MAIL":

                        # get email for this user notification
                        result = DB.session.query(User.email).filter(User.id_role == role).one()

                        if result:
                            email = str(result[0])
                            log.info("Notification email : %s", email)
                            # Send mail via celery
                            if title and content and email:
                                mailTask = send_notification_mail.s(title, content, email)
                                mailTask.delay()
