"""Insert French regions in ref_geo

Revision ID: d02f4563bebe
Create Date: 2021-11-23 12:06:37.699867

"""
from alembic import op
import sqlalchemy as sa
from shutil import copyfileobj

from ref_geo.migrations.utils import (
    schema,
    delete_area_with_type,
)
from utils_flask_sqla.migrations.utils import logger, open_remote_file


# revision identifiers, used by Alembic.
revision = "d02f4563bebe"
down_revision = None
branch_labels = ("ref_geo_fr_regions",)
depends_on = "4882d6141a41"  # ref_geo


filename = "regions_fr_2021-11.csv.xz"
base_url = "http://geonature.fr/data/ign/"
temp_table_name = "temp_fr_regions"


def upgrade():
    logger.info("Create temporary regions table…")
    op.execute(
        f"""
        CREATE TABLE {schema}.{temp_table_name} (
            gid integer NOT NULL,
            id character varying(24),
            nom_m character varying(50),
            nom character varying(50),
            insee_reg character varying(5),
            geom public.geometry(MultiPolygon,2154)
        )
    """
    )
    op.execute(
        f"""
        ALTER TABLE ONLY {schema}.{temp_table_name}
            ADD CONSTRAINT {temp_table_name}_pkey PRIMARY KEY (gid)
    """
    )
    cursor = op.get_bind().connection.cursor()
    with open_remote_file(base_url, filename) as geofile:
        logger.info("Inserting regions data in temporary table…")
        cursor.copy_expert(f"COPY {schema}.{temp_table_name} FROM STDIN", geofile)
    logger.info("Copy regions in l_areas…")
    op.execute(
        f"""
        INSERT INTO {schema}.l_areas (
            id_type,
            area_code,
            area_name,
            geom,
            geojson_4326
        )
        SELECT
            {schema}.get_id_area_type('REG') as id_type,
            insee_reg,
            nom,
            ST_Transform(geom, Find_SRID('{schema}', 'l_areas', 'geom')),
            public.ST_asgeojson(public.st_transform(geom, 4326))
        FROM {schema}.{temp_table_name}
    """
    )
    logger.info("Re-indexing…")
    op.execute(f"REINDEX INDEX {schema}.index_l_areas_geom")
    logger.info("Dropping temporary regions table…")
    op.execute(f"DROP TABLE {schema}.{temp_table_name}")


def downgrade():
    delete_area_with_type("REG")
