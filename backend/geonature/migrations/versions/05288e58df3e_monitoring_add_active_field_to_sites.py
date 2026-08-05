"""[monitoring] add active field to sites

Revision ID: 05288e58df3e
Revises: c3db57568f88
Create Date: 2026-02-02 12:12:49.504028

"""

from alembic import op
import sqlalchemy as sa


# revision identifiers, used by Alembic.
revision = "05288e58df3e"
down_revision = "c3db57568f88"
branch_labels = None
depends_on = None


def upgrade():
    op.execute(
        """
        ALTER TABLE gn_monitoring.t_base_sites ADD COLUMN active BOOLEAN NOT NULL DEFAULT TRUE;
        """
    )


def downgrade():
    op.execute(
        """
        ALTER TABLE gn_monitoring.t_base_sites DROP COLUMN active;
        """
    )
