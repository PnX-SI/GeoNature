from celery.schedules import crontab
from celery.utils.log import get_task_logger

from geonature.core.gn_commons.models import TValidations
from geonature.utils.celery import celery_app
from geonature.utils.config import config

logger = get_task_logger(__name__)


@celery_app.on_after_finalize.connect
def setup_periodic_tasks(sender, **kwargs):
    is_enabled = config["VALIDATION"]["AUTO_VALIDATION_ENABLED"]
    ct = config["VALIDATION"]["AUTO_VALIDATION_CRONTAB"]
    if ct and is_enabled:
        minute, hour, day_of_month, month_of_year, day_of_week = ct.split(" ")
        sender.add_periodic_task(
            crontab(
                minute=minute,
                hour=hour,
                day_of_week=day_of_week,
                day_of_month=day_of_month,
                month_of_year=month_of_year,
            ),
            set_auto_validation.s(),
            name="auto validation",
        )


@celery_app.task(bind=True)
def set_auto_validation(self):
    is_enabled = config["VALIDATION"]["AUTO_VALIDATION_ENABLED"]
    fct_auto_validation_name = config["VALIDATION"]["AUTO_VALIDATION_SQL_FUNCTION"]
    if is_enabled:
        logger.info("Set autovalidation...")
        TValidations.auto_validation(fct_auto_validation_name)
        logger.info("Auto validation done")
