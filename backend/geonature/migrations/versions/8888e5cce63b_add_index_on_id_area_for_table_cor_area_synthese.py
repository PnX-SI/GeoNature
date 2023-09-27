"""add index on id_area for table cor_area_synthese

Revision ID: 8888e5cce63b
Revises: 09a637f06b96
Create Date: 2023-01-18 17:34:54.298323

"""
from alembic import op
import sqlalchemy as sa


# revision identifiers, used by Alembic.
revision = "8888e5cce63b"
down_revision = "09a637f06b96"
branch_labels = None
depends_on = None

SCHEMA_NAME = "gn_synthese"
TABLE_NAME = "cor_area_synthese"
INDEX_NAME = "i_cor_area_synthese_id_area"
COLUMN_NAME = "id_area"


def upgrade():
    op.create_index(INDEX_NAME, schema=SCHEMA_NAME, table_name=TABLE_NAME, columns=[COLUMN_NAME])


def downgrade():
    op.drop_index(INDEX_NAME, schema=SCHEMA_NAME, table_name=TABLE_NAME)
