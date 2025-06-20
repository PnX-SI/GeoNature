"""[notifications] Rename import notifications category

Revision ID: a7f95c66819a
Revises: d07958b2b7e0
Create Date: 2025-06-20 10:20:24.605193

"""

from alembic import op
import sqlalchemy as sa


# revision identifiers, used by Alembic.
revision = "a7f95c66819a"
down_revision = "d07958b2b7e0"
branch_labels = None
depends_on = None


def upgrade():
    op.execute(
        """
    UPDATE gn_notifications.bib_notifications_categories 
    SET label = 'Import terminée',
    description ='Se déclenche lorsqu’un de vos imports est terminé et correctement intégré'
    WHERE code = 'IMPORT-DONE';
    """
    )


def downgrade():
    op.execute(
        """
    UPDATE gn_notifications.bib_notifications_categories
    SET label = 'Import en synthèse terminé',
    description ='Se déclenche lorsqu’un de vos imports est terminé et correctement intégré à la synthèse'
    WHERE code = 'IMPORT-DONE';
    """
    )
