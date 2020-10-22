# Fonctions génériques permettant l'envoie de mails
import re

from flask import current_app
from flask_mail import Message

name_address_email_regex = re.compile(r"^([^<]+)<([^>]+)>$", re.IGNORECASE)

def send_mail(recipients, subject, msg_html):
    """
        Send email with Flask_mail

        .. :quickref:  Generic fonction for sending email

        :query str or [str] recipients: Recipients in comma 
            separated string or in list. Syntax to use a label with email:
            Label <email@my-domain.dot>
        :query str subject: Subjet of the mail
        :query str msg_html: Mail content in HTML

        **Returns:**
        .. void
    """
    # Import here to permit use of other functions in config schema.
    from server import MAIL

    if not MAIL:
        raise Exception("No configuration for email")

    with MAIL.connect() as conn:
        mail_sender = current_app.config.get("MAIL_DEFAULT_SENDER") 
        if not mail_sender:
            mail_sender = current_app.config["MAIL_USERNAME"]

        msg = Message(
            subject,
            sender=mail_sender,
            recipients=clean_recipients(recipients)
        )

        msg.html = msg_html

        conn.send(msg)


def clean_recipients(recipients):
    splited_recipients = recipients if type(recipients) is list else recipients.split(",")
    trimed_recipients = list(map(str.strip, splited_recipients))
    return list(map(split_name_address, trimed_recipients))


def split_name_address(email):
    name_address = email
    match = name_address_email_regex.match(email)
    if match:
        name_address=(match.group(1).strip(), match.group(2).strip())
    return name_address
