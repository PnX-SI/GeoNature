"""add_observers_txt_column_t_base_visit

Revision ID: 8309591841f3
Revises: f1dd984bff97
Create Date: 2023-10-06 11:07:43.532623

"""
from alembic import op
import sqlalchemy as sa


# revision identifiers, used by Alembic.
revision = "8309591841f3"
down_revision = "f1dd984bff97"
branch_labels = None
depends_on = None


monitorings_schema = "gn_monitoring"
table = "t_base_visits"
column = "observers_txt"


def upgrade():
    op.add_column(
        table,
        sa.Column(
            column,
            sa.Text(),
            nullable=True,
        ),
        schema=monitorings_schema,
    )


def downgrade():
    op.drop_column(table, column, schema=monitorings_schema)
