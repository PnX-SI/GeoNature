"""[metadata] increase jdd name column size

Revision ID: 78c7e705efd3
Revises: 83a9f5f6217a
Create Date: 2026-08-26 15:34:55.474105

"""

from alembic import op
import sqlalchemy as sa
from utils_flask_sqla.revision import alter_table_with_dependent_views

# revision identifiers, used by Alembic.
revision = "78c7e705efd3"
down_revision = "83a9f5f6217a"
branch_labels = None
depends_on = None


def upgrade():
    with alter_table_with_dependent_views(op.get_bind(), "gn_meta", "t_datasets"):
        op.execute("""
        ALTER TABLE gn_meta.t_datasets
        ALTER COLUMN dataset_name TYPE VARCHAR;
        """)


def downgrade():
    with alter_table_with_dependent_views(op.get_bind(), "gn_meta", "t_datasets"):
        op.execute("""
        ALTER TABLE gn_meta.t_datasets
        ALTER COLUMN dataset_name TYPE VARCHAR(255);
        """)
