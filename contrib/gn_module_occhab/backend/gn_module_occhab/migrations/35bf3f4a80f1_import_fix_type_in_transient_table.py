"""[import] fix type in transient table

Revision ID: 35bf3f4a80f1
Revises: f1b70ed3c809
Create Date: 2025-06-20 13:27:11.802411

"""

from alembic import op
import sqlalchemy as sa


# revision identifiers, used by Alembic.
revision = "35bf3f4a80f1"
down_revision = "f1b70ed3c809"
branch_labels = None
depends_on = None


def upgrade():
    op.execute(
        """
        ALTER TABLE gn_imports.t_imports_occhab ALTER COLUMN recovery_percentage TYPE numeric USING recovery_percentage::numeric;
        """
    )


def downgrade():
    op.execute(
        """
        ALTER TABLE gn_imports.t_imports_occhab ALTER COLUMN recovery_percentage TYPE int4 USING recovery_percentage::int4;

        """
    )
