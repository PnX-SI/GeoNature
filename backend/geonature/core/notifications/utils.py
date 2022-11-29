from itertools import chain, product

from jinja2 import Template
from flask import current_app

from pypnusershub.db.models import User

from geonature.core.notifications.models import (
    Notification,
    NotificationCategory,
    NotificationRule,
    NotificationTemplate,
)
from geonature.utils.env import db
from geonature.core.notifications.tasks import send_notification_mail


def dispatch_notifications(
    code_categories, id_roles, title=None, url=None, *, content=None, context={}
):
    if not current_app.config["NOTIFICATION"]["ENABLED"]:
        return

    categories = chain.from_iterable(
        [
            NotificationCategory.query.filter(NotificationCategory.code.like(code)).all()
            for code in code_categories
        ]
    )
    roles = [User.query.get(id_role) for id_role in id_roles]

    for category, role in product(categories, roles):
        dispatch_notification(category, role, title, url, content=content, context=context)


def dispatch_notification(category, role, title=None, url=None, *, content=None, context={}):
    if not title:
        title = category.label

    # add role, title and url to rendering context
    context = {"role": role, "title": title, "url": url, **context}

    rules = NotificationRule.query.filter(
        NotificationRule.id_role == role.id_role,
        NotificationRule.code_category == category.code,
    )
    for rule in rules.all():
        if not content:
            # get template for this method and category
            notificationTemplate = NotificationTemplate.query.filter_by(
                category=category,
                method=rule.method,
            ).one_or_none()
            if not notificationTemplate:
                continue
            template = Template(notificationTemplate.content)
            content = template.render(context)
            # if no content break | content is
            if not content.strip():
                continue

        if rule.code_method == "DB":
            send_db_notification(role, title, content, url)
        elif rule.code_method == "MAIL":
            send_mail_notification(role, title, content)


def send_db_notification(role, title, content, url):
    # Save notification in database as UNREAD
    current_app.logger.info(f"Send database notification to {role}")
    notification = Notification(
        user=role,
        title=title,
        content=content,
        url=url,
        code_status="UNREAD",
    )
    db.session.add(notification)
    return notification


def send_mail_notification(role, title, content):
    if not role.email:
        return
    current_app.logger.info(f"Send email notification to {role} ({role.email})")
    send_notification_mail.delay(title, content, role.email)
