"""Add two columns

Revision ID: 2ed6a7ee5250
Revises: 3a65de65b697
Create Date: 2021-03-30 11:06:40.502478

"""
from alembic import op
import sqlalchemy as sa


# revision identifiers, used by Alembic.
revision = "2ed6a7ee5250"
down_revision = "3a65de65b697"
branch_labels = None
depends_on = None


def upgrade():
    op.execute(
        """
        ALTER TABLE gn_imports.t_imports
        ADD COLUMN detected_encoding VARCHAR
    """
    )
    op.execute(
        """
        ALTER TABLE gn_imports.t_imports
        ADD COLUMN source_file BYTEA
    """
    )


def downgrade():
    op.execute(
        """
        ALTER TABLE gn_imports.t_imports
        DROP COLUMN source_file
    """
    )
    op.execute(
        """
        ALTER TABLE gn_imports.t_imports
        DROP COLUMN detected_encoding
    """
    )
