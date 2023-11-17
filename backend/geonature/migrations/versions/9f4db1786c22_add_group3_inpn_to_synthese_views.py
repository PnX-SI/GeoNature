"""add group3 inpn to synthese views

Revision ID: 9f4db1786c22
Revises: 446e902a14e7
Create Date: 2023-07-21 14:15:23.311469

"""
import importlib

from alembic import op
from sqlalchemy.sql import text

# revision identifiers, used by Alembic.
revision = "9f4db1786c22"
down_revision = "446e902a14e7"
branch_labels = None
depends_on = ("c4415009f164",)  # Taxref v15 db structure


def upgrade():
    conn = op.get_bind()
    path = "geonature.migrations.data.core.gn_synthese"
    filename = "synthese_view_export_add_group3_inpn.sql"
    conn.execute(text(importlib.resources.read_text(path, filename)))


def downgrade():
    conn = op.get_bind()
    path = "geonature.migrations.data.core.gn_synthese"
    filename = "synthese_view_export_remove_group3_inpn.sql"
    conn.execute(text(importlib.resources.read_text(path, filename)))
