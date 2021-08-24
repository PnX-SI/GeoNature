"""add schema gn_profile

Revision ID: 2aa558b1be3a
Revises: f06cc80cc8ba
Create Date: 2021-08-24 11:10:08.973033

"""
from alembic import op
import sqlalchemy as sa

from geonature.utils.env import ROOT_DIR

# revision identifiers, used by Alembic.
revision = '2aa558b1be3a'
down_revision = 'f06cc80cc8ba'
branch_labels = None
depends_on = None


def upgrade():
    with open(ROOT_DIR / 'data/core/profiles.sql') as f:
        operations= f.readlines()
    op.execute(
        "".join(operations)
    )


def downgrade():
    op.execute(f'DROP SCHEMA gn_profiles CASCADE')
