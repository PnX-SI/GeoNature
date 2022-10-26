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
down_revision = "4b5478df71cb"
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
        Column("code", Unicode, primary_key=True),
        Column("label", Unicode),
        Column("description", Unicode),
        schema=SCHEMA_NAME,
    )

    logger.info("Create table " + SCHEMA_NAME + ".bib_notifications_categories")
    bibNotificationsCategories = op.create_table(
        "bib_notifications_categories",
        Column("code", Unicode, primary_key=True),
        Column("label", Unicode),
        Column("description", Unicode),
        schema=SCHEMA_NAME,
    )

    logger.info("Create table " + SCHEMA_NAME + ".bib_notifications_templates")
    bibNotificationsTemplates = op.create_table(
        "bib_notifications_templates",
        Column("code_category", Unicode, primary_key=True),
        Column("code_method", Unicode, primary_key=True),
        Column("content", Unicode),
        schema=SCHEMA_NAME,
    )

    # Create notification tables
    logger.info("Create table " + SCHEMA_NAME + ".t_notifications")
    tNotifications = op.create_table(
        "t_notifications",
        Column("id_notification", Integer, primary_key=True),
        Column("id_role", Integer, ForeignKey("utilisateurs.t_roles.id_role"), nullable=False),
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
        Column("id_role", Integer, ForeignKey("utilisateurs.t_roles.id_role"), nullable=False),
        Column(
            "code_method",
            Unicode,
            ForeignKey(SCHEMA_NAME + ".bib_notifications_methods.code"),
            nullable=False
        ),
        Column(
            "code_category",
            Unicode,
            ForeignKey(SCHEMA_NAME + ".bib_notifications_categories.code"),
            nullable=False
        ),
        schema=SCHEMA_NAME,
    )

    # Populate information
    logger.info("Insertion des données méthodes")
    op.bulk_insert(
        bibNotificationsMethods,
        [
            {
                "code": "BDD",
                "label": "Notification en base de données",
                "description": "Sauvegarde des informations en base de données",
            },
            {
                "code": "MAIL",
                "label": "Notification par mail",
                "description": "Envoi des notifications par mail",
            },
        ],
    )

    logger.info("Insertion des données catégories")
    op.bulk_insert(
        bibNotificationsCategories,
        [
            {
                "code": "VALIDATION-1",
                "label": "Modification du statut d'une observation",
                "description": "Se déclenche en cas de modification d'un statut d'observation ",
            },
            {
                "code": "VALIDATION-2",
                "label": "Observation validée",
                "description": "Se déclenche en cas du passage d'une observation en statut Validée",
            },
            {
                "code": "VALIDATION-3",
                "label": "Passage d'une observation au statut Probable",
                "description": "Se déclenche en cas du passage d'une observation en statut Probable",
            },
            {
                "code": "VALIDATION-4",
                "label": "Passage d'une observation au statut Douteux",
                "description": "Se déclenche en cas du passage d'une observation en statut Douteux",
            },
            {
                "code": "VALIDATION-5",
                "label": "Passage d'une observation au statut Invalide",
                "description": "Se déclenche en cas du passage d'une observation en statut Invalide",
            },
            {
                "code": "VALIDATION-6",
                "label": "Passage d'une observation au statut Non réalisable",
                "description": "Se déclenche en cas du passage d'une observation en statut Non réalisable",
            },
            {
                "code": "VALIDATION-7",
                "label": "Passage d'une observation au statut Inconnu",
                "description": "Se déclenche en cas du passage d'une observation en statut Inconnu",
            },
            {
                "code": "VALIDATION-8",
                "label": "Passage d'une observation au statut En attente de validation",
                "description": "Se déclenche en cas du passage d'une observation en statut En attente de validation",
            },
        ],
    )

    logger.info("Insertion des données template")
    op.bulk_insert(
        bibNotificationsTemplates,
        [
            {
                "code_category": "VALIDATION-1",
                "code_method": "BDD",
                "content": "Passage au statut <b>{{ mnemonique }}</b> pour l'observation <b>n°{{ id_synthese }}</b>",
            },
            {
                "code_category": "VALIDATION-2",
                "code_method": "BDD",
                "content": "Passage au statut <b>{{ mnemonique }}</b> pour l'observation <b>n°{{ id_synthese }}</b>",
            },
            {
                "code_category": "VALIDATION-3",
                "code_method": "BDD",
                "content": "Passage au statut <b>{{ mnemonique }}</b> pour l'observation <b>n°{{ id_synthese }}</b>",
            },
            {
                "code_category": "VALIDATION-4",
                "code_method": "BDD",
                "content": "Passage au statut <b>{{ mnemonique }}</b> pour l'observation <b>n°{{ id_synthese }}</b>",
            },
            {
                "code_category": "VALIDATION-5",
                "code_method": "BDD",
                "content": "Passage au statut <b>{{ mnemonique }}</b> pour l'observation <b>n°{{ id_synthese }}</b>",
            },
            {
                "code_category": "VALIDATION-6",
                "code_method": "BDD",
                "content": "Passage au statut <b>{{ mnemonique }}</b> pour l'observation <b>n°{{ id_synthese }}</b>",
            },
            {
                "code_category": "VALIDATION-7",
                "code_method": "BDD",
                "content": "Passage au statut <b>{{ mnemonique }}</b> pour l'observation <b>n°{{ id_synthese }}</b>",
            },
            {
                "code_category": "VALIDATION-8",
                "code_method": "BDD",
                "content": "Passage au statut <b>{{ mnemonique }}</b> pour l'observation <b>n°{{ id_synthese }}</b>",
            },
            {
                "code_category": "VALIDATION-1",
                "code_method": "MAIL",
                "content": '<p>Bonjour {{ name }}!</p><p>Le statut de l\'<a href="{{ url }}">observation {{ id_synthese }}</a> a été modifié en <b>{{ mnemonique}}</b>.</p><p>Vous recevez ce mail via le service de notification de geonature</p>',
            },
            {
                "code_category": "VALIDATION-2",
                "code_method": "MAIL",
                "content": '<p>Bonjour {{ name }}!</p><p>Le statut de l\'<a href="{{ url }}">observation {{ id_synthese }}</a> a été modifié en <b>{{ mnemonique}}</b>.</p><p>Vous recevez ce mail via le service de notification de geonature</p>',
            },
            {
                "code_category": "VALIDATION-3",
                "code_method": "MAIL",
                "content": '<p>Bonjour {{ name }}!</p><p>Le statut de l\'<a href="{{ url }}">observation {{ id_synthese }}</a> a été modifié en <b>{{ mnemonique}}</b>.</p><p>Vous recevez ce mail via le service de notification de geonature</p>',
            },
            {
                "code_category": "VALIDATION-4",
                "code_method": "MAIL",
                "content": '<p>Bonjour {{ name }}!</p><p>Le statut de l\'<a href="{{ url }}">observation {{ id_synthese }}</a> a été modifié en <b>{{ mnemonique}}</b>.</p><p>Vous recevez ce mail via le service de notification de geonature</p>',
            },
            {
                "code_category": "VALIDATION-5",
                "code_method": "MAIL",
                "content": '<p>Bonjour {{ name }}!</p><p>Le statut de l\'<a href="{{ url }}">observation {{ id_synthese }}</a> a été modifié en <b>{{ mnemonique}}</b>.</p><p>Vous recevez ce mail via le service de notification de geonature</p>',
            },
            {
                "code_category": "VALIDATION-6",
                "code_method": "MAIL",
                "content": '<p>Bonjour {{ name }}!</p><p>Le statut de l\'<a href="{{ url }}">observation {{ id_synthese }}</a> a été modifié en <b>{{ mnemonique}}</b>.</p><p>Vous recevez ce mail via le service de notification de geonature</p>',
            },
            {
                "code_category": "VALIDATION-7",
                "code_method": "MAIL",
                "content": '<p>Bonjour {{ name }}!</p><p>Le statut de l\'<a href="{{ url }}">observation {{ id_synthese }}</a> a été modifié en <b>{{ mnemonique}}</b>.</p><p>Vous recevez ce mail via le service de notification de geonature</p>',
            },
            {
                "code_category": "VALIDATION-8",
                "code_method": "MAIL",
                "content": '<p>Bonjour {{ name }}!</p><p>Le statut de l\'<a href="{{ url }}">observation {{ id_synthese }}</a> a été modifié en <b>{{ mnemonique}}</b>.</p><p>Vous recevez ce mail via le service de notification de geonature</p>',
            },
        ],
    )


def downgrade():

    logger.info("DROP SCHEMA " + SCHEMA_NAME + " CASCADE")
    op.execute("DROP SCHEMA " + SCHEMA_NAME + " CASCADE")
