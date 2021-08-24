"""add schema gn_profiles

Revision ID: 2aa558b1be3a
Revises: f06cc80cc8ba
Create Date: 2021-08-24 11:10:08.973033

"""
import importlib.resources

from alembic import op
import sqlalchemy as sa


# revision identifiers, used by Alembic.
revision = '2aa558b1be3a'
down_revision = 'f06cc80cc8ba'
branch_labels = None
depends_on = ('98035939bc0d',)


def upgrade():
    op.execute(importlib.resources.read_text('geonature.migrations.data.core', 'profiles.sql'))


def downgrade():
    op.execute(f'DROP SCHEMA gn_profiles CASCADE')
