"""Insert default French DEM (IGN 250m BD alti)

Revision ID: 1715cf31a75d
Create Date: 2021-09-27 22:58:27.235271

"""
import os.path
from zipfile import ZipFile
from urllib.parse import urlsplit
import subprocess
from tempfile import TemporaryDirectory

from alembic import op, context
import sqlalchemy as sa

from geonature.utils.config import config
from utils_flask_sqla.migrations.utils import logger, open_remote_file


# revision identifiers, used by Alembic.
revision = "1715cf31a75d"
down_revision = None
branch_labels = ("ign_bd_alti",)
depends_on = ("6afe74833ed0",)  # ref_geo

base_url = "http://geonature.fr/data/ign/"
archive_name = "BDALTIV2_2-0_250M_ASC_LAMB93-IGN69_FRANCE_2017-06-21.zip"
file_name = "BDALTIV2_250M_FXX_0098_7150_MNT_LAMB93_IGN69.asc"


def upgrade():
    try:
        local_srid = context.get_x_argument(as_dictionary=True)["local-srid"]
    except KeyError:
        raise Exception("Missing local srid, please use -x local-srid=...")
    with TemporaryDirectory() as temp_dir:
        with open_remote_file(base_url, archive_name, open_fct=ZipFile) as archive:
            archive.extract(file_name, path=temp_dir)
        path = os.path.join(temp_dir, file_name)
        cmd = f"raster2pgsql -s {local_srid} -c -C -I -M -d -t 5x5 {path} ref_geo.dem | psql"
        db_uri = urlsplit(config["SQLALCHEMY_DATABASE_URI"])
        env = {
            "PGHOST": db_uri.hostname,
            "PGPORT": str(db_uri.port),
            "PGUSER": db_uri.username,
            "PGPASSWORD": db_uri.password,
            "PGDATABASE": db_uri.path.lstrip("/"),
        }
        subprocess.run(cmd, stdout=subprocess.DEVNULL, shell=True, check=True, env=env)
    logger.info("Refresh DEM spatial index…")
    op.execute("REINDEX INDEX ref_geo.dem_st_convexhull_idx")


def downgrade():
    op.execute("TRUNCATE ref_geo.dem")
