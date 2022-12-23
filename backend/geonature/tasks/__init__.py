from celery.signals import task_postrun

from geonature.utils.env import db
from geonature.utils.celery import celery_app


@task_postrun.connect
def close_session(*args, **kwargs):
    db.session.remove()
