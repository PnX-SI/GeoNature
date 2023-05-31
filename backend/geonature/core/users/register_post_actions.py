"""
Action triggered after register action (create temp user, change password etc...)
"""
import datetime
from warnings import warn

from flask import Markup, render_template, current_app, url_for
from pypnusershub.db.models import Application, User
from pypnusershub.db.models_register import TempUser
from sqlalchemy.sql import func

from geonature.core.gn_commons.models import TModules
from geonature.core.gn_meta.models import (
    TDatasets,
    TAcquisitionFramework,
    CorDatasetActor,
    CorAcquisitionFrameworkActor,
)
from geonature.utils.utilsmails import send_mail
from geonature.utils.env import db, DB


def validate_temp_user(data):
    """
    Send an email after the action of account creation.

    :param admin_validation_required: if True an admin will receive an
    email to validate the account creation else the user himself
    receive the email.
    :type admin_validation_required: bool
    """
    token = data.get("token", None)

    user = DB.session.query(TempUser).filter(TempUser.token_role == token).first()

    if not user:
        return {
            "msg": "{token}: ce token n'est pas associé à un compte temporaire".format(token=token)
        }
    user_dict = user.as_dict()
    subject = "Demande de création de compte GeoNature"
    if current_app.config["ACCOUNT_MANAGEMENT"]["AUTO_ACCOUNT_CREATION"]:
        template = "email_self_validate_account.html"
        recipients = [user.email]
    else:
        template = "email_admin_validate_account.html"
        recipients = [current_app.config["ACCOUNT_MANAGEMENT"]["VALIDATOR_EMAIL"]]
    url_validation = url_for("users.confirmation", token=user.token_role, _external=True)

    additional_fields = [
        {"key": key, "value": value} for key, value in (user_dict.get("champs_addi") or {}).items()
    ]

    msg_html = render_template(
        template,
        url_validation=url_validation,
        user=user_dict,
        additional_fields=additional_fields,
    )

    send_mail(recipients, subject, msg_html)

    return {"msg": "ok"}


def execute_actions_after_validation(data):
    if current_app.config["ACCOUNT_MANAGEMENT"]["AUTO_DATASET_CREATION"]:
        create_dataset_user(data)
    inform_user(data)
    return {"msg": "ok"}


def create_dataset_user(user):
    """
    After dataset validation, add a personnal AF and JDD so the user
    can add new user.
    """
    af_desc_and_name = "Cadre d'acquisition personnel de {name} {surname}".format(
        name=user["nom_role"], surname=user["prenom_role"]
    )

    #  actor = data productor
    af_productor = CorAcquisitionFrameworkActor(
        id_role=user["id_role"],
        id_nomenclature_actor_role=func.ref_nomenclatures.get_id_nomenclature("ROLE_ACTEUR", "6"),
    )
    af_contact = CorAcquisitionFrameworkActor(
        id_role=user["id_role"],
        id_nomenclature_actor_role=func.ref_nomenclatures.get_id_nomenclature("ROLE_ACTEUR", "1"),
    )

    new_af = TAcquisitionFramework(
        acquisition_framework_name=af_desc_and_name,
        acquisition_framework_desc=af_desc_and_name
        + " - auto-créé via la demande de création de compte",
        acquisition_framework_start_date=datetime.datetime.now(),
    )

    new_af.cor_af_actor = [af_productor, af_contact]

    db.session.add(new_af)

    ds_desc_and_name = "Jeu de données personnel de {name} {surname}".format(
        name=user["nom_role"], surname=user["prenom_role"]
    )
    ds_productor = CorDatasetActor(
        id_role=user["id_role"],
        id_nomenclature_actor_role=func.ref_nomenclatures.get_id_nomenclature("ROLE_ACTEUR", "6"),
    )
    ds_contact = CorDatasetActor(
        id_role=user["id_role"],
        id_nomenclature_actor_role=func.ref_nomenclatures.get_id_nomenclature("ROLE_ACTEUR", "1"),
    )
    # add new JDD: terrestrial and marine = True as default
    new_dataset = TDatasets(
        acquisition_framework=new_af,
        dataset_name=ds_desc_and_name,
        dataset_shortname=ds_desc_and_name + " - auto-créé via la demande de création de compte",
        dataset_desc=ds_desc_and_name,
        marine_domain=True,
        terrestrial_domain=True,
    )
    new_dataset.cor_dataset_actor = [ds_productor, ds_contact]
    db.session.add(new_dataset)

    for module_code in current_app.config["ACCOUNT_MANAGEMENT"]["DATASET_MODULES_ASSOCIATION"]:
        module = TModules.query.filter_by(module_code=module_code).one_or_none()
        if module is None:
            warn("Module code '{}' does not exist, can not associate dataset.".format(module_code))
            continue
        new_dataset.modules.append(module)

    db.session.commit()


def inform_user(user):
    """
    Send an email to inform the user that his account was validate.
    """
    app_name = current_app.config["appName"]
    app_url = current_app.config["URL_APPLICATION"]
    text_addon = current_app.config["ACCOUNT_MANAGEMENT"]["ADDON_USER_EMAIL"]
    html_text_addon = Markup(text_addon)

    msg_html = render_template(
        "email_confirm_user_validation.html",
        user_firstname=user["prenom_role"],
        user_lastname=user["nom_role"],
        app_name=app_name,
        app_url=app_url,
        user_login=user["identifiant"],
        text_addon=html_text_addon,
    )
    subject = f"Confirmation inscription {app_name}"
    send_mail([user["email"]], subject, msg_html)


def send_email_for_recovery(data):
    """
    Send an email with the login of the role and the possibility to reset
    its password
    """
    user = data["role"]
    url_password = (
        current_app.config["URL_APPLICATION"] + "/#/login/new-password?token=" + data["token"]
    )

    msg_html = render_template(
        "email_login_and_new_pass.html",
        identifiant=user["identifiant"],
        url_password=url_password,
    )
    subject = "Confirmation changement Identifiant / mot de passe"
    send_mail([user["email"]], subject, msg_html)
    return {"msg": "ok"}


function_dict = {
    "create_temp_user": validate_temp_user,
    "valid_temp_user": execute_actions_after_validation,
    "create_cor_role_token": send_email_for_recovery,
}
