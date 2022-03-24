"""add linears

Revision ID: f7374cd6e38d
Create Date: 2022-02-25 12:342:56.78

"""
import importlib

from alembic import op, context
import sqlalchemy as sa
from sqlalchemy.sql import text
from ref_geo.utils import (
    get_local_srid,
)

# revision identifiers, used by Alembic.
revision = "f7374cd6e38d"
down_revision = "cb038e76d59c"
branch_labels = None
depends_on = None


def upgrade():
    stmt = text(importlib.resources.read_text("ref_geo.migrations.data", "ref_geo_linear.sql"))
    op.get_bind().execute(stmt, {"local_srid": get_local_srid(op.get_bind())})


def downgrade():
    op.execute(
        """
        DROP TABLE ref_geo.cor_linear_group;
        DROP TABLE ref_geo.t_linear_groups;
        DROP TABLE ref_geo.l_linears;
        DROP TABLE ref_geo.bib_linears_types;
    """
    )
