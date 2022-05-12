import os
import warnings
import smtplib
import logging
from logging.handlers import SMTPHandler
from flask import request, has_request_context
from flask.logging import default_handler


class RequestIdFormatter(logging.Formatter):
    def format(self, record):
        s = super().format(record)
        if has_request_context():
            req_id = request.environ["FLASK_REQUEST_ID"]
            s = f"[{req_id}] {s}"
        return s


def config_loggers(config):
    """
    Configuration des niveaux de logging/warnings
    et des hanlers
    """
    root_logger = logging.getLogger()
    formatter = RequestIdFormatter()
    default_handler.setFormatter(formatter)
    root_logger.addHandler(default_handler)
    root_logger.setLevel(config["SERVER"]["LOG_LEVEL"])
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
    if os.environ.get("FLASK_ENV") == "development":
        warnings.simplefilter("always", DeprecationWarning)
    else:
        gunicorn_error_logger = logging.getLogger("gunicorn.error")
        root_logger.handlers.extend(gunicorn_error_logger.handlers)
