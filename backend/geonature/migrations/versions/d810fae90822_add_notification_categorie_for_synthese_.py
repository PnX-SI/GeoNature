"""add notification categorie for synthese export

Revision ID: d810fae90822
Revises: 67b70584ade0
Create Date: 2025-06-05 09:17:41.978947

"""

from alembic import op
import sqlalchemy as sa


# revision identifiers, used by Alembic.
revision = "d810fae90822"
down_revision = "67b70584ade0"
branch_labels = None
depends_on = None

CATEGORY_CODE = "SYNTHESE_EXPORT"
EMAIL_CONTENT = (
    "<p>Bonjour <i>{{ role.nom_complet }}</i> !</p>"
    '<p>L\'export synthese - {{export_name}}- a bien été réalisé, il est téléchargeable en cliquant sur ce  <a href="{{ url }}">ici</a>. </p>'
    "<p><i>Vous recevez cet email automatiquement via le service de notification de GeoNature.</i></p>"
)
DB_CONTENT = "L'export {{export_name}} a bien été réalisé"


def upgrade():
    conn = op.get_bind()
    metadata = sa.MetaData(bind=conn)
    notification_category = sa.Table(
        "bib_notifications_categories", metadata, schema="gn_notifications", autoload_with=conn
    )
    op.execute(
        sa.insert(notification_category).values(
            {
                "code": CATEGORY_CODE,
                "label": "Nouvel export généré dans la synthèse",
                "description": "Se déclenche lorsqu'un nouveau commentaire est ajouté à une de vos observations, ou une observation que vous avez commenté",
            }
        )
    )

    notification_template = sa.Table(
        "bib_notifications_templates", metadata, schema="gn_notifications", autoload_with=conn
    )
    op.execute(
        sa.insert(notification_template).values(
            [
                {"code_category": CATEGORY_CODE, "code_method": "EMAIL", "content": EMAIL_CONTENT},
                {"code_category": CATEGORY_CODE, "code_method": "DB", "content": DB_CONTENT},
            ]
        )
    )

    notification_rule = sa.Table(
        "t_notifications_rules", metadata, schema="gn_notifications", autoload_with=conn
    )
    op.execute(
        sa.insert(notification_rule).values(
            [
                {"code_category": CATEGORY_CODE, "code_method": "EMAIL"},
                {"code_category": CATEGORY_CODE, "code_method": "DB"},
            ]
        )
    )


def downgrade():
    conn = op.get_bind()
    metadata = sa.MetaData(bind=conn)
    notification_category = sa.Table(
        "bib_notifications_categories", metadata, schema="gn_notifications", autoload_with=conn
    )
    notification_template = sa.Table(
        "bib_notifications_templates", metadata, schema="gn_notifications", autoload_with=conn
    )
    notification_rule = sa.Table(
        "t_notifications_rules", metadata, schema="gn_notifications", autoload_with=conn
    )
    category = conn.execute(
        sa.select(notification_category).where(notification_category.c.code == CATEGORY_CODE)
    ).one()
    op.execute(
        sa.delete(notification_template).where(
            notification_template.c.code_category == category.code
        )
    )
    op.execute(
        sa.delete(notification_rule).where(notification_rule.c.code_category == category.code)
    )
    op.execute(
        sa.delete(notification_category).where(notification_category.c.code == CATEGORY_CODE)
    )
