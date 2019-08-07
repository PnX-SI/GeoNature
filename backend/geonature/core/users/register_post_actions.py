"""
Action triggered after register action (create temp user, change password etc...)
"""

from flask import render_template, current_app, url_for
from pypnusershub.db.models import Application, User
from pypnusershub.db.models_register import TempUser

from geonature.utils.utilsmails import send_mail
from geonature.utils.env import DB
from geonature.core.gn_meta.models import (
    TDatasets,
    TAcquisitionFramework,
    CorDatasetActor,
)


def validate_temp_user(data):
    """
       Send an email after the action of account creation

       :param admin_validation_required: if True an admin will receive an email to validate the account creation else the user himself receive the email
       :type admin_validation_required: bool
    """
    token = data.get("token", None)

    user = DB.session.query(TempUser).filter(TempUser.token_role == token).first()

    if not user:
        return {
            "msg": "{token}: ce token n'est pas associé à un compte temporaire".format(
                token=token
            )
        }

    subject = "Demande de création de compte GeoNature"
    if current_app.config["REGISTER"]["AUTO_ACCOUNT_CREATION"]:
        template = "email_self_validate_account.html"
        recipients = [user.email]
    else:
        template = "email_admin_validate_account.html"
        recipients = current_app.config["MAIL_CONFIG"]["MAIL_USERNAME"]
    url_validation = url_for("user.confirmation", token=user.token_role)
    msg_html = render_template(template, url_validation=url_validation, user=user)

    send_mail(recipients, subject, msg_html)

    return {"msg": "ok"}


def create_dataset_user(data):
    print("POST DATASET USE")
    print(data)
    # recuperer le user from data
    # new_af = TAcquisitionFramework(
    #     acquisition_framework_name='test',
    #     acquisition_framework_desc='test'
    # )

    # DB.session.add(new_dataset)
    # DB.session.commit()

    # actor = CorDatasetActor(
    #     id_role=1
    # )
    # new_dataset = TDatasets(
    #     id_acquisition_framework=1,
    #     dataset_name="test",
    #     dataset_shortname='test',
    # )


function_dict = {
    "create_temp_user": validate_temp_user,
    "valid_temp_user": create_dataset_user,
}

