"""remove step field

Revision ID: bf80cb5679be
Revises: 75f0f9906bf1
Create Date: 2022-02-01 16:28:34.090996

"""
from alembic import op
import sqlalchemy as sa


# revision identifiers, used by Alembic.
revision = "bf80cb5679be"
down_revision = "75f0f9906bf1"
branch_labels = None
depends_on = None


def upgrade():
    op.execute(
        """
        ALTER TABLE gn_imports.t_imports
        DROP COLUMN step
    """
    )

    op.execute(
        """
        ALTER TABLE gn_imports.t_user_error_list
        DROP COLUMN step
    """
    )


def downgrade():
    op.execute(
        """
        ALTER TABLE gn_imports.t_imports
        ADD COLUMN step integer
    """
    )

    op.execute(
        """
        ALTER TABLE gn_imports.t_user_error_list
        ADD COLUMN step VARCHAR(20) null
    """
    )
