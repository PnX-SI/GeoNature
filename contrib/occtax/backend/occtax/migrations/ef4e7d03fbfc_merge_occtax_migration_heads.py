"""[object] merge occtax migration heads

Revision ID: ef4e7d03fbfc
Revises: 26f11ef2fe77, d2c12d091e14
Create Date: 2026-10-07 08:10:32.037090

"""
from alembic import op
import sqlalchemy as sa


# revision identifiers, used by Alembic.
revision = 'ef4e7d03fbfc'
down_revision = ('26f11ef2fe77', 'd2c12d091e14')
branch_labels = None
depends_on = None


def upgrade():
    pass


def downgrade():
    pass
