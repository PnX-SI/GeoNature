"""
Action triggered after register action (create temp user, change password etc...)
"""
import datetime

from flask import render_template, current_app, url_for
from pypnusershub.db.models import Application, User
from pypnusershub.db.models_register import TempUser
from sqlalchemy.sql import func


from geonature.core.gn_meta.models import (
    TDatasets,
    TAcquisitionFramework,
    CorDatasetActor,
)
from geonature.utils.utilsmails import send_mail
from geonature.utils.env import DB


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
    url_validation = url_for("users.confirmation", token=user.token_role)
    msg_html = render_template(template, url_validation=url_validation, user=user)

    send_mail(recipients, subject, msg_html)

    return {"msg": "ok"}


def create_dataset_user(user):
    """
        After dataset validation, add a personnal AF and JDD so the user can add new user
    """
    print("POST DATASET USE")
    print(user)
    af_desc_and_name = "Cadre d'acquisition personnel de {name} {surname}".format(
        name=user["nom_role"], surname=user["prenom_role"]
    )
    new_af = TAcquisitionFramework(
        acquisition_framework_name=af_desc_and_name,
        acquisition_framework_desc=af_desc_and_name
        + " - auto-créé via la demande de création de compte",
        acquisition_framework_start_date=datetime.datetime.now(),
    )

    DB.session.add(new_af)
    DB.session.commit()
    print("LAAAAAAAAA")
    print(new_af)
    print(new_af.id_acquisition_framework)

    ds_desc_and_name = "Jeu de données personnel de {name} {surname}".format(
        name=user["nom_role"], surname=user["prenom_role"]
    )
    actor = CorDatasetActor(
        id_role=user["id_role"],
        id_nomenclature_actor_role=func.ref_nomenclatures.get_id_nomenclature(
            "ROLE_ACTEUR", "1"
        ),
    )
    # add new JDD: terrestrial and marine = True as default
    new_dataset = TDatasets(
        id_acquisition_framework=new_af.id_acquisition_framework,
        dataset_name=ds_desc_and_name,
        dataset_shortname=ds_desc_and_name
        + " - auto-créé via la demande de création de compte",
        dataset_desc=ds_desc_and_name,
        marine_domain=True,
        terrestrial_domain=True,
    )
    new_dataset.cor_dataset_actor.append(actor)
    DB.session.add(new_dataset)
    DB.session.commit()
    return {"msg": "ok"}


if current_app.config["REGISTER"]["AUTO_DATASET_CREATION"]:
    function_dict = {
        "create_temp_user": validate_temp_user,
        "valid_temp_user": create_dataset_user,
    }
else:
    function_dict = {"create_temp_user": validate_temp_user}

