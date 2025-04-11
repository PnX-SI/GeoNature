from sqlalchemy.sql import func
from celery.utils.log import get_task_logger
from celery.schedules import crontab

from geonature.utils.env import db
from geonature.utils.config import config
from geonature.utils.celery import celery_app


logger = get_task_logger(__name__)


@celery_app.on_after_finalize.connect
def setup_periodic_tasks(sender, **kwargs):
    ct = config["PROFILES_REFRESH_CRONTAB"]
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
            refresh_profiles.s(),
            name="refresh profiles",
        )


@celery_app.task(bind=True)
def refresh_profiles(self):
    logger.info("Refresh profiles...")
    db.session.execute(func.gn_profiles.refresh_profiles())
    db.session.commit()
    logger.info("Profiles refreshed.")
