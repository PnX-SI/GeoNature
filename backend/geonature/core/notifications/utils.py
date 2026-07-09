from itertools import chain, groupby, product

from jinja2 import Environment
from flask import current_app
import sqlalchemy as sa

from pypnusershub.db.models import User, CorRoles

from geonature.core.notifications.models import (
    Notification,
    NotificationCategory,
    NotificationMethod,
    NotificationRule,
    NotificationTemplate,
)
from geonature.utils.env import db
from geonature.core.notifications.tasks import send_notification_mail
from sqlalchemy import select
from sqlalchemy.orm import joinedload

NOTIFY_EVERYONE = object()  # sentinel object


class SkipNotification(Exception):
    pass


def get_expanded_notification_rules():
    """
    Get expanded notification rules combining user-specific group, and default rules.

    Rules are prioritized as follows:
    - Priority 0: User-specific rules (highest precedence)
    - Priority 1: Group rules (inherited by group members)

    For each (id_role, code_category, code_method) combination, only the rule
    with the highest priority (lowest value) is kept. If multiple rules from
    the same priority level exist (e.g., multiple groups), subscribed=true
    takes precedence.

    Returns:
        A SQLAlchemy CTE containing the expanded rules + default rules with columns:
        - id
        - id_role (individual user)
        - code_category
        - code_method
        - subscribed
    """
    # User-specific rules (non-group targets, priority 0 = higher precedence)
    user_rules = (
        sa.select(
            NotificationRule.id,
            NotificationRule.code_category,
            NotificationRule.code_method,
            NotificationRule.subscribed,
            User.id_role,
            sa.literal(0).label("priority"),
        )
        .select_from(NotificationRule)
        .join(User, User.id_role == NotificationRule.id_role)
        .where(
            User.groupe == sa.false(),
        )
    )

    # Group rules expanded to their members (priority 1 = lower precedence)
    group_rules = (
        sa.select(
            NotificationRule.id,
            NotificationRule.code_category,
            NotificationRule.code_method,
            NotificationRule.subscribed,
            CorRoles.id_role_utilisateur.label("id_role"),
            sa.literal(1).label("priority"),
        )
        .select_from(NotificationRule)
        .join(User, User.id_role == NotificationRule.id_role)
        .join(CorRoles, CorRoles.id_role_groupe == User.id_role)
        .where(
            User.groupe == sa.true(),
        )
    )

    # All rules with duplicates
    unioned_rules = sa.union_all(user_rules, group_rules).cte("unioned_rules")

    # Per-user rules after group expansion + default rules
    expanded_user_rules = (
        sa.select(
            unioned_rules.c.id,
            unioned_rules.c.id_role,
            unioned_rules.c.code_category,
            unioned_rules.c.code_method,
            unioned_rules.c.subscribed,
        )
        .distinct(
            unioned_rules.c.id_role,
            unioned_rules.c.code_category,
            unioned_rules.c.code_method,
        )
        .order_by(
            unioned_rules.c.id_role,
            unioned_rules.c.code_category,
            unioned_rules.c.code_method,
            unioned_rules.c.priority.asc(),
            unioned_rules.c.subscribed.desc(),  # (multi-group) subscribe win vs unsuscribe
        )
    )

    # Default rules
    default_rules = (
        sa.select(
            NotificationRule.id,
            NotificationRule.id_role,
            NotificationRule.code_category,
            NotificationRule.code_method,
            NotificationRule.subscribed,
        )
        .select_from(NotificationRule)
        .where(NotificationRule.id_role.is_(None))
    )

    # expanded user rules + default rules
    return sa.union_all(expanded_user_rules, default_rules).cte("expanded_rules")


def get_effective_rules(rules=None, id_role=User.id_role):
    """
    Get the effective notification rules from a set of rules with user + default rules.

    Args:
        rules: If None, use `get_expanded_notification_rules()` to take groups into account.
        id_role: The id_role to filter rules for.
                 Defaults to ``User.id_role``, which can be used as a lateral join expression.
    """
    if rules is None:
        rules = get_expanded_notification_rules()

    return (
        sa.select(rules)
        .where(
            sa.or_(
                rules.c.id_role.is_(None),
                rules.c.id_role == id_role,
            )
        )
        .order_by(
            rules.c.code_category.desc(),  # important for distinct
            rules.c.code_method.desc(),  # important for distinct
            rules.c.id_role.asc(),  # NULL comes after with PostgreSQL
        )
        .distinct(
            rules.c.code_category, rules.c.code_method
        )  # keep only the effective rule for each (category, method) couple
    )


def dispatch_notifications(
    code_categories, id_roles, title=None, url=None, *, content=None, context={}, **kwargs
):
    if not current_app.config["NOTIFICATIONS_ENABLED"]:
        return

    all_expanded_rules = get_expanded_notification_rules()

    expanded_rules = (
        sa.select(all_expanded_rules)
        .where(
            sa.or_(
                *[
                    all_expanded_rules.c.code_category.like(category)
                    for category in code_categories
                ],
            )
        )
        .cte("expanded_rules_for_categories")
    )

    effective_rules = get_effective_rules(expanded_rules).lateral()
    stmt = (
        select(User, NotificationCategory, NotificationMethod)
        .select_from(User)
        .join(effective_rules, sa.true())
        .join(
            NotificationCategory,
            effective_rules.c.code_category == NotificationCategory.code,
        )
        .join(
            NotificationMethod,
            effective_rules.c.code_method == NotificationMethod.code,
        )
        .where(
            effective_rules.c.subscribed == sa.true(),
        )
        .order_by(NotificationCategory.code, NotificationMethod.code)
    )
    if id_roles != NOTIFY_EVERYONE:
        stmt = stmt.where(User.id_role.in_(id_roles))
    results = db.session.execute(stmt).all()

    environment = Environment()

    for (category, method), group in groupby(
        results, key=lambda res: (res[1], res[2])  # (category, method)
    ):
        notification_kwargs = {"content": content, "context": context, **kwargs}
        template = None
        if not content:
            template = db.session.scalars(
                sa.select(NotificationTemplate).filter_by(category=category, method=method)
            ).one_or_none()
            if not template:
                # There are no templates for this category/method, and not content have been provided: do not notify
                continue
            notification_kwargs["template"] = environment.from_string(template.content)
        for role, _, _ in group:
            # The context may be a callable, which will be called for each user
            # This allows to use a different context for each user
            if template and callable(context):
                try:
                    notification_kwargs["context"] = context(
                        category,
                        method,
                        role,
                        environment=environment,
                        template=template.content,
                    )
                except SkipNotification:
                    continue
            send_notification(
                category,
                method,
                role,
                title=title,
                url=url,
                **notification_kwargs,
            )


def send_notification(
    category, method, role, *, title, url, content=None, template=None, context={}
):
    """
    Send a notification of a given category to a given role using a specific method.
    """
    if content:
        notification_content = content
    else:
        # add role, title and url to rendering context
        context = {"role": role, "title": title, "url": url, **context}
        notification_content = template.render(context)
        if not notification_content.strip():
            return

    send_notification_to_method(method, role, title, url, notification_content)


def send_notification_to_method(method, role, title, url, content):
    if method.code == "DB":
        send_notification_to_db(role, title, content, url)
    elif method.code == "EMAIL":
        send_notification_to_email(role, title, content)


def send_notification_to_db(role, title, content, url):
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


def send_notification_to_email(role, title, content):
    if not role.email:
        return
    current_app.logger.info(f"Send email notification to {role} ({role.email})")
    send_notification_mail.delay(f"[GeoNature] {title}", content, role.email)
