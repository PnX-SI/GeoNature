"""update notifications import-done to make them generic with respect to the destination

Revision ID: 02e9b8758709
Revises: 439dd64e9cd3
Create Date: 2024-01-23 16:10:58.149517

"""
from alembic import op
import sqlalchemy as sa


# revision identifiers, used by Alembic.
revision = "02e9b8758709"
down_revision = "439dd64e9cd3"
branch_labels = None
depends_on = None

ORIGINAL_TEMPLATE_DB = (
    "<b>Import n° {{ import.id_import }}</b> correctement terminé et intégré dans la synthèse"
)
ORIGINAL_TEMPLATE_MAIL = '<p>Bonjour <i>{{ role.nom_complet }}</i> !</p> <p>Votre <a href="{{ url }}">import <b>n°{{ import.id_import }}</b></a> s’est terminé correctement {% if import.import_count == import.source_count %} 👌 et a été bien {% else %} 👍 mais a été partiellement {% endif %} intégré dans la synthèse.</p><p> {{ import.import_count }} / {{ import.source_count }} données ont pu être effectivement intégrées dans la synthèse.</p><hr><p><i>Vous recevez cet email automatiquement via le service de notification de GeoNature. <a href="{{url_notification_rules}}">Gestion de vos règles de notification</a>.</i></p>'

NEW_TEMPLATE_DB = "<b>Import n° {{ import.id_import }}</b> terminé{% if import.errors|length > 0 %} 👍 et partiellement {% else %} 👌 et correctement {% endif %}intégré : {{ import.import_count }} entité{% if import.import_count > 1 %}s{% endif %} importée{% if import.import_count > 1 %}s{% endif %} dans la destination {{ destination.label }}"
NEW_TEMPLATE_MAIL = '<p>Bonjour <i>{{ role.nom_complet }}</i> !</p> <p>Votre <a href="{{ url }}">import <b>n°{{ import.id_import }}</b></a> est terminé {% if import.errors|length > 0 %} 👍 mais a été partiellement {% else %} 👌 et a été correctement {% endif %} intégré dans la destination {{ destination.label }}.</p><p> {{ import.import_count }} entité{% if import.import_count > 1 %}s valides ont{% else %} valide a{% endif %} pu être effectivement intégrée{% if import.import_count > 1 %}s{% endif %}.</p><hr><p><i>Vous recevez cet email automatiquement via le service de notification de GeoNature. <a href="{{url_notification_rules}}">Gestion de vos règles de notification</a>.</i></p>'


def upgrade():
    # Update templates 'EMAIL' and 'DB' for the category 'IMPORT-DONE', IF AND ONLY IF still equal to the original template from "485a659efdcd"
    op.execute(
        f"""
        UPDATE gn_notifications.bib_notifications_templates 
        SET content = '{NEW_TEMPLATE_DB}' 
        WHERE code_method = 'DB' AND code_category = 'IMPORT-DONE' AND content = '{ORIGINAL_TEMPLATE_DB}'
        """
    )
    op.execute(
        f"""
        UPDATE gn_notifications.bib_notifications_templates 
        SET content = '{NEW_TEMPLATE_MAIL}' 
        WHERE code_method = 'EMAIL' AND code_category = 'IMPORT-DONE' AND content = '{ORIGINAL_TEMPLATE_MAIL}'
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
