"""add comment notification

Revision ID: 95acee9f0452
Revises: 9e9218653d6c
Create Date: 2023-04-06 19:02:39.863972

"""
import sqlalchemy as sa
from alembic import op

from geonature.core.notifications.models import (
    NotificationCategory,
    NotificationRule,
    NotificationTemplate,
)

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
    bind = op.get_bind()
    session = sa.orm.Session(bind=bind)

    # Add category
    category = NotificationCategory(
        code=CATEGORY_CODE,
        label="Nouveau commentaire sur une observation",
        description=(
            "Se déclenche lorsqu'un nouveau commentaire est ajouté à une de vos observations, ou une observation que vous avez commenté"
        ),
    )

    session.add(category)

    for method, content in (("EMAIL", EMAIL_CONTENT), ("DB", DB_CONTENT)):
        template = NotificationTemplate(category=category, code_method=method, content=content)
        session.add(template)

    session.commit()

    op.execute(
        f"""
        INSERT INTO 
            gn_notifications.t_notifications_rules (code_category, code_method)
        VALUES
            ('{CATEGORY_CODE}', 'DB'),
            ('{CATEGORY_CODE}', 'EMAIL')
        """
    )


def downgrade():
    bind = op.get_bind()
    session = sa.orm.Session(bind=bind)
    # Do not use NotificationCategory.query as it is not the same session!
    category = (
        session.query(NotificationCategory)
        .filter(NotificationCategory.code == CATEGORY_CODE)
        .one_or_none()
    )

    if category is not None:
        session.query(NotificationRule).filter(
            NotificationRule.code_category == category.code
        ).delete()
        # Since there is no cascade, need to delete template manually
        session.query(NotificationTemplate).filter(
            NotificationTemplate.code_category == category.code
        ).delete()

        session.delete(category)
        session.commit()

    op.execute(
        f"""
        DELETE FROM
            gn_notifications.t_notifications_rules
        WHERE
            code_category = '{CATEGORY_CODE}'
        AND
            id_role IS NULL
        """
    )
