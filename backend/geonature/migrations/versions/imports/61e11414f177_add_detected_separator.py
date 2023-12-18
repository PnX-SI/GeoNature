"""add detected separator

Revision ID: 61e11414f177
Revises: 0e4f9da0e33f
Create Date: 2022-04-14 14:03:41.842620

"""
from alembic import op
import sqlalchemy as sa


# revision identifiers, used by Alembic.
revision = "61e11414f177"
down_revision = "0e4f9da0e33f"
branch_labels = None
depends_on = None


def upgrade():
    op.add_column(
        schema="gn_imports",
        table_name="t_imports",
        column=sa.Column(
            "detected_separator",
            sa.Unicode,
        ),
    )


def downgrade():
    op.drop_column(
        schema="gn_imports",
        table_name="t_imports",
        column_name="detected_separator",
    )
