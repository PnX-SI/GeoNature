import os
import warnings
import smtplib
import logging
import flask
from logging.handlers import SMTPHandler
from .request import request_id


# custom class to send email in SSL and with non ascii character
class SSLSMTPHandler(SMTPHandler):
    """ Custom class to emit email log with SSL """

    def emit(self, record):
        """
        Emit a record.
        """
        try:
            from email.mime.text import MIMEText
            from email.utils import formatdate

            port = self.mailport
            if not port:
                port = smtplib.SMTP_PORT
            smtp = smtplib.SMTP_SSL(self.mailhost, port)
            msg = self.format(record)
            message = MIMEText(msg, _charset="utf-8")

            message.add_header("Subject", self.getSubject(record))
            message.add_header("From", self.fromaddr)
            message.add_header("To", ",".join(self.toaddrs))
            message.add_header("Date", formatdate())

            if self.username:
                smtp.login(self.username, self.password)
            smtp.sendmail(self.fromaddr, self.toaddrs, message.as_string())
            smtp.quit()
        except (KeyboardInterrupt, SystemExit):
            raise
        except:
            self.handleError(record)


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
        mail_handler = SSLSMTPHandler(
            mailhost=(MAIL_CONFIG["MAIL_SERVER"], MAIL_CONFIG["MAIL_PORT"]),
            fromaddr=MAIL_CONFIG["MAIL_USERNAME"],
            toaddrs=MAIL_CONFIG["ERROR_MAIL_TO"],
            subject="GeoNature error",
            credentials=(MAIL_CONFIG["MAIL_USERNAME"], MAIL_CONFIG["MAIL_PASSWORD"]),
        )
        mail_handler.setLevel(logging.ERROR)
        root_logger.addHandler(mail_handler)
    if os.environ.get('FLASK_ENV') == "development":
        warnings.simplefilter("always", DeprecationWarning)
    else:
        gunicorn_error_logger = logging.getLogger("gunicorn.error")
        root_logger.handlers.extend(gunicorn_error_logger.handlers)
