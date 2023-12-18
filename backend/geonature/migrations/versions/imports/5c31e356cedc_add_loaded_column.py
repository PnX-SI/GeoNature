"""add loaded column

Revision ID: 5c31e356cedc
Revises: 0ff8fc0b4233
Create Date: 2022-06-22 12:58:31.609964

"""

from alembic import op
import sqlalchemy as sa
from sqlalchemy.sql import expression


# revision identifiers, used by Alembic.
revision = "5c31e356cedc"
down_revision = "0ff8fc0b4233"
branch_labels = None
depends_on = None


def upgrade():
    op.add_column(
        schema="gn_imports",
        table_name="t_imports",
        column=sa.Column("loaded", sa.Boolean, nullable=False, server_default=expression.false()),
    )
    op.execute(
        """
    UPDATE
        gn_imports.t_imports
    SET
        loaded = TRUE
    WHERE
        source_count > 0
    """
    )
    op.alter_column(
        schema="gn_imports",
        table_name="t_imports",
        column_name="processing",
        new_column_name="processed",
        nullable=False,
    )


def downgrade():
    op.alter_column(
        schema="gn_imports",
        table_name="t_imports",
        column_name="processed",
        new_column_name="processing",
        nullable=True,
    )
    op.drop_column(
        schema="gn_imports",
        table_name="t_imports",
        column_name="loaded",
    )
