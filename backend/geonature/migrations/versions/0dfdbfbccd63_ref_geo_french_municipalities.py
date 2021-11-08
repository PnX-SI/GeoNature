"""Insert French municipalities in ref_geo

Revision ID: 0dfdbfbccd63
Create Date: 2021-06-01 11:02:56.834432

"""
from alembic import op
from shutil import copyfileobj

from geonature.migrations.ref_geo_utils import (
    schema,
    delete_area_with_type,
)
from utils_flask_sqla.migrations.utils import logger, open_remote_file


# revision identifiers, used by Alembic.
revision = '0dfdbfbccd63'
down_revision = None
branch_labels = ('ref_geo_fr_municipalities',)
depends_on = '6afe74833ed0'  # ref_geo

filename = 'communes_fr_2020-02.csv.xz'
base_url = 'http://geonature.fr/data/ign/'
temp_table_name = 'temp_fr_municipalities'


def upgrade():
    logger.info("Create temporary municipalities table…")
    op.execute(f"""
        CREATE TABLE {schema}.{temp_table_name} (
            gid integer NOT NULL,
            id character varying(24),
            nom_com character varying(50),
            nom_com_m character varying(50),
            insee_com character varying(5),
            statut character varying(24),
            insee_can character varying(2),
            insee_arr character varying(2),
            insee_dep character varying(3),
            insee_reg character varying(2),
            code_epci character varying(21),
            population bigint,
            type character varying(3),
            geom public.geometry(MultiPolygon,2154),
            geojson character varying
        )
    """)
    op.execute(f"""
        ALTER TABLE ONLY {schema}.{temp_table_name}
            ADD CONSTRAINT {temp_table_name}_pkey PRIMARY KEY (gid)
    """)
    cursor = op.get_bind().connection.cursor()
    with open_remote_file(base_url, filename) as geofile:
        logger.info("Inserting municipalities data in temporary table…")
        cursor.copy_expert(f'COPY {schema}.{temp_table_name} FROM STDIN', geofile)
    logger.info("Copy municipalities in l_areas…")
    op.execute(f"""
        INSERT INTO {schema}.l_areas (id_type, area_code, area_name, geom, geojson_4326)
        SELECT {schema}.get_id_area_type('COM') AS id_type, insee_com, nom_com, geom, geojson
        FROM {schema}.{temp_table_name}
    """)
    logger.info("Copy municipalities in li_municipalities…")
    op.execute(f"""
        INSERT INTO ref_geo.li_municipalities
        (id_municipality, id_area, status, insee_com, nom_com, insee_arr, insee_dep, insee_reg, code_epci)
        SELECT id,  a.id_area, statut, insee_com, nom_com, insee_arr, insee_dep, insee_reg, code_epci
        FROM ref_geo.temp_fr_municipalities t
        JOIN ref_geo.l_areas a ON a.area_code = t.insee_com
    """)
    logger.info("Re-indexing…")
    op.execute(f'REINDEX INDEX {schema}.index_l_areas_geom')
    logger.info("Dropping temporary municipalities table…")
    op.execute(f'DROP TABLE {schema}.{temp_table_name}')


def downgrade():
    delete_area_with_type('COM')
    # Note: li_municipalities is automatically emptied because of the FK against l_areas
