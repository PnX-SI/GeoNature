"""add notification schema, tables and data

Revision ID: 36d0bd313a47
Revises: 42040535a20e
Create Date: 2022-09-22 09:58:19.055808

"""
import datetime
from alembic import op
from sqlalchemy import Column, ForeignKey, Integer, Unicode, UnicodeText, DateTime
from sqlalchemy.schema import UniqueConstraint
from utils_flask_sqla.migrations.utils import logger


# revision identifiers, used by Alembic.
revision = "36d0bd313a47"
down_revision = "2d7edda45dd4"
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
        Column("description", UnicodeText),
        schema=SCHEMA_NAME,
    )

    logger.info("Create table " + SCHEMA_NAME + ".bib_notifications_categories")
    bibNotificationsCategories = op.create_table(
        "bib_notifications_categories",
        Column("code", Unicode, primary_key=True),
        Column("label", Unicode),
        Column("description", UnicodeText),
        schema=SCHEMA_NAME,
    )

    logger.info("Create table " + SCHEMA_NAME + ".bib_notifications_templates")
    bibNotificationsTemplates = op.create_table(
        "bib_notifications_templates",
        Column(
            "code_category",
            Unicode,
            ForeignKey(SCHEMA_NAME + ".bib_notifications_categories.code"),
            primary_key=True,
        ),
        Column(
            "code_method",
            Unicode,
            ForeignKey(SCHEMA_NAME + ".bib_notifications_methods.code"),
            primary_key=True,
        ),
        Column("content", UnicodeText),
        schema=SCHEMA_NAME,
    )

    # Create notification tables
    logger.info("Create table " + SCHEMA_NAME + ".t_notifications")
    tNotifications = op.create_table(
        "t_notifications",
        Column("id_notification", Integer, primary_key=True),
        Column("id_role", Integer, ForeignKey("utilisateurs.t_roles.id_role"), nullable=False),
        Column("title", Unicode),
        Column("content", UnicodeText),
        Column("url", Unicode),
        Column("code_status", Unicode),
        Column("creation_date", DateTime, default=datetime.datetime.utcnow),
        schema=SCHEMA_NAME,
    )

    logger.info("Create table " + SCHEMA_NAME + ".t_notifications_rules")
    tNotificationsRules = op.create_table(
        "t_notifications_rules",
        Column("id", Integer, primary_key=True),
        Column("id_role", Integer, ForeignKey("utilisateurs.t_roles.id_role"), nullable=False),
        Column(
            "code_method",
            Unicode,
            ForeignKey(SCHEMA_NAME + ".bib_notifications_methods.code"),
            nullable=False,
        ),
        Column(
            "code_category",
            Unicode,
            ForeignKey(SCHEMA_NAME + ".bib_notifications_categories.code"),
            nullable=False,
        ),
        UniqueConstraint(
            "id_role", "code_method", "code_category", name="un_role_method_category"
        ),
        schema=SCHEMA_NAME,
    )

    # Populate information
    logger.info("Insertion des données méthodes")
    op.bulk_insert(
        bibNotificationsMethods,
        [
            {
                "code": "DB",
                "label": "Notification dans l'application",
                "description": "Sauvegarde des informations pour une visualistion dans l'application",
            },
            {
                "code": "EMAIL",
                "label": "Notification par email",
                "description": "Envoi des notifications par email",
            },
        ],
    )

    logger.info("Insertion des données catégories")
    op.bulk_insert(
        bibNotificationsCategories,
        [
            {
                "code": "VALIDATION-STATUS-CHANGED",
                "label": "Modification du statut d'une observation",
                "description": "Se déclenche en cas de modification du statut d'une de vos observations",
            },
            # exemple pour l'ajout d'un statut
            # {
            #    "code": "VALIDATION-STATUS-CHANGED-PROBABLE",
            #    "label": "Observation validée",
            #    "description": "Se déclenche en cas de passage à l'état 'Certain - très probable' d'une observation",
            # },
        ],
    )

    logger.info("Insertion des données template")
    op.bulk_insert(
        bibNotificationsTemplates,
        [
            {
                "code_category": "VALIDATION-STATUS-CHANGED",
                "code_method": "DB",
                "content": "Passage au statut <b>{{ status.mnemonique }}</b> pour votre observation <b>n°{{ synthese.id_synthese }}</b>",
            },
            # exemple pour l'ajout d'un statut
            # {
            #    "code_category": "VALIDATION-STATUS-CHANGED-PROBABLE",
            #    "code_method": "BDD",
            #    "content": "{% if status.mnemonique == 'Certain - très probable' %} Passage au statut <b>{{ status.mnemonique }}</b> pour l'observation <b>n°{{ synthese.id_synthese }}</b> {% endif %}",
            # },
            {
                "code_category": "VALIDATION-STATUS-CHANGED",
                "code_method": "EMAIL",
                "content": '<p>Bonjour {{ role.nom_complet }} !</p><p>Le statut de votre <a href="{{ url }}">observation {{ synthese.id_synthese }}</a> a été modifié en <b>{{ status.mnemonique }}</b>.</p><p>Vous recevez cet email automatiquement via le service de notification de GeoNature.</p>',
            },
        ],
    )


def downgrade():
    logger.info("DROP SCHEMA " + SCHEMA_NAME + " CASCADE")
    op.execute("DROP SCHEMA " + SCHEMA_NAME + " CASCADE")
