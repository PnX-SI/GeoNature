"""add_column_group_inpn_to_v_synthese_for_web_app

Revision ID: d99a7c22cc3c
Revises: 446e902a14e7
Create Date: 2023-11-17 14:53:42.138762

"""
import importlib

from alembic import op
from sqlalchemy.sql import text


# revision identifiers, used by Alembic.
revision = "d99a7c22cc3c"
down_revision = "446e902a14e7"
branch_labels = None
depends_on = ("c4415009f164",)  # Taxref v15 db structure


def upgrade():
    conn = op.get_bind()
    path = "geonature.migrations.data.core.gn_synthese"
    filename = "v_synthese_for_web_app_add_group_inpn_v1.0.2.sql"
    conn.execute(text(importlib.resources.read_text(path, filename)))


def downgrade():
    conn = op.get_bind()
    path = "geonature.migrations.data.core.gn_synthese"
    filename = "v_synthese_for_web_app_add_id_module_v1.0.1.sql"
    conn.execute(text(importlib.resources.read_text(path, filename)))
