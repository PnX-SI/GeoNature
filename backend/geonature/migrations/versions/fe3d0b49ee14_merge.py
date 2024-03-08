"""Merge from rebase

Revision ID: fe3d0b49ee14
Revises: 9f4db1786c22, bfc90691737d
Create Date: 2024-03-08 16:47:21.574188

"""

from alembic import op
import sqlalchemy as sa


# revision identifiers, used by Alembic.
revision = "fe3d0b49ee14"
down_revision = ("9f4db1786c22", "bfc90691737d")
branch_labels = None
depends_on = None


def upgrade():
    pass


def downgrade():
    pass
