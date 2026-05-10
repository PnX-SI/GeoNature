from datetime import datetime

from flask import current_app
import sqlalchemy as sa

from celery.utils.log import get_task_logger
from celery.schedules import crontab

from geonature.utils.env import db
from geonature.utils.celery import celery_app
from geonature.utils.config import config
from geonature.utils.contextmanagers import trigger_disabled
from geonature.core.gn_synthese.models import Synthese
from geonature.core.notifications.utils import dispatch_notifications, NOTIFY_EVERYONE

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


@celery_app.task
def send_synthese_notifications():
    new_obs = db.session.scalars(
        sa.select(Synthese).where(Synthese.meta_notification_date.is_(None))
    ).all()
    if new_obs:
        logger.info(f"Send notifications for {len(new_obs)} new observations.")

        # TODO: add filter on ids? creation date?
        url = current_app.config.get("URL_APPLICATION") + "/#/synthese"

        dispatch_notifications(
            code_categories=["SYNTHESE-OBS-CREATED", "SYNTHESE-OBS-CREATED-%"],
            id_roles=NOTIFY_EVERYONE,
            title="Observation(s) crée(s)",
            url=url,
            context={"observations": new_obs},
        )

        set_meta_notification_date(Synthese.meta_notification_date.is_(None))

    db.session.commit()

    updated_obs = db.session.scalars(
        sa.select(Synthese).where(Synthese.meta_update_date > Synthese.meta_notification_date)
    ).all()
    if updated_obs:
        logger.info(f"Send notifications for {len(updated_obs)} updated observations.")

        # TODO: add filter on ids? update date?
        url = current_app.config.get("URL_APPLICATION") + "/#/synthese"

        dispatch_notifications(
            code_categories=["SYNTHESE-OBS-UPDATED", "SYNTHESE-OBS-UPDATED-%"],
            id_roles=NOTIFY_EVERYONE,
            title="Observation(s) modifiée(s)",
            url=url,
            context={"observations": updated_obs},
        )

        set_meta_notification_date(Synthese.meta_update_date > Synthese.meta_notification_date)

    db.session.commit()


def set_meta_notification_date(whereclause):
    with db.session.begin_nested():
        with trigger_disabled("gn_synthese.synthese", "tri_meta_dates_change_synthese"):
            db.session.execute(
                sa.update(Synthese).where(whereclause).values(meta_notification_date=datetime.now())
            )
