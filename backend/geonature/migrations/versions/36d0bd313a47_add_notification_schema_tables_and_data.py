"""add notification schema, tables and data

Revision ID: 36d0bd313a47
Revises: 42040535a20e
Create Date: 2022-09-22 09:58:19.055808

"""
import datetime
from alembic import op
from sqlalchemy import Column, ForeignKey, Integer, Unicode, DateTime
from utils_flask_sqla.migrations.utils import logger


# revision identifiers, used by Alembic.
revision = "36d0bd313a47"
down_revision = "42040535a20e"
branch_labels = None
depends_on = None

SCHEMA_NAME = "gn_notifications"


def upgrade():

    # Create new schema
    logger.info("Create schema " + SCHEMA_NAME)
    op.execute("CREATE SCHEMA " + SCHEMA_NAME)

    # Create references tables
    logger.info("Create table " + SCHEMA_NAME + ".bib_notifications_methods")
    bibNotificationsMethods = op.create_table(
        "bib_notifications_methods",
        Column("code_notification_method", Unicode, primary_key=True),
        Column("label_notification_method", Unicode),
        Column("description_notification_method", Unicode),
        schema=SCHEMA_NAME,
    )

    logger.info("Create table " + SCHEMA_NAME + ".bib_notifications_categories")
    bibNotificationsCategories = op.create_table(
        "bib_notifications_categories",
        Column("code_notification_category", Unicode, primary_key=True),
        Column("label_notification_category", Unicode),
        Column("description_notification_category", Unicode),
        schema=SCHEMA_NAME,
    )

    logger.info("Create table " + SCHEMA_NAME + ".bib_notifications_templates")
    bibNotificationsTemplates = op.create_table(
        "bib_notifications_templates",
        Column("notification_template_category", Unicode, primary_key=True),
        Column("notification_template_method", Unicode, primary_key=True),
        Column("notification_template_content", Unicode),
        schema=SCHEMA_NAME,
    )

    # Create notification tables
    logger.info("Create table " + SCHEMA_NAME + ".t_notifications")
    tNotifications = op.create_table(
        "t_notifications",
        Column("id_notification", Integer, primary_key=True),
        Column("id_role", Integer, ForeignKey("utilisateurs.t_roles.id_role")),
        Column("title", Unicode),
        Column("content", Unicode),
        Column("url", Unicode),
        Column("code_status", Unicode),
        Column("creation_date", DateTime, default=datetime.datetime.utcnow),
        schema=SCHEMA_NAME,
    )

    logger.info("Create table " + SCHEMA_NAME + ".t_notifications_rules")
    tNotificationsRules = op.create_table(
        "t_notifications_rules",
        Column("id_notification_rules", Integer, primary_key=True),
        Column("id_role", Integer, ForeignKey("utilisateurs.t_roles.id_role")),
        Column(
            "code_notification_method",
            Unicode,
            ForeignKey(SCHEMA_NAME + ".bib_notifications_methods.code_notification_method"),
        ),
        Column(
            "code_notification_category",
            Unicode,
            ForeignKey(SCHEMA_NAME + ".bib_notifications_categories.code_notification_category"),
        ),
        schema=SCHEMA_NAME,
    )

    # Populate information
    logger.info("Insertion des données")
    op.bulk_insert(
        bibNotificationsMethods,
        [
            {
                "code_notification_method": "BDD",
                "label_notification_method": "Notification en base de données",
                "description_notification_method": "Sauvegarde des informations en base de données",
            },
            {
                "code_notification_method": "MAIL",
                "label_notification_method": "Notification par mail",
                "description_notification_method": "Envoi des notifications par mail",
            },
        ],
    )

    op.bulk_insert(
        bibNotificationsCategories,
        [
            {
                "code_notification_category": "VALIDATION-1",
                "label_notification_category": "Modification du statut d'une observation",
                "description_notification_category": "Se déclenche en cas de modification d'un statut d'observation ",
            },
            {
                "code_notification_category": "VALIDATION-2",
                "label_notification_category": "Observation validée",
                "description_notification_category": "Se déclenche en cas du passage d'une observation en statut Validée",
            },
            {
                "code_notification_category": "VALIDATION-3",
                "label_notification_category": "Passage d'une observation au statut Probable",
                "description_notification_category": "Se déclenche en cas du passage d'une observation en statut Probable",
            },
            {
                "code_notification_category": "VALIDATION-4",
                "label_notification_category": "Passage d'une observation au statut Douteux",
                "description_notification_category": "Se déclenche en cas du passage d'une observation en statut Douteux",
            },
            {
                "code_notification_category": "VALIDATION-5",
                "label_notification_category": "Passage d'une observation au statut Invalide",
                "description_notification_category": "Se déclenche en cas du passage d'une observation en statut Invalide",
            },
            {
                "code_notification_category": "VALIDATION-6",
                "label_notification_category": "Passage d'une observation au statut Non réalisable",
                "description_notification_category": "Se déclenche en cas du passage d'une observation en statut Non réalisable",
            },
            {
                "code_notification_category": "VALIDATION-7",
                "label_notification_category": "Passage d'une observation au statut Inconnu",
                "description_notification_category": "Se déclenche en cas du passage d'une observation en statut Inconnu",
            },
            {
                "code_notification_category": "VALIDATION-8",
                "label_notification_category": "Passage d'une observation au statut En attente de validation",
                "description_notification_category": "Se déclenche en cas du passage d'une observation en statut En attente de validation",
            },
        ],
    )

    op.bulk_insert(
        bibNotificationsTemplates,
        [
            {
                "notification_template_category": "VALIDATION-1",
                "notification_template_method": "BDD",
                "notification_template_content": "Passage au statut <b>{{ mnemonique }}</b> pour l'observation <b>n°{{ id_synthese }}</b>",
            },
            {
                "notification_template_category": "VALIDATION-2",
                "notification_template_method": "BDD",
                "notification_template_content": "Passage au statut <b>{{ mnemonique }}</b> pour l'observation <b>n°{{ id_synthese }}</b>",
            },
            {
                "notification_template_category": "VALIDATION-3",
                "notification_template_method": "BDD",
                "notification_template_content": "Passage au statut <b>{{ mnemonique }}</b> pour l'observation <b>n°{{ id_synthese }}</b>",
            },
            {
                "notification_template_category": "VALIDATION-4",
                "notification_template_method": "BDD",
                "notification_template_content": "Passage au statut <b>{{ mnemonique }}</b> pour l'observation <b>n°{{ id_synthese }}</b>",
            },
            {
                "notification_template_category": "VALIDATION-5",
                "notification_template_method": "BDD",
                "notification_template_content": "Passage au statut <b>{{ mnemonique }}</b> pour l'observation <b>n°{{ id_synthese }}</b>",
            },
            {
                "notification_template_category": "VALIDATION-6",
                "notification_template_method": "BDD",
                "notification_template_content": "Passage au statut <b>{{ mnemonique }}</b> pour l'observation <b>n°{{ id_synthese }}</b>",
            },
            {
                "notification_template_category": "VALIDATION-7",
                "notification_template_method": "BDD",
                "notification_template_content": "Passage au statut <b>{{ mnemonique }}</b> pour l'observation <b>n°{{ id_synthese }}</b>",
            },
            {
                "notification_template_category": "VALIDATION-8",
                "notification_template_method": "BDD",
                "notification_template_content": "Passage au statut <b>{{ mnemonique }}</b> pour l'observation <b>n°{{ id_synthese }}</b>",
            },
            {
                "notification_template_category": "VALIDATION-1",
                "notification_template_method": "MAIL",
                "notification_template_content": '<p>Bonjour {{ name }}!</p><p>Le statut de l\'<a href="{{ url }}">observation {{ id_synthese }}</a> a été modifié en <b>{{ mnemonique}}</b>.</p><p>Vous recevez ce mail via le service de notification de geonature</p>',
            },
            {
                "notification_template_category": "VALIDATION-2",
                "notification_template_method": "MAIL",
                "notification_template_content": '<p>Bonjour {{ name }}!</p><p>Le statut de l\'<a href="{{ url }}">observation {{ id_synthese }}</a> a été modifié en <b>{{ mnemonique}}</b>.</p><p>Vous recevez ce mail via le service de notification de geonature</p>',
            },
            {
                "notification_template_category": "VALIDATION-3",
                "notification_template_method": "MAIL",
                "notification_template_content": '<p>Bonjour {{ name }}!</p><p>Le statut de l\'<a href="{{ url }}">observation {{ id_synthese }}</a> a été modifié en <b>{{ mnemonique}}</b>.</p><p>Vous recevez ce mail via le service de notification de geonature</p>',
            },
            {
                "notification_template_category": "VALIDATION-4",
                "notification_template_method": "MAIL",
                "notification_template_content": '<p>Bonjour {{ name }}!</p><p>Le statut de l\'<a href="{{ url }}">observation {{ id_synthese }}</a> a été modifié en <b>{{ mnemonique}}</b>.</p><p>Vous recevez ce mail via le service de notification de geonature</p>',
            },
            {
                "notification_template_category": "VALIDATION-5",
                "notification_template_method": "MAIL",
                "notification_template_content": '<p>Bonjour {{ name }}!</p><p>Le statut de l\'<a href="{{ url }}">observation {{ id_synthese }}</a> a été modifié en <b>{{ mnemonique}}</b>.</p><p>Vous recevez ce mail via le service de notification de geonature</p>',
            },
            {
                "notification_template_category": "VALIDATION-6",
                "notification_template_method": "MAIL",
                "notification_template_content": '<p>Bonjour {{ name }}!</p><p>Le statut de l\'<a href="{{ url }}">observation {{ id_synthese }}</a> a été modifié en <b>{{ mnemonique}}</b>.</p><p>Vous recevez ce mail via le service de notification de geonature</p>',
            },
            {
                "notification_template_category": "VALIDATION-7",
                "notification_template_method": "MAIL",
                "notification_template_content": '<p>Bonjour {{ name }}!</p><p>Le statut de l\'<a href="{{ url }}">observation {{ id_synthese }}</a> a été modifié en <b>{{ mnemonique}}</b>.</p><p>Vous recevez ce mail via le service de notification de geonature</p>',
            },
            {
                "notification_template_category": "VALIDATION-8",
                "notification_template_method": "MAIL",
                "notification_template_content": '<p>Bonjour {{ name }}!</p><p>Le statut de l\'<a href="{{ url }}">observation {{ id_synthese }}</a> a été modifié en <b>{{ mnemonique}}</b>.</p><p>Vous recevez ce mail via le service de notification de geonature</p>',
            },
        ],
    )


def downgrade():

    logger.info("DROP SCHEMA " + SCHEMA_NAME + " CASCADE")
    op.execute("DROP SCHEMA " + SCHEMA_NAME + " CASCADE")
