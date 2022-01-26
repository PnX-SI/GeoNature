"""add theme in module

Revision ID: 08cda6f29127
Revises: 944072911ff7
Create Date: 2022-01-26 19:43:21.055900

"""
from alembic import op
import sqlalchemy as sa


# revision identifiers, used by Alembic.
revision = '08cda6f29127'
down_revision = '944072911ff7'
branch_labels = None
depends_on = None


def upgrade():
    op.execute(
        """
            ALTER TABLE gn_commons.t_modules
            ADD column theme character varying(50)
        """
    )


def downgrade():
    op.execute(
        """
            ALTER TABLE gn_commons.t_modules
            DROP COLUMN theme
        """
    )
