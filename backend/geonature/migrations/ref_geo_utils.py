from alembic import op, context
import sqlalchemy as sa
import logging
from contextlib import ExitStack
from tempfile import TemporaryDirectory
from shutil import copyfileobj
from urllib.request import urlopen
import lzma
import os, os.path


schema = 'ref_geo'

logger = logging.getLogger('alembic.runtime.migration')


class open_geofile(ExitStack):
    def __init__(self, base_url, filename):
        super().__init__()
        self.base_url = base_url
        self.filename = filename
        self.geo_dir = context.get_x_argument(as_dictionary=True).get('geo-data-directory')

    def __enter__(self):
        stack = super().__enter__()
        if not self.geo_dir:
            self.geo_dir = stack.enter_context(TemporaryDirectory())
            logger.info("Created temporary directory '{}'".format(self.geo_dir))
        if not os.path.exists(self.geo_dir):
            os.mkdir(self.geo_dir)
        geofile_path = os.path.join(self.geo_dir, self.filename)
        if not os.path.isfile(geofile_path):
            logger.info("Downloading '{}'…".format(self.filename))
            with urlopen('{}{}'.format(self.base_url, self.filename)) as response, \
                                              open(geofile_path, 'wb') as geofile:
                copyfileobj(response, geofile)
        return stack.enter_context(lzma.open(geofile_path))


def delete_area_with_type(area_type):
    op.execute(f"""
        DELETE FROM {schema}.l_areas la
        USING {schema}.get_id_area_type('{area_type}') as area_type
        WHERE la.id_type = area_type
    """)


def create_temporary_grids_table(schema, temp_table_name):
    logger.info("Create temporary grids table…")
    op.execute(f"""
        CREATE TABLE {schema}.{temp_table_name} (
            gid integer NOT NULL,
            cd_sig character varying(21),
            code character varying(10),
            geom public.geometry(MultiPolygon,2154),
            geojson character varying
        )
    """)
    op.execute(f"""
        ALTER TABLE ONLY {schema}.{temp_table_name}
            ADD CONSTRAINT {temp_table_name}_pkey PRIMARY KEY (gid)
    """)


def insert_grids_and_drop_temporary_table(schema, temp_table_name, area_type):
    logger.info("Copy grids in l_areas…")
    op.execute(f"""
        INSERT INTO {schema}.l_areas (id_type, area_code, area_name, geom, geojson_4326)
        SELECT {schema}.get_id_area_type('{area_type}') AS id_type, cd_sig, code, geom, geojson
        FROM {schema}.{temp_table_name}
    """)
    logger.info("Copy grids in li_grids…")
    op.execute(f"""
        INSERT INTO {schema}.li_grids(id_grid, id_area, cxmin, cxmax, cymin, cymax)
            SELECT
                l.area_code,
                l.id_area,
                ST_XMin(g.geom),
                ST_XMax(g.geom),
                ST_YMin(g.geom),
                ST_YMax(g.geom)
            FROM {schema}.{temp_table_name} g
            JOIN {schema}.l_areas l ON l.area_code = cd_sig;
    """)
    logger.info("Re-indexing…")
    op.execute(f'REINDEX INDEX {schema}.index_l_areas_geom')
    logger.info("Dropping temporary grids table…")
    op.execute(f'DROP TABLE {schema}.{temp_table_name}')
