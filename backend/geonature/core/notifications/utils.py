from geonature.core.notifications.models import (
    Notification,
    NotificationCategory,
    NotificationRule,
    NotificationTemplate,
)
from geonature.utils.env import db
from jinja2 import Template
from pypnusershub.db.models import User
from geonature.core.notifications.tasks import send_notification_mail
import geonature.utils.utilsmails as mail
import datetime
import logging
import json


class NotificationUtil:
    def create_database_notification(id_role, title, content, url):
        # Save notification in database as UNREAD
        new_notification = Notification(
            id_role=id_role,
            title=title,
            content=content,
            url=url,
            creation_date=datetime.datetime.now(),
            code_status="UNREAD",
        )
        try:
            db.session.add(new_notification)
            db.session.commit()
        except:
            return json.dumps(
                {"success": False, "information": "Could not save notification in database"}
            )
        else:
            return json.dumps({"success": True, "information": "Notification saved"})

    def create_notification(notificationData):
        log = logging.getLogger()
        resultInformation = {"result": []}
        # for all categories given
        categories = notificationData.get("categories")
        if not categories:
            return json.dumps(
                {"success": False, "information": "Category is missing from the request"}
            )

        # loop on given categories
        for category in categories:

            # Check if method exist in config and loop on regex
            categoryRegex = category + "%"
            databaseCategories = NotificationCategory.query.filter(
                NotificationCategory.code.like(categoryRegex)
            )

            if databaseCategories.count() == 0:
                resultInformation["result"].append(
                    {
                        "success": False,
                        "category": category,
                        "information": "This category of notification is not implemented yet",
                    }
                )
                break

            ## Loop on categories
            for databaseCategory in databaseCategories:

                # Set notification title, label category if not set
                title = notificationData.get("title", databaseCategory.label)

                # Get notification method for wanted users
                # Can be several user to notify ( exemple multi digitiser for an observation)
                idRoles = notificationData.get("id_roles")
                if not idRoles:
                    resultInformation["result"].append(
                        {
                            "success": False,
                            "category": databaseCategory.code,
                            "information": "Notification is missing id_role to be notified",
                        }
                    )
                    break

                for role in idRoles:
                    userNotificationsRules = NotificationRule.query.filter(
                        NotificationRule.id_role == role,
                        NotificationRule.code_category == databaseCategory.code,
                    )

                    # if no information then no rules return OK with information
                    if userNotificationsRules.all() == []:
                        resultInformation["result"].append(
                            {
                                "success": False,
                                "category": databaseCategory.code,
                                "role": role,
                                "information": "No rules for this user/category",
                            }
                        )
                        break

                    # loop on all methods subscribed by user
                    # No need to test id method exist ( foreign key constraint)
                    for rule in userNotificationsRules.all():
                        method = rule.code_method

                        # If content exist use it, otherwise use template
                        content = notificationData.get("content")
                        if not content:
                            # get template for this method and category
                            notificationTemplate = NotificationTemplate.query.filter_by(
                                code_method=method,
                                code_category=databaseCategory.code,
                            ).first()
                            if notificationTemplate:
                                # erase existing content with template
                                template = Template(notificationTemplate.content)
                                content = template.render(notificationData)
                            # if no content break | content is
                            if not content or not content.strip():
                                resultInformation["result"].append(
                                    {
                                        "success": False,
                                        "category": databaseCategory.code,
                                        "role": role,
                                        "information": "Empty content not notification sent",
                                    }
                                )
                                break

                        # if method is type BDD
                        if method == "BDD":
                            url = notificationData.get("url", "")
                            message = NotificationUtil.create_database_notification(
                                role, title, content, url
                            )
                            resultInformation["result"].append(message)
                            break

                        # if method is type MAIL
                        if method == "MAIL":

                            # get email for this user notification
                            result = (
                                db.session.query(User.email).filter(User.id_role == role).one()
                            )

                            if result:
                                email = str(result[0])
                                # Send mail via celery
                                if title and content and email:
                                    mailTask = send_notification_mail.s(title, content, email)
                                    mailTask.delay()
                                    resultInformation["result"].append(
                                        {
                                            "success": True,
                                            "category": category,
                                            "role": role,
                                            "method": method,
                                            "information": "Notification sent",
                                        }
                                    )

                                else:
                                    resultInformation["result"].append(
                                        {
                                            "success": False,
                                            "category": category,
                                            "role": role,
                                            "title": title,
                                            "content": content,
                                            "email": email,
                                            "information": "Missing information to send email",
                                        }
                                    )
                            else:
                                resultInformation["result"].append(
                                    {
                                        "success": False,
                                        "category": category,
                                        "role": role,
                                        "information": "Missing user email to send email",
                                    }
                                )
        return json.dumps(resultInformation)
