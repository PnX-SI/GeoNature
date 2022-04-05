"""add ngmodule column in t_modules

Revision ID: 42040535a20e
Revises: ca0fe5d21ea2
Create Date: 2022-04-05 16:22:57.078076

"""
from alembic import op
import sqlalchemy as sa


# revision identifiers, used by Alembic.
revision = "42040535a20e"
down_revision = "ca0fe5d21ea2"
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
