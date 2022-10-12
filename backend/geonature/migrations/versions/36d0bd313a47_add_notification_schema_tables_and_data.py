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

    logger.info("Create table " + SCHEMA_NAME + ".bib_notifications_status")
    bibNotificationsStatus = op.create_table(
        "bib_notifications_status",
        Column("code_notification_status", Unicode, primary_key=True),
        Column("label_notification_status", Unicode),
        Column("description_notification_status", Unicode),
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
        Column(
            "code_status",
            Unicode,
            ForeignKey(SCHEMA_NAME + ".bib_notifications_status.code_notification_status"),
        ),
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
                "description_notification_category": "Categorie a utiliser en cas de modification d'un statut d'observation ",
            },
            {
                "code_notification_category": "VALIDATION-2",
                "label_notification_category": "Suppresion d'une observation",
                "description_notification_category": "Categorie a utiliser en cas de suppression d'une observation",
            },
        ],
    )

    op.bulk_insert(
        bibNotificationsStatus,
        [
            {
                "code_notification_status": "UNREAD",
                "label_notification_status": "Non lu",
                "description_notification_status": "Notification pas encore lu par l'utilisateur",
            },
            {
                "code_notification_status": "READ",
                "label_notification_status": "lu",
                "description_notification_status": "Notification lu par l'utilisateur",
            },
        ],
    )

    op.bulk_insert(
        bibNotificationsTemplates,
        [
            {
                "notification_template_category": "VALIDATION-1",
                "notification_template_method": "MAIL",
                "notification_template_content": '<p>Bonjour {{ name }}!</p><p>Le statut de l\'observation <a href="{{ url }}"></a>{{ observation }}</a> a été modifié.</p><p>Vous recevez ce mail via le service de notification de geonature</p>',
            }
        ],
    )


def downgrade():

    logger.info("DROP SCHEMA " + SCHEMA_NAME + " CASCADE")
    op.execute("DROP SCHEMA " + SCHEMA_NAME + " CASCADE")
