"""drop import_count column

Revision ID: 7b6a578eccd7
Revises: c49474d2f1f7
Create Date: 2024-10-18 16:24:44.145501

"""

from alembic import op
import sqlalchemy as sa


# revision identifiers, used by Alembic.
revision = "7b6a578eccd7"
down_revision = "c49474d2f1f7"
branch_labels = None
depends_on = None


def upgrade():
    op.drop_column(
        schema="gn_imports",
        table_name="t_imports",
        column_name="import_count",
    )


def downgrade():
    op.add_column(
        schema="gn_imports",
        table_name="t_imports",
        column=sa.Column(
            "import_count",
            sa.Integer,
        ),
    )
