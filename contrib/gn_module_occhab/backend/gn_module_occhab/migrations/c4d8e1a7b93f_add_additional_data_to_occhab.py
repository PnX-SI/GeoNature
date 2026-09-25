"""add additional_data to occhab stations and habitats

Revision ID: c4d8e1a7b93f
Revises: fc6f7f3cb801
Create Date: 2026-08-31 10:12:44.318602

"""

from alembic import op
import sqlalchemy as sa
from sqlalchemy.dialects.postgresql import JSONB

# revision identifiers, used by Alembic.
revision = "c4d8e1a7b93f"
down_revision = "fc6f7f3cb801"
branch_labels = None
depends_on = None


def upgrade():
    for table in ("t_stations", "t_habitats"):
        op.add_column(
            table,
            sa.Column("additional_data", JSONB, server_default=sa.text("'{}'::jsonb")),
            schema="pr_occhab",
        )


def downgrade():
    for table in ("t_stations", "t_habitats"):
        op.drop_column(table, "additional_data", schema="pr_occhab")
