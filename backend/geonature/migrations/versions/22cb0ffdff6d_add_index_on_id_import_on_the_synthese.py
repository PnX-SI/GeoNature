"""add index on id_import on the synthese

Revision ID: 22cb0ffdff6d
Revises: 54e5b4a96add
Create Date: 2025-02-24 17:13:50.963764

"""

from alembic import op
import sqlalchemy as sa


# revision identifiers, used by Alembic.
revision = "22cb0ffdff6d"
down_revision = "54e5b4a96add"
branch_labels = None
depends_on = None


def upgrade():
    op.create_index(
        "synthese_id_import_idx",
        "synthese",
        ["id_import"],
        schema="gn_synthese",
    )


def downgrade():
    op.drop_index(
        "synthese_id_import_idx",
        table_name="synthese",
        schema="gn_synthese",
    )
