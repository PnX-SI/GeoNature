"""add regions in area types

Revision ID: 4882d6141a41
Revises: e0ac4c9f5c0a
Create Date: 2021-11-23 12:17:22.518074

"""
from alembic import op
import sqlalchemy as sa


# revision identifiers, used by Alembic.
revision = "4882d6141a41"
down_revision = "e0ac4c9f5c0a"
branch_labels = None
depends_on = None


def upgrade():
    conn = op.get_bind()
    metadata = sa.MetaData(bind=conn)
    area_type = sa.Table("bib_areas_types", metadata, schema="ref_geo", autoload_with=conn)
    conn.execute(
        area_type.insert().values(
            type_name="Régions",
            type_code="REG",
            type_desc="Type régions",
            ref_name="IGN admin_express",
        )
    )


def downgrade():
    conn = op.get_bind()
    metadata = sa.MetaData(bind=conn)
    area_type = sa.Table("bib_areas_types", metadata, schema="ref_geo", autoload_with=conn)
    conn.execute(area_type.delete().where(area_type.c.type_code == "REG"))
