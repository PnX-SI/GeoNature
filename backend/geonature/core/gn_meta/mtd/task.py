from celery.schedules import crontab
from celery.utils.log import get_task_logger

from geonature.core.gn_commons.repositories import TMediumRepository
from geonature.core.gn_meta.mtd import sync_af_and_ds
from geonature.utils.celery import celery_app
from geonature.utils.config import config

logger = get_task_logger(__name__)


@celery_app.on_after_finalize.connect
def setup_periodic_tasks(sender, **kwargs):
    ct = config["MTD_SYNC_CRONTAB"]
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
            start_mtd_sync.s(),
            name="mtd sync",
        )


@celery_app.task(bind=True)
def start_mtd_sync(self):
    logger.info("syncing mtd ...")
    sync_af_and_ds()
    logger.info("Mtd synced")
