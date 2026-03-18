"""add_closed_af_error

Revision ID: bc060d4f55ce
Revises: 2b0b3bd0248c
Create Date: 2026-18-03 10:49:49.973738

"""

from alembic import op

revision = "bc060d4f55ce"
down_revision = "2b0b3bd0248c"
branch_labels = None
depends_on = None


def upgrade():
    op.execute(
        """
        INSERT INTO gn_imports.bib_errors_types (error_type, name, description, error_level) VALUES
            ('Cadre d''acquisition fermé', 'CLOSED_ACQUISITION_FRAMEWORK', 'Un cadre d''acquisiton associé est fermé', 'ERROR')
        ;
        """
    )


def downgrade():
    op.execute(
        """
            DELETE FROM gn_imports.bib_errors_types WHERE name = 'CLOSED_ACQUISITION_FRAMEWORK';
        """
    )
