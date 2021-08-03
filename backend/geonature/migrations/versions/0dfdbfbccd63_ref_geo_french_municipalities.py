"""Insert French municipalities in ref_geo

Revision ID: 0dfdbfbccd63
Create Date: 2021-06-01 11:02:56.834432

"""
from alembic import op, context
import sqlalchemy as sa
import logging
from zipfile import ZipFile
from contextlib import ExitStack
from tempfile import TemporaryDirectory
from shutil import copyfileobj
from urllib.request import urlopen
from io import StringIO
import os, os.path


# revision identifiers, used by Alembic.
revision = '0dfdbfbccd63'
down_revision = None
branch_labels = ('ref_geo_fr_municipalities',)
depends_on = None

zip_filename = 'communes_fr_admin_express_2020-02.zip'
sql_filename = 'fr_municipalities.sql'
base_url = 'http://geonature.fr/data/ign/'
schema = 'ref_geo'
temp_table_name = 'temp_fr_municipalities'


logger = logging.getLogger('alembic.runtime.migration')


def upgrade():
    with ExitStack() as stack:
        geo_dir = context.get_x_argument(as_dictionary=True).get('geo-data-directory')
        if not geo_dir:
            geo_dir = stack.enter_context(TemporaryDirectory())
            logger.info(f"Created temporary directory {geo_dir}")
        if not os.path.exists(geo_dir):
            os.mkdir(geo_dir)
        if not os.path.isfile(f'{geo_dir}/{sql_filename}'):
            if not os.path.isfile(f'{geo_dir}/{zip_filename}'):
                logger.info("Downloading municipalities data…")
                with urlopen(f'{base_url}{zip_filename}') as response, open(f'{geo_dir}/{zip_filename}', 'wb') as zip_file:
                    copyfileobj(response, zip_file)
            logger.info("Extracting municipalities data…")
            with ZipFile(f'{geo_dir}/{zip_filename}') as z:
                z.extractall(path=geo_dir)
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
            CREATE SEQUENCE {schema}.{temp_table_name}_gid_seq
                AS integer
                START WITH 1
                INCREMENT BY 1
                NO MINVALUE
                NO MAXVALUE
                CACHE 1
        """)
        op.execute(f"""
            ALTER SEQUENCE {schema}.{temp_table_name}_gid_seq
                OWNED BY {schema}.{temp_table_name}.gid
        """)
        op.execute(f"""
            ALTER TABLE ONLY {schema}.{temp_table_name} ALTER COLUMN gid
            SET DEFAULT nextval('{schema}.{temp_table_name}_gid_seq'::regclass)
        """)
        op.execute(f"""
            SELECT pg_catalog.setval('{schema}.{temp_table_name}_gid_seq', 34839, true)
        """)
        op.execute(f"""
            ALTER TABLE ONLY {schema}.{temp_table_name}
                ADD CONSTRAINT {temp_table_name}_pkey PRIMARY KEY (gid)
        """)
        cursor = op.get_bind().connection.cursor()
        with open(f'{geo_dir}/{sql_filename}') as sql_file:
            # we extract data from sql file based on line numbers
            # this is not very satisfying, we should better upload a dedicated file
            data_file = StringIO(''.join(sql_file.readlines()[77:34916]))
            logger.info("Inserting municipalities data in temporary table…")
            columns=('gid', 'id', 'nom_com', 'nom_com_m', 'insee_com', 'statut',
                     'insee_can', 'insee_arr', 'insee_dep', 'insee_reg', 'code_epci',
                     'population', 'type', 'geom', 'geojson')
            columns = ', '.join(f'"{col}"' for col in columns)
            sql = f'COPY {schema}.{temp_table_name} ({columns}) FROM STDIN' \
                   " WITH DELIMITER AS '\t' NULL AS '\\N'"
            # note: copy_from does not work because table name is quoted and we use schema
            cursor.copy_expert(sql, data_file)
        logger.info("Copy municipalities data in l_areas…")
        # note: arrondissement are excluded
        op.execute(f"""
            INSERT INTO {schema}.l_areas (id_type, area_code, area_name, geom, geojson_4326)
            SELECT {schema}.get_id_area_type('COM') AS id_type, insee_com, nom_com, geom, geojson
            FROM {schema}.{temp_table_name}
            WHERE id ILIKE 'commune%'
        """)
        logger.info("Copy municipalities data in li_municipalities…")
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
    op.execute(f"""
        DELETE FROM {schema}.l_areas la
        USING {schema}.get_id_area_type('COM') as com_type
        WHERE la.id_type = com_type
    """)
    # Note: li_municipalities is automatically emptied because of the FK against l_areas
