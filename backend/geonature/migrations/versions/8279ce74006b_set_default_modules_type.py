"""set modules default type

Revision ID: 8279ce74006b
Revises: 5d65f9c93a32
Create Date: 2023-02-22 12:47:26.727855

"""

from alembic import op
import sqlalchemy as sa


# revision identifiers, used by Alembic.
revision = "8279ce74006b"
down_revision = "5d65f9c93a32"
branch_labels = None
depends_on = None


def upgrade():
    op.execute(
        """
        UPDATE
            gn_commons.t_modules
        SET
            type = 'base'
        WHERE
            type IS NULL
        """
    )
    op.alter_column(
        schema="gn_commons",
        table_name="t_modules",
        column_name="type",
        nullable=False,
        server_default="base",
    )


def downgrade():
    op.alter_column(
        schema="gn_commons",
        table_name="t_modules",
        column_name="type",
        nullable=True,
        server_default=None,
    )
    op.execute(
        """
        UPDATE
            gn_commons.t_modules
        SET
            type = NULL
        WHERE
            type = 'base'
        """
    )
