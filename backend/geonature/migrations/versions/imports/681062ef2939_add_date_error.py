"""add date error

Revision ID: 681062ef2939
Revises: eb217f32d7d7
Create Date: 2022-05-10 12:42:31.793379

"""

from alembic import op
import sqlalchemy as sa


# revision identifiers, used by Alembic.
revision = "681062ef2939"
down_revision = "eb217f32d7d7"
branch_labels = None
depends_on = None


def upgrade():
    op.execute(
        """
        INSERT INTO gn_imports.dict_errors (error_type,"name",description,error_level) VALUES 
        ('Date invalide','DATE_MIN_TOO_HIGH','La date de début est dans le futur ','ERROR'),
        ('Date invalide','DATE_MAX_TOO_HIGH','La date de fin est dans le futur ','ERROR')
        ;
    """
    )


def downgrade():
    op.execute(
        """
            DELETE FROM gn_imports.dict_errors WHERE name = 'DATE_MIN_TOO_HIGH' OR name = 'DATE_MAX_TOO_HIGH'
            ;
        """
    )
