"""[import] change observer field type

Revision ID: 832b55d40a2c
Revises: 65f77e9d4c6f
Create Date: 2025-10-29 10:50:09.612783

"""

from alembic import op
import sqlalchemy as sa


# revision identifiers, used by Alembic.
revision = "832b55d40a2c"
down_revision = "65f77e9d4c6f"
branch_labels = None
depends_on = None


def upgrade():
    op.execute(
        """
        UPDATE gn_imports.bib_fields
        SET type_field = 'observers'
        WHERE name_field = 'observers_txt' AND id_destination = (SELECT id_destination FROM gn_imports.bib_destinations WHERE code = 'occhab');
    """
    )


def downgrade():
    op.execute(
        """
        UPDATE gn_imports.bib_fields
        SET type_field = 'textarea'
        WHERE name_field = 'observers' AND id_destination = (SELECT id_destination FROM gn_imports.bib_destinations WHERE code = 'occhab');
    """
    )
