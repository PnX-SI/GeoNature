"""create occhab schema

Revision ID: 2984569d5df6
Revises:
Create Date: 2021-10-04 10:15:40.419932

"""

import importlib

from alembic import op
import sqlalchemy as sa
from sqlalchemy import func
from sqlalchemy.sql import text


# revision identifiers, used by Alembic.
revision = "2984569d5df6"
down_revision = None
branch_labels = ("occhab",)
depends_on = ("f06cc80cc8ba",)  # GeoNature 2.7.5


def upgrade():
    local_srid = op.get_bind().execute(func.Find_SRID("ref_geo", "l_areas", "geom")).scalar()
    operations = text(
        importlib.resources.read_text("gn_module_occhab.migrations.data", "occhab.sql")
    )
    op.get_bind().execute(operations, {"local_srid": local_srid})


def downgrade():
    op.execute(
        """
    DELETE FROM gn_commons.bib_tables_location
    WHERE schema_name = 'pr_occhab'
    """
    )
    op.execute("DROP SCHEMA pr_occhab CASCADE")
