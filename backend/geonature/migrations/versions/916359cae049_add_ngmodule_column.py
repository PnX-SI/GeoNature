"""add ngmodule column

Revision ID: 916359cae049
Revises: 31f4fab360c1
Create Date: 2022-02-01 10:10:42.664284

"""
from alembic import op
import sqlalchemy as sa


# revision identifiers, used by Alembic.
revision = '916359cae049'
down_revision = '31f4fab360c1'
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