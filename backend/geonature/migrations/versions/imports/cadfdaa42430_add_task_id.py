"""add task_uuid

Revision ID: cadfdaa42430
Revises: 627b7968a55b
Create Date: 2022-05-16 14:34:03.746276

"""

from alembic import op
import sqlalchemy as sa


# revision identifiers, used by Alembic.
revision = "cadfdaa42430"
down_revision = "627b7968a55b"
branch_labels = None
depends_on = None


def upgrade():
    op.add_column(
        schema="gn_imports",
        table_name="t_imports",
        column=sa.Column(
            "task_id",
            sa.String(155),
        ),
    )


def downgrade():
    op.drop_column(
        schema="gn_imports",
        table_name="t_imports",
        column_name="task_id",
    )
