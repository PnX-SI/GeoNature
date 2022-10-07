"""ref_geo schema

Revision ID: 6afe74833ed0
Create Date: 2021-09-27 18:07:43.582936

"""
import importlib

from alembic import op, context
import sqlalchemy as sa
from sqlalchemy.sql import text


# revision identifiers, used by Alembic.
revision = "6afe74833ed0"
down_revision = None
branch_labels = ("ref_geo",)
depends_on = ("3842a6d800a0",)  # sql utils


def upgrade():
    try:
        local_srid = context.get_x_argument(as_dictionary=True)["local-srid"]
    except KeyError:
        raise Exception("Missing local srid, please use -x local-srid=...")
    stmt = text(importlib.resources.read_text("ref_geo.migrations.data", "ref_geo.sql"))
    op.get_bind().execute(stmt, {"local_srid": local_srid})


def downgrade():
    op.execute("DROP SCHEMA ref_geo CASCADE")
