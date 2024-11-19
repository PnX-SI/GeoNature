"""import schema

Revision ID: 92f0083cf735
Revises: ebbe0f7ed866
Create Date: 2023-11-07 16:06:36.745188

"""

from alembic import op
import sqlalchemy as sa


# revision identifiers, used by Alembic.
revision = "92f0083cf735"
down_revision = "ebbe0f7ed866"
branch_labels = None
depends_on = ("2b0b3bd0248c",)


def upgrade():
    op.execute(
        """
        UPDATE
            gn_commons.t_modules
        SET
            type = 'synthese'
        WHERE
            module_code = 'SYNTHESE'
        """
    )


def downgrade():
    op.execute(
        """
        UPDATE
            gn_commons.t_modules
        SET
            type = 'base'
        WHERE
            module_code = 'SYNTHESE'
        """
    )
