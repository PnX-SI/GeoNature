import smtplib
import logging
from logging.handlers import SMTPHandler
from flask import current_app


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

# Si la configuration des mails est spécifié
#   et que le paramètre MAIL_ON_ERROR est à True
# Configuration de l'envoie de mail lors des erreurs GeoNature
if current_app.config['MAIL_CONFIG'] and current_app.config['MAIL_ON_ERROR']:
    MAIL_CONFIG = current_app.config['MAIL_CONFIG']
    mail_handler = SSLSMTPHandler(
        mailhost=(MAIL_CONFIG['MAIL_SERVER'], MAIL_CONFIG['MAIL_PORT']),
        fromaddr=MAIL_CONFIG['MAIL_USERNAME'],
        toaddrs=MAIL_CONFIG['ERROR_MAIL_TO'],
        subject='GeoNature error',
        credentials=(MAIL_CONFIG['MAIL_USERNAME'], MAIL_CONFIG['MAIL_PASSWORD']))

    mail_handler.setLevel(logging.ERROR)
