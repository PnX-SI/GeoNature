"""Vectorize French DEM

Revision ID: 87651375c2e8
Create Date: 2021-09-28 10:41:26.441911

"""

from alembic import op
import sqlalchemy as sa


# revision identifiers, used by Alembic.
revision = "87651375c2e8"
down_revision = None
branch_labels = ("ign_bd_alti_vector",)
depends_on = ("1715cf31a75d",)  # IGN BD Alti


def upgrade():
    op.execute(
        "INSERT INTO ref_geo.dem_vector (geom, val) SELECT (ST_DumpAsPolygons(rast)).* FROM ref_geo.dem"
    )
    op.execute("REINDEX INDEX ref_geo.index_dem_vector_geom")


def downgrade():
    op.execute("TRUNCATE ref_geo.dem_vector")
