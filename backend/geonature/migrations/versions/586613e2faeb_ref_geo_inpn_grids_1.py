"""Insert INPN 1×1 grids in ref_geo

Revision ID: 586613e2faeb
Create Date: 2021-06-01 11:02:56.834432

"""
from alembic import op
from shutil import copyfileobj

from geonature.migrations.ref_geo_utils import (
    logger,
    schema,
    create_temporary_grids_table,
    open_geofile,
    delete_area_with_type,
    insert_grids_and_drop_temporary_table
)


# revision identifiers, used by Alembic.
revision = '586613e2faeb'
down_revision = None
branch_labels = ('ref_geo_inpn_grids_1',)
depends_on = None

filename = 'inpn_grids_1.csv.xz'
base_url = 'http://geonature.fr/data/inpn/layers/2020/'
temp_table_name = 'temp_grids_1'
area_type = 'M1'


def upgrade():
    create_temporary_grids_table(schema, temp_table_name)
    cursor = op.get_bind().connection.cursor()
    with open_geofile(base_url, filename) as geofile:
        logger.info("Inserting grids data in temporary table…")
        cursor.copy_expert(f'COPY {schema}.{temp_table_name} FROM STDIN', geofile)
    insert_grids_and_drop_temporary_table(schema, temp_table_name, area_type)


def downgrade():
    delete_area_with_type(area_type)
