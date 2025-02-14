"""add comment notification

Revision ID: 95acee9f0452
Revises: 9e9218653d6c
Create Date: 2023-04-06 19:02:39.863972

"""

import sqlalchemy as sa
from alembic import op

# revision identifiers, used by Alembic.
revision = "95acee9f0452"
down_revision = "e2a94808cf76"
branch_labels = None
depends_on = ("09a637f06b96",)  # Geonature Notifications

CATEGORY_CODE = "OBSERVATION-COMMENT"
EMAIL_CONTENT = (
    "<p>Bonjour <i>{{ role.nom_complet }}</i> !</p>"
    "<p>{{ user.nom_complet }} a commenté l'observation de {{ synthese.nom_cite }} du {{ synthese.meta_create_date.strftime('%d-%m-%Y') }}"
    "que vous avez créée ou commentée</p>"
    '<p>Vous pouvez y accéder directement <a href="{{ url }}">ici</a></p>'
    "<p><i>Vous recevez cet email automatiquement via le service de notification de GeoNature.</i></p>"
)
DB_CONTENT = (
    "{{ user.nom_complet }} a commenté l'observation de {{ synthese.nom_cite }} du "
    "{{ synthese.meta_create_date.strftime('%d-%m-%Y') }} que vous avez créée ou commentée"
)


def upgrade():
    conn = op.get_bind()
    metadata = sa.MetaData(bind=conn)

    # Add category
    notification_category = sa.Table(
        "bib_notifications_categories", metadata, schema="gn_notifications", autoload_with=conn
    )
    op.execute(
        sa.insert(notification_category).values(
            {
                "code": CATEGORY_CODE,
                "label": "Nouveau commentaire sur une observation",
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
