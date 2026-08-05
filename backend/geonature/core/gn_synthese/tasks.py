from datetime import datetime
from functools import partial

from flask import current_app
from geonature.core.gn_permissions.tools import get_permissions
from geonature.core.gn_synthese.utils.query_select_sqla import SyntheseQuery
import sqlalchemy as sa
from jinja2.meta import find_undeclared_variables

from celery.utils.log import get_task_logger
from celery.schedules import crontab

from geonature.utils.env import db
from geonature.utils.celery import celery_app
from geonature.utils.config import config
from geonature.utils.contextmanagers import trigger_disabled
from geonature.core.gn_synthese.models import Synthese
from geonature.core.notifications.utils import (
    dispatch_notifications,
    NOTIFY_EVERYONE,
    SkipNotification,
)

logger = get_task_logger(__name__)


@celery_app.on_after_finalize.connect
def setup_periodic_tasks(sender, **kwargs):
    ct = config["SYNTHESE"]["NOTIFICATIONS_CRONTAB"]
    if ct:
        minute, hour, day_of_month, month_of_year, day_of_week = ct.split(" ")
        sender.add_periodic_task(
            crontab(
                minute=minute,
                hour=hour,
                day_of_week=day_of_week,
                day_of_month=day_of_month,
                month_of_year=month_of_year,
            ),
            send_synthese_notifications.s(),
            name="synthese notifications",
        )


def get_obs(obs_ids, role, permissions=None):
    stmt = sa.select(Synthese).where(Synthese.id_synthese.in_(obs_ids))
    if permissions:
        query = SyntheseQuery(model=Synthese, query=stmt, filters={})
        query.apply_all_filters(role, permissions)
        stmt = query.build_query()
    return db.session.scalars(stmt).all()


def get_context_builder(obs_ids):
    def context_builder(category, method, role, *, environment, template, **kwargs):
        context = {
            "obs_ids": obs_ids,
            "get_obs": partial(get_obs, role=role),
            "get_permissions": partial(get_permissions, id_role=role.id_role),
        }
        ast = environment.parse(template)
        undeclared_variables = find_undeclared_variables(ast)
        if "observations" in undeclared_variables:
            observations = get_obs(
                obs_ids,
                role,
                permissions=get_permissions(
                    action_code="R", id_role=role.id_role, module_code="SYNTHESE"
                ),
            )
            if not observations:
                raise SkipNotification
            context.update({"observations": observations})
        return context

    return context_builder


@celery_app.task
def send_synthese_notifications():
    new_obs_ids = db.session.scalars(
        sa.select(Synthese.id_synthese).where(Synthese.meta_notification_date.is_(None))
    ).all()
    if new_obs_ids:
        logger.info(f"Send notifications for {len(new_obs_ids)} new observations.")

        # TODO: add filter on ids? creation date?
        url = current_app.config.get("URL_APPLICATION") + "/#/synthese"

        dispatch_notifications(
            code_categories=["SYNTHESE-OBS-CREATED", "SYNTHESE-OBS-CREATED-%"],
            id_roles=NOTIFY_EVERYONE,
            title="Observation(s) crée(s)",
            url=url,
            context=get_context_builder(new_obs_ids),
        )

        set_meta_notification_date(Synthese.id_synthese.in_(new_obs_ids))

    db.session.commit()

    updated_obs_ids = db.session.scalars(
        sa.select(Synthese.id_synthese).where(
            Synthese.meta_update_date > Synthese.meta_notification_date
        )
    ).all()
    if updated_obs_ids:
        logger.info(f"Send notifications for {len(updated_obs_ids)} updated observations.")

        # TODO: add filter on ids? update date?
        url = current_app.config.get("URL_APPLICATION") + "/#/synthese"

        dispatch_notifications(
            code_categories=["SYNTHESE-OBS-UPDATED", "SYNTHESE-OBS-UPDATED-%"],
            id_roles=NOTIFY_EVERYONE,
            title="Observation(s) modifiée(s)",
            url=url,
            context=get_context_builder(updated_obs_ids),
        )

        set_meta_notification_date(Synthese.id_synthese.in_(updated_obs_ids))

    db.session.commit()


def set_meta_notification_date(whereclause):
    with db.session.begin_nested():
        with trigger_disabled("gn_synthese.synthese", "tri_meta_dates_change_synthese"):
            db.session.execute(
                sa.update(Synthese).where(whereclause).values(meta_notification_date=datetime.now())
            )
