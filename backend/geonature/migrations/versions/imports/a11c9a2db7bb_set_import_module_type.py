"""set import module type

Revision ID: a11c9a2db7bb
Revises: 65defbe5027b
Create Date: 2022-07-05 18:15:09.885031

"""
from alembic import op
import sqlalchemy as sa


# revision identifiers, used by Alembic.
revision = "a11c9a2db7bb"
down_revision = "65defbe5027b"
branch_labels = None
depends_on = None


def upgrade():
    op.execute(
        """
    UPDATE
        gn_commons.t_modules
    SET
        type = 'import'
    WHERE
        module_code = 'IMPORT'
    """
    )


def downgrade():
    op.execute(
        """
    UPDATE
        gn_commons.t_modules
    SET
        type = NULL
    WHERE
        module_code = 'IMPORT'
    """
    )
