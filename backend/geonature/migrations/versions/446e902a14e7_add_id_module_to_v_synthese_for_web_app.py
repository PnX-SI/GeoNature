"""add id_module to v_synthese_for_web_app

Revision ID: 446e902a14e7
Revises: f1dd984bff97
Create Date: 2023-09-25 10:09:39.126531

"""
import importlib

from alembic import op
from sqlalchemy.sql import text
from geonature.utils import alembic_utils

# revision identifiers, used by Alembic.
revision = "446e902a14e7"
down_revision = "f1dd984bff97"
branch_labels = None
depends_on = None


view_name = "gn_synthese.v_synthese_for_web_app"

path_synthese = "geonature.migrations.data.core.gn_synthese"
init_filename = "initial_v_synthese_for_web_app_v1.0.0.sql"
sql_text = text(importlib.resources.read_text(path_synthese, init_filename))
v_synthese_for_web_app_init = alembic_utils.ReplaceableObject(view_name, sql_text)

filename = "v_synthese_for_web_app_add_id_module_v1.0.1.sql"
sql_text = text(importlib.resources.read_text(path_synthese, filename))
v_synthese_for_web_app = alembic_utils.ReplaceableObject(view_name, sql_text)


def upgrade():
    op.drop_view(v_synthese_for_web_app_init)
    op.create_view(v_synthese_for_web_app)


def downgrade():
    op.drop_view(v_synthese_for_web_app)
    op.create_view(v_synthese_for_web_app_init)
