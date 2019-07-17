# Fonctions génériques permettant l'envoie de mails

from flask import current_app
from flask_mail import Message

from server import MAIL


def send_mail(recipients, subject, msg_html):
    if not MAIL:
        raise Exception("No configuration for email")

    with MAIL.connect() as conn:
        msg = Message(
            subject,
            sender=current_app.config["MAIL_FROM"],
            recipients=recipients
        )

        msg.html = msg_html

        conn.send(msg)
