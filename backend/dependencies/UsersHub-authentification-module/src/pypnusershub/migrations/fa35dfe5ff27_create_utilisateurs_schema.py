"""utilisateurs schema 1.4.7

Revision ID: fa35dfe5ff27
Revises: 
Create Date: 2021-08-24 15:39:57.784074

"""
import importlib.resources

from alembic import op
import sqlalchemy as sa


# revision identifiers, used by Alembic.
revision = 'fa35dfe5ff27'
down_revision = None
branch_labels = ('utilisateurs',)
depends_on = None


def upgrade():
    op.execute(importlib.resources.read_text('pypnusershub.migrations.data', 'utilisateurs.sql'))


def downgrade():
    op.execute("DROP SCHEMA utilisateurs CASCADE")
