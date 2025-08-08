"""[import]increase the length of bib_fields labels

Revision ID: 8e54e61d698f
Revises: becc3a0c4d90
Create Date: 2025-08-08 14:28:58.168246

"""

from alembic import op
import sqlalchemy as sa


# revision identifiers, used by Alembic.
revision = "8e54e61d698f"
down_revision = "becc3a0c4d90"
branch_labels = None
depends_on = None

varchar_column_to_extend = ["fr_label", "eng_label"]


def upgrade():
    for column_name in varchar_column_to_extend:
        op.execute(
            f"""
            update pg_attribute 
            set atttypmod = 516
            WHERE attrelid = 'gn_imports.bib_fields'::regclass
            AND attname = '{column_name}';
            """
        )


def downgrade():
    for column_name in varchar_column_to_extend:
        op.execute(
            f"""
            update pg_attribute 
            set atttypmod = 100
            WHERE attrelid = 'gn_imports.bib_fields'::regclass
            AND attname = '{column_name}';
            """
        )
