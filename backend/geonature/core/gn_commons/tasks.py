from celery.schedules import crontab
from celery.utils.log import get_task_logger

from geonature.core.gn_commons.repositories import TMediumRepository
from geonature.utils.celery import celery_app
from geonature.utils.config import config

logger = get_task_logger(__name__)


@celery_app.on_after_finalize.connect
def setup_periodic_tasks(sender, **kwargs):
    ct = config["MEDIA_CLEAN_CRONTAB"]
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
            clean_attachments.s(),
            name="clean medias",
        )


@celery_app.task(bind=True)
def clean_attachments(self):
    logger.info("Cleaning medias...")
    TMediumRepository.sync_medias()
    logger.info("Medias cleaned")
