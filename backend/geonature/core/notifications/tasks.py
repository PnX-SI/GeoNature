
from celery.utils.log import get_task_logger

from geonature.utils.celery import celery_app
import geonature.utils.utilsmails as mail

logger = get_task_logger(__name__)


@celery_app.task(bind=True)
def send_notification_mail(self, subject, content, recipient):
    
    logger.info(f"Launch mail.")
    mail.send_mail(recipient, subject, content)
    