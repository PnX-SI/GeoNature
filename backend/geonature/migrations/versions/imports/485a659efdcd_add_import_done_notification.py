"""add 'IMPORT-DONE' notification

Revision ID: 485a659efdcd
Revises: a11c9a2db7bb
Create Date: 2023-01-12 12:01:34.177079

"""
from alembic import op
import sqlalchemy as sa


# revision identifiers, used by Alembic.
revision = "485a659efdcd"
down_revision = "a11c9a2db7bb"
branch_labels = None
depends_on = ("36d0bd313a47",)

SCHEMA_NAME = "gn_notifications"


def upgrade():
    # Insert the notification category 'IMPORT-DONE'
    op.execute(
        f"""
    INSERT INTO {SCHEMA_NAME}.bib_notifications_categories 
    VALUES  ('IMPORT-DONE', 'Import en synthèse terminé', 'Se déclenche lorsqu’un de vos imports est terminé et correctement intégré à la synthèse')
    """
    )

    # Insert templates 'EMAIL' and 'DB' for the category 'IMPORT-DONE'
    op.execute(
        """
    INSERT INTO gn_notifications.bib_notifications_templates 
    VALUES  ('IMPORT-DONE', 'DB', '<b>Import n° {{ import.id_import }}</b> correctement terminé et intégré dans la synthèse')
    """
    )
    op.execute(
        """
    INSERT INTO gn_notifications.bib_notifications_templates 
    VALUES  ('IMPORT-DONE', 'EMAIL', '<p>Bonjour <i>{{ role.nom_complet }}</i> !</p> <p>Votre <a href="{{ url }}">import <b>n°{{ import.id_import }}</b></a> s’est terminé correctement {% if import.import_count == import.source_count %} 👌 et a été bien {% else %} 👍 mais a été partiellement {% endif %} intégré dans la synthèse.</p><p> {{ import.import_count }} / {{ import.source_count }} données ont pu être effectivement intégrées dans la synthèse.</p><hr><p><i>Vous recevez cet email automatiquement via le service de notification de GeoNature. <a href="{{url_notification_rules}}">Gestion de vos règles de notification</a>.</i></p>')
    """
    )


def downgrade():
    # First, remove the notifications rules corresponding to 'IMPORT-DONE'
    op.execute(
        f"""
    DELETE FROM {SCHEMA_NAME}.t_notifications_rules WHERE code_category = 'IMPORT-DONE'
    """
    )

    # Then, Remove the notifications templates corresponding to 'IMPORT-DONE'
    op.execute(
        f"""
    DELETE FROM {SCHEMA_NAME}.bib_notifications_templates WHERE code_category = 'IMPORT-DONE'
    """
    )

    # Lastly, Remove the notifications category 'IMPORT-DONE'
    op.execute(
        f"""
    DELETE FROM {SCHEMA_NAME}.bib_notifications_categories WHERE code = 'IMPORT-DONE'
    """
    )
