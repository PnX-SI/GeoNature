"""allow multi select mapping

Revision ID: 8611f7aab8dc
Revises: a89a99f68203
Create Date: 2023-07-27 11:18:00.424394

"""
from alembic import op
import sqlalchemy as sa


# revision identifiers, used by Alembic.
revision = "8611f7aab8dc"
down_revision = "a89a99f68203"
branch_labels = None
depends_on = None


def upgrade():
    op.execute(
        """
        ALTER TABLE
            gn_imports.bib_fields
        ADD COLUMN
            multi BOOLEAN NOT NULL DEFAULT FALSE
        """
    )
    op.execute(
        """
        UPDATE
            gn_imports.bib_fields
        SET
            multi = TRUE
        WHERE
            name_field = 'additional_data'
        """
    )


def downgrade():
    op.execute(
        """
        ALTER TABLE
            gn_imports.bib_fields
        DROP COLUMN
            multi
        """
    )
