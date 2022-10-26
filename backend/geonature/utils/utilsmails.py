# Fonctions génériques permettant l'envoie de mails
import re
import logging

from smtplib import SMTPException
from flask import current_app
from flask_mail import Message

from geonature.utils.env import MAIL

log = logging.getLogger()

name_address_email_regex = re.compile(r"^([^<]+)<([^>]+)>$", re.IGNORECASE)


def send_mail(recipients, subject, msg_html):
    """Envoi d'un email à l'aide de Flask_mail.

    .. :quickref:  Fonction générique d'envoi d'email.

    Parameters
    ----------
    recipients : str or [str]
        Chaine contenant des emails séparés par des virgules ou liste
        contenant des emails. Un email encadré par des chevrons peut être
        précédé d'un libellé qui sera utilisé lors de l'envoi.

    subject : str
        Sujet de l'email.
    msg_html : str
        Contenu de l'eamil au format HTML.

    Returns
    -------
    void
        L'email est envoyé. Aucun retour.
    """
    with MAIL.connect() as conn:
        mail_sender = current_app.config.get("MAIL_DEFAULT_SENDER")
        if not mail_sender:
            mail_sender = current_app.config["MAIL_USERNAME"]
        msg = Message(subject, sender=mail_sender, recipients=clean_recipients(recipients))
        msg.html = msg_html
        conn.send(msg)


def clean_recipients(recipients):
    """Retourne une liste contenant des emails (str) ou des tuples
    contenant un libelé et l'email correspondant.

    Parameters
    ----------
    recipients : str or [str]
        Chaine contenant des emails séparés par des virgules ou liste
        contenant des emails. Un email encadré par des chevrons peut être
        précédé d'un libellé qui sera utilisé lors de l'envoi.

    Returns
    -------
    [str or tuple]
        Liste contenant des chaines (email) ou des tuples (libellé, email).
    """
    if type(recipients) is list and len(recipients) > 0:
        splited_recipients = recipients
    elif type(recipients) is str and recipients != "":
        splited_recipients = recipients.split(",")
    else:
        raise Exception("Recipients not set")
    trimed_recipients = list(map(str.strip, splited_recipients))
    return list(map(split_name_address, trimed_recipients))


def split_name_address(email):
    """Sépare le libellé de l'email. Le libellé doit précéder l'email qui
    doit être encadré par des chevons. Format : `libellé <email>`. Ex. :
    `Carl von LINNÉ <c.linnaeus@linnaeus.se>`.

    Parameters
    ----------
    email : str
        Chaine contenant un email avec ou sans libellé.

    Returns
    -------
    str or tuple
        L'email simple ou un tuple contenant ("libellé", "email").
    """
    name_address = email
    match = name_address_email_regex.match(email)
    if match:
        name_address = (match.group(1).strip(), match.group(2).strip())
    return name_address
