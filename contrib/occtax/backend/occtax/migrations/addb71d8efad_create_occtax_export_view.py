"""create occtax export view

Revision ID: addb71d8efad
Revises: 29c199e07eaa
Create Date: 2021-10-04 11:22:19.819944

"""
import importlib

from alembic import op
import sqlalchemy as sa


# revision identifiers, used by Alembic.
revision = "addb71d8efad"
down_revision = "29c199e07eaa"
branch_labels = None
depends_on = None


def upgrade():
    operations = importlib.resources.read_text("occtax.migrations.data", "exports_occtax.sql")
    op.execute(operations)


def downgrade():
    op.execute("DROP VIEW pr_occtax.v_export_occtax")
