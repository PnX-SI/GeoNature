"""add_column_group_inpn_to_v_synthese_for_web_app

Revision ID: d99a7c22cc3c
Revises: 446e902a14e7
Create Date: 2023-11-17 14:53:42.138762

"""
import importlib

from alembic import op
from sqlalchemy.sql import text
from geonature.utils import alembic_utils

# revision identifiers, used by Alembic.
revision = "d99a7c22cc3c"
down_revision = "446e902a14e7"
branch_labels = None
depends_on = ("c4415009f164",)  # Taxref v15 db structure


view_name = "gn_synthese.v_synthese_for_web_app"

path_synthese = "geonature.migrations.data.core.gn_synthese"


filename = "v_synthese_for_web_app_add_group_inpn_v1.0.2.sql"
sql_text = text(importlib.resources.read_text(path_synthese, filename))
v_synthese_for_web_app = alembic_utils.ReplaceableObject(view_name, sql_text)


def upgrade():
    op.replace_view(v_synthese_for_web_app, replaces="446e902a14e7.v_synthese_for_web_app")


def downgrade():
    op.replace_view(v_synthese_for_web_app, replace_with="446e902a14e7.v_synthese_for_web_app")
