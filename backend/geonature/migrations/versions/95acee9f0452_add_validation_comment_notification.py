"""add_validation_comment_notification

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
down_revision = "9e9218653d6c"
branch_labels = None
depends_on = None

CATEGORY_CODE = "VALIDATION-NEW-COMMENT"


def upgrade():
    bind = op.get_bind()
    session = sa.orm.Session(bind=bind)

    # Add category
    category = NotificationCategory(
        code=CATEGORY_CODE,
        label="Nouveau commentaire dans une discussion sur une observation",
        description=(
            "Se déclenche lorsqu'un nouveau commentaire "
            "est ajouté dans une discussion de validation"
        ),
    )

    session.add(category)

    # Add template
    email_content = """ <p>Bonjour <i>{{ role.nom_complet }}</i> !</p> 
    <p>{{ user.nom_complet }} a commenté votre observation de {{ synthese.nom_cite }} du {{ synthese.meta_create_date.strftime('%d-%m-%Y') }}</p>
    <p>Vous pouvez y accéder directement <a href="{{ url }}">ici</a></p>
    <p><i>Vous recevez cet email automatiquement via le service de notification de GeoNature.</i></p>
    """
    db_content = """ {{ user.nom_complet }} a commenté votre observation 
    de {{ synthese.nom_cite }} du {{ synthese.meta_create_date.strftime('%d-%m-%Y') }}
    """

    for method, content in (("EMAIL", email_content), ("DB", db_content)):
        template = NotificationTemplate(category=category, code_method=method, content=content)
        session.add(template)

    session.commit()


def downgrade():
    bind = op.get_bind()
    session = sa.orm.Session(bind=bind)
    # Do not use NotificationCategory.query as it is not the same session!
    category = (
        session.query(NotificationCategory)
        .filter(NotificationCategory.code == CATEGORY_CODE)
        .one()
    )

    if category:
        session.query(NotificationRule).filter(
            NotificationRule.code_category == category.code
        ).delete()
        # Since there is no cascade, need to delete template manually
        session.query(NotificationTemplate).filter(
            NotificationTemplate.code_category == category.code
        ).delete()

        session.delete(category)
        session.commit()
