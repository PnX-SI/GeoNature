"""add start_on to permissions

Add an optional start date to permissions. A permission is only considered
active once this date is reached (in addition to the existing expiration and
validation checks). A null start_on means the permission is active as soon
as it is validated, preserving the previous behaviour.

Revision ID: 17929040cac1
Revises: f6a1feb3f297
Create Date: 2026-06-01 00:00:00.000000

"""

from alembic import op
import sqlalchemy as sa
from sqlalchemy import Column, DateTime


# revision identifiers, used by Alembic.
revision = "17929040cac1"
down_revision = "f6a1feb3f297"
branch_labels = None
depends_on = None


def upgrade():
    op.add_column(
        schema="gn_permissions",
        table_name="t_permissions",
        column=Column("start_on", DateTime, nullable=True),
    )


def downgrade():
    op.drop_column(
        schema="gn_permissions",
        table_name="t_permissions",
        column_name="start_on",
    )
