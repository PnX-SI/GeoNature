"""additional fields: add datalist widget

Revision ID: 77a3bc6628d2
Revises: 74908bad752e
Create Date: 2022-04-27 17:00:38.070394

"""

from alembic import op
import sqlalchemy as sa


# revision identifiers, used by Alembic.
revision = "77a3bc6628d2"
down_revision = "74908bad752e"
branch_labels = None
depends_on = None


def upgrade():
    op.execute(
        """
        INSERT INTO gn_commons.bib_widgets (widget_name)
        VALUES('datalist');
        """
    )


def downgrade():
    op.execute(
        """
        DELETE FROM gn_commons.bib_widgets
        WHERE widget_name = 'datalist';
        """
    )
