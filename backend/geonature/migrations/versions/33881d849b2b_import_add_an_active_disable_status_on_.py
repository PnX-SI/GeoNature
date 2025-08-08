"""[import] Add an active/disable status on a destination

Revision ID: 33881d849b2b
Revises: 8e54e61d698f
Create Date: 2025-08-08 14:34:35.961121

"""

from alembic import op
import sqlalchemy as sa


# revision identifiers, used by Alembic.
revision = "33881d849b2b"
down_revision = "8e54e61d698f"
branch_labels = None
depends_on = None


def upgrade():
    op.add_column(
        "bib_destinations",
        sa.Column("active", sa.Boolean, server_default=sa.true()),
        schema="gn_imports",
    )


def downgrade():
    op.drop_column("bib_destinations", "active", schema="gn_imports")
