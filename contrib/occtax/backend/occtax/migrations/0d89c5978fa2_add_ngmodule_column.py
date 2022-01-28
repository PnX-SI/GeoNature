"""add ngmodule column

Revision ID: 0d89c5978fa2
Revises: 08cda6f29127
Create Date: 2022-01-27 14:21:10.342312

"""
from alembic import op
import sqlalchemy as sa


# revision identifiers, used by Alembic.
revision = '0d89c5978fa2'
down_revision = '944072911ff7'
branch_labels = None
depends_on = None


def upgrade():
    op.execute(
        """
            ALTER TABLE gn_commons.t_modules
            ADD column ng_module character varying(500)
        """
    )


def downgrade():
    op.execute(
        """
            ALTER TABLE gn_commons.t_modules
            DROP COLUMN ng_module
        """
    )
