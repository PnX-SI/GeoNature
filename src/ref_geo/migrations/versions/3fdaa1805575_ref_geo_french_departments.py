"""Insert French departments in ref_geo

Revision ID: 3fdaa1805575
Create Date: 2021-06-01 11:02:56.834432

"""
from alembic import op
from shutil import copyfileobj

from ref_geo.migrations.utils import schema, delete_area_with_type
from utils_flask_sqla.migrations.utils import logger, open_remote_file


# revision identifiers, used by Alembic.
revision = "3fdaa1805575"
down_revision = None
branch_labels = ("ref_geo_fr_departments",)
depends_on = "6afe74833ed0"  # ref_geo

filename = "departements_fr_2020-02.csv.xz"
base_url = "http://geonature.fr/data/ign/"
temp_table_name = "temp_fr_departements"


def upgrade():
    logger.info("Create temporary departments table…")
    op.execute(
        f"""
        CREATE TABLE {schema}.{temp_table_name} (
            gid integer NOT NULL,
            id character varying(24),
            nom_dep character varying(30),
            nom_dep_m character varying(30),
            insee_dep character varying(3),
            insee_reg character varying(2),
            chf_dep character varying(5),
            geom public.geometry(MultiPolygon,2154),
            geojson character varying
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
        logger.info("Inserting departments data in temporary table…")
        cursor.copy_expert(f"COPY {schema}.{temp_table_name} FROM STDIN", geofile)
    logger.info("Copy departments data in l_areas…")
    op.execute(
        f"""
        INSERT INTO {schema}.l_areas (id_type, area_code, area_name, geom, geojson_4326)
        SELECT
            {schema}.get_id_area_type('DEP') AS id_type,
            insee_dep,
            nom_dep,
            ST_TRANSFORM(geom, Find_SRID('{schema}', 'l_areas', 'geom')),
            geojson
        FROM {schema}.{temp_table_name}
    """
    )
    logger.info("Re-indexing…")
    op.execute(f"REINDEX INDEX {schema}.index_l_areas_geom")
    logger.info("Dropping temporary departments table…")
    op.execute(f"DROP TABLE {schema}.{temp_table_name}")


def downgrade():
    delete_area_with_type("DEP")
