"""add indexes on FK referencing l_areas.id_area

Revision ID: e0ac4c9f5c0a
Revises: 6afe74833ed0
Create Date: 2021-09-15 09:26:08.125615

"""
from alembic import op
import sqlalchemy as sa


# revision identifiers, used by Alembic.
revision = "e0ac4c9f5c0a"
down_revision = "6afe74833ed0"
branch_labels = None
depends_on = None


def upgrade():
    op.create_index(
        "index_li_grids_id_area", schema="ref_geo", table_name="li_grids", columns=["id_area"]
    )
    op.create_index(
        "index_li_municipalities_id_area",
        schema="ref_geo",
        table_name="li_municipalities",
        columns=["id_area"],
    )


def downgrade():
    op.drop_index("index_li_grids_id_area", schema="ref_geo", table_name="li_grids")
    op.drop_index(
        "index_li_municipalities_id_area", schema="ref_geo", table_name="li_municipalities"
    )
