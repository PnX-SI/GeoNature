"""increase the length of a datasets label

Revision ID: ab7d63977c5d
Revises: a7f95c66819a
Create Date: 2025-08-08 14:17:29.671513

"""

from alembic import op
import sqlalchemy as sa


# revision identifiers, used by Alembic.
revision = "ab7d63977c5d"
down_revision = "a7f95c66819a"
branch_labels = None
depends_on = None


def upgrade():
    op.execute(
        """
    update pg_attribute 
    set atttypmod = 516
    WHERE attrelid = 'gn_meta.t_datasets'::regclass
    AND attname = 'dataset_name';
    """
    )


def downgrade():
    op.execute(
        """
    update pg_attribute 
    set atttypmod = 259
    WHERE attrelid = 'gn_meta.t_datasets'::regclass
    AND attname = 'dataset_name';
    """
    )
