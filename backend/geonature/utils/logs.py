import os
import warnings
import smtplib
import logging
from logging.handlers import SMTPHandler
from .request import request_id


class RequestIdFilter(logging.Filter):

    def filter(self, record):
        record.request_id = request_id() if flask.has_request_context() else ''
        return True


def config_loggers(config):
    """
        Configuration des niveaux de logging/warnings 
        et des hanlers
    """
    root_logger = logging.getLogger()
    root_logger.addHandler(logging.StreamHandler())
    root_logger.setLevel(config["SERVER"]["LOG_LEVEL"])
    root_logger.addFilter(RequestIdFilter())
    if config["MAIL_ON_ERROR"] and config["MAIL_CONFIG"]:
        MAIL_CONFIG = config["MAIL_CONFIG"]
        mail_handler = SMTPHandler(
            mailhost=(MAIL_CONFIG["MAIL_SERVER"], MAIL_CONFIG["MAIL_PORT"]),
            fromaddr=MAIL_CONFIG["MAIL_USERNAME"],
            toaddrs=MAIL_CONFIG["ERROR_MAIL_TO"],
            subject="GeoNature error",
            credentials=(MAIL_CONFIG["MAIL_USERNAME"], MAIL_CONFIG["MAIL_PASSWORD"]),
            secure=(),
        )
        mail_handler.setLevel(logging.ERROR)
        root_logger.addHandler(mail_handler)
    if os.environ.get('FLASK_ENV') == "development":
        warnings.simplefilter("always", DeprecationWarning)
    else:
        gunicorn_error_logger = logging.getLogger("gunicorn.error")
        root_logger.handlers.extend(gunicorn_error_logger.handlers)
