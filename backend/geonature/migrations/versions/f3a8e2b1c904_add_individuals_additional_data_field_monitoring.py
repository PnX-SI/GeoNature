"""[monitoring] add additional_data to t_individuals

Revision ID: f3a8e2b1c904
Revises: daeaa45e4cc0
Create Date: 2026-06-12 00:00:00.000000

"""

from alembic import op
import sqlalchemy as sa
from sqlalchemy.dialects import postgresql

# revision identifiers, used by Alembic.
revision = "f3a8e2b1c904"
down_revision = "daeaa45e4cc0"
branch_labels = None
depends_on = None


def upgrade():
    op.add_column(
        "t_individuals",
        sa.Column("additional_data", postgresql.JSONB(), nullable=True),
        schema="gn_monitoring",
    )


def downgrade():
    op.drop_column("t_individuals", "additional_data", schema="gn_monitoring")
