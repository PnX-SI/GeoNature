"""remove in_error column

Revision ID: 0e4f9da0e33f
Revises: 906231e8f8e0
Create Date: 2022-04-25 10:51:14.746232

"""
from alembic import op
import sqlalchemy as sa


# revision identifiers, used by Alembic.
revision = "0e4f9da0e33f"
down_revision = "906231e8f8e0"
branch_labels = None
depends_on = None


def upgrade():
    op.drop_column(
        schema="gn_imports",
        table_name="t_imports",
        column_name="in_error",
    )


def downgrade():
    op.add_column(
        schema="gn_imports",
        table_name="t_imports",
        column=sa.Column(
            "in_error",
            sa.Boolean,
        ),
    )
    op.execute(
        """
    UPDATE
        gn_imports.t_imports i
    SET
        in_error = EXISTS (
            SELECT * FROM gn_imports.t_user_errors err WHERE err.id_import = i.id_import
        )
    """
    )
