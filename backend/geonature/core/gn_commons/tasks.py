from datetime import datetime, timedelta
from pathlib import Path

from celery.schedules import crontab
from celery.utils.log import get_task_logger
from flask import current_app
from sqlalchemy import delete

from geonature.core.gn_commons.repositories import TMediumRepository
from geonature.core.gn_commons.models import Task
from geonature.utils.env import db
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

    sender.add_periodic_task(
        crontab(minute="0", hour="0"),
        delete_file_and_tasks_celery.s(),
        name="Clean export files",
    )


@celery_app.task(bind=True)
def clean_attachments(self):
    logger.info("Cleaning medias...")
    TMediumRepository.sync_medias()
    logger.info("Medias cleaned")


def delete_file_and_tasks():
    """
    Fonction permettant de supprimer les fichiers générés
    par le module export ayant plus de X jours

    .. :quickref: Fonction permettant de supprimer les
        fichiers générés par le module export ayant plus de X jours

    """
    time_to_del = datetime.timestamp(datetime.today() - timedelta(days=15))
    path_to_delete = Path(current_app.config["MEDIA_FOLDER"]) / "exports/usr_generated"
    for item in path_to_delete.glob("**/*"):
        item_time = item.stat().st_mtime
        if item_time < time_to_del:
            if item.is_file():
                item.unlink()
    # delete tasks
    db.session.execute(delete(Task).where(Task.end < time_to_del))


@celery_app.task(bind=True)
def delete_file_and_tasks_celery(self):
    delete_file_and_tasks()
