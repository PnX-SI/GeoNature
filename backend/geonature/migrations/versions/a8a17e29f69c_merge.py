"""Merge from rebase

Revision ID: a8a17e29f69c
Revises: ebbe0f7ed866, 0e8e1943c215
Create Date: 2024-03-08 16:47:21.574188

"""

from alembic import op
import sqlalchemy as sa


# revision identifiers, used by Alembic.
revision = "a8a17e29f69c"
down_revision = ("ebbe0f7ed866", "0e8e1943c215")
branch_labels = None
depends_on = None


def upgrade():
    pass


def downgrade():
    pass
