"""date min/max too low

Revision ID: 627b7968a55b
Revises: 699c25251384
Create Date: 2022-05-20 14:43:24.306971

"""

from alembic import op
import sqlalchemy as sa


# revision identifiers, used by Alembic.
revision = "627b7968a55b"
down_revision = "699c25251384"
branch_labels = None
depends_on = None


def upgrade():
    op.execute(
        """
    INSERT INTO gn_imports.bib_errors_types (error_type,"name",description,error_level) VALUES
        ('Incohérence','DATE_MIN_TOO_LOW','La date de début est inférieur à 1900','WARNING'),
        ('Incohérence','DATE_MAX_TOO_LOW','La date de fin est inférieur à 1900','WARNING')
    """
    )


def downgrade():
    op.execute(
        """
    DELETE FROM gn_imports.bib_errors_types WHERE name in ('DATE_MIN_TOO_LOW', 'DATE_MAX_TOO_LOW')
    """
    )
