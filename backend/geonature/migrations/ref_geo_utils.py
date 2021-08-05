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
