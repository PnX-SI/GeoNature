"""update_notifications_import

Revision ID: 9df933cc3c7a
Revises: 6734d8f7eb2a
Create Date: 2025-01-09 15:57:37.476537

"""

from alembic import op
import sqlalchemy as sa


# revision identifiers, used by Alembic.
revision = "9df933cc3c7a"
down_revision = "6734d8f7eb2a"
branch_labels = None
depends_on = None


ORIGINAL_TEMPLATE_DB = (
    "<b>Import n° {{ import.id_import }}</b> correctement terminé et intégré dans la synthèse"
)
ORIGINAL_TEMPLATE_MAIL = """<p>Bonjour <i>{{ role.nom_complet }}</i> !</p> <p>Votre <a href="{{ url }}">import <b>n°{{ import.id_import }}</b></a> s’est terminé correctement {% if import.statistics["import_count"] == import.source_count %} 👌 et a été bien {% else %} 👍 mais a été partiellement {% endif %} intégré dans la synthèse.</p><p> {{ import.statistics["import_count"] }} / {{ import.source_count }} données ont pu être effectivement intégrées dans la synthèse.</p><hr><p><i>Vous recevez cet email automatiquement via le service de notification de GeoNature. <a href="{{url_notification_rules}}">Gestion de vos règles de notification</a>.</i></p>"""

NEW_TEMPLATE_DB = """<b>Import n° {{ import.id_import }}</b> terminé{% if import.errors|length > 0 %}👍 et partiellement {% else %} 👌 et correctement {% endif %}intégré : {{ import.statistics["nb_line_valid"] }} / {{ import.source_count }} ligne{% if import.statistics["nb_line_valid"] > 1 %}s ont{% else %} a{% endif %} pu être effectivement intégrée{% if import.statistics["nb_line_valid"] > 1 %}s{% endif %}."""
NEW_TEMPLATE_MAIL = """<p>Bonjour <i>{{ role.prenom_role }} {{ role.nom_role }}</i> !</p> <p>Votre <a href="{{ url }}">import <b>n°{{ import.id_import }}</b></a> est terminé {% if import.errors|length > 0 %} 👍 mais a été partiellement {% else %} 👌 et a été correctement {% endif %} intégré dans la destination {{ destination.label }}.</p><p> {{ import.statistics["nb_line_valid"] }} / {{ import.source_count }} ligne{% if import.statistics["nb_line_valid"] > 1 %}s ont{% else %} a{% endif %} pu être effectivement intégrée{% if import.statistics["nb_line_valid"] > 1 %}s{% endif %}.</p><hr><p><i>Vous recevez cet email automatiquement via le service de notification de GeoNature. <a href="{{url_notification_rules}}">Gestion de vos règles de notification</a>.</i></p>"""


def upgrade():
    # Update templates 'EMAIL' and 'DB' for the category 'IMPORT-DONE', IF AND ONLY IF still equal to the original template from "485a659efdcd"
    op.execute(
        f"""
        UPDATE gn_notifications.bib_notifications_templates 
        SET content = '{NEW_TEMPLATE_DB}' 
        WHERE code_method = 'DB' AND code_category = 'IMPORT-DONE'
        """
    )
    op.execute(
        f"""
        UPDATE gn_notifications.bib_notifications_templates 
        SET content = '{NEW_TEMPLATE_MAIL}' 
        WHERE code_method = 'EMAIL' AND code_category = 'IMPORT-DONE'
        """
    )


def downgrade():
    # Set back to the original templates
    op.execute(
        f"""
        UPDATE gn_notifications.bib_notifications_templates 
        SET content = '{ORIGINAL_TEMPLATE_DB}' 
        WHERE code_method = 'DB' AND code_category = 'IMPORT-DONE'
        """
    )
    op.execute(
        f"""
        UPDATE gn_notifications.bib_notifications_templates 
        SET content = '{ORIGINAL_TEMPLATE_MAIL}' 
        WHERE code_method = 'EMAIL' AND code_category = 'IMPORT-DONE'
        """
    )
