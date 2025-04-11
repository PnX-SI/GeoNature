"""add default value in additionalFields bib

Revision ID: 1eb624249f2b
Revises: 2aa558b1be3a
Create Date: 2021-10-26 10:28:03.196912

"""

from alembic import op
import sqlalchemy as sa


# revision identifiers, used by Alembic.
revision = "1eb624249f2b"
down_revision = "2aa558b1be3a"
branch_labels = None
depends_on = None


def upgrade():
    op.execute(
        """ALTER TABLE gn_commons.t_additional_fields 
            ADD COLUMN default_value text
        """
    )


def downgrade():
    op.execute(
        """ALTER TABLE gn_commons.t_additional_fields
           DROP COLUMN default_value
        """
    )
