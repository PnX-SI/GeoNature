from geonature.core.notifications.models import (
    Notifications,
    NotificationsCategories,
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
    def create_database_notification(id_role, title, content, url):
        # Save notification in database as UNREAD
        new_notification = Notifications(
            id_role=id_role,
            title=title,
            content=content,
            url=url,
            creation_date=datetime.datetime.now(),
            code_status="UNREAD",
        )
        try:
            DB.session.add(new_notification)
            DB.session.commit()
        except:
            return json.dumps(
                {"success": False, "information": "Could not save notification in database"}
            )
        else:
            return json.dumps({"success": True, "information": "Notification saved"})

    def create_notification(notificationData):
        log = logging.getLogger()
        # for all categories given
        categories = notificationData.get("categories")
        if not categories:
            return json.dumps(
                {"success": False, "information": "Category is missing from the request"}
            )

        for category in categories:

            # Check if method exist in config
            categorie_exists = NotificationsCategories.query.filter_by(code=category).one()
            if not categorie_exists:
                return json.dumps(
                    {
                        "success": False,
                        "information": "This categorie of notification in not implement yet",
                    }
                )
            # Set notification title, label categorie if not set
            title = notificationData.get("title", categorie_exists.label)

            # Get notification method for wanted users
            # Can be several user to notify ( exemple multi digitiser for an observation)
            idRoles = notificationData.get("id_roles")
            if not idRoles:
                return json.dumps(
                    {
                        "success": False,
                        "information": "Notification is missing id_role to be notify",
                    }
                )

            for role in idRoles:
                userNotificationsRules = NotificationsRules.query.filter(
                    NotificationsRules.id_role == role,
                    NotificationsRules.code_category == category,
                )

                # if no information then no rules return OK with information
                if userNotificationsRules.all() == []:
                    return json.dumps(
                        {"success": False, "information": "No rules for this user/category"}
                    )

                # loop on all methods subscribed by user
                # No need to test id method exist ( foreign key constraint)
                for rule in userNotificationsRules.all():
                    method = rule.code_method

                    # If content exist use it, otherwise use template
                    content = notificationData.get("content")
                    if not content:
                        # get template for this method and category
                        notificationTemplate = NotificationsTemplates.query.filter_by(
                            code_method=method,
                            code_category=category,
                        ).one()
                        if notificationTemplate:
                            # erase existing content with template
                            template = Template(notificationTemplate.content)
                            content = template.render(notificationData)

                    # if method is type BDD
                    if method == "BDD":
                        url = notificationData.get("url", "")
                        message = Notification.create_database_notification(
                            role, title, content, url
                        )
                        log.debug("Notification return %s ", message)

                    # if method is type MAIL
                    if method == "MAIL":

                        # get email for this user notification
                        result = DB.session.query(User.email).filter(User.id_role == role).one()

                        if result:
                            email = str(result[0])
                            log.debug("Notification email : %s", email)
                            # Send mail via celery
                            if title and content and email:
                                mailTask = send_notification_mail.s(title, content, email)
                                mailTask.delay()
