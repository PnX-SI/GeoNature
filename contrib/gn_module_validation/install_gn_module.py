import os
import subprocess
import psycopg2
from pathlib import Path

import logging

ROOT_DIR = Path(__file__).absolute().parent
GEONATURE_DIR = ROOT_DIR.parent.parent

db_handler = logging.FileHandler(
    str(GEONATURE_DIR / "var/log/install_validation.log"), mode="w"
)
db_handler.setLevel(logging.INFO)
db_logger = logging.getLogger("sqlalchemy")
db_logger.addHandler(db_handler)


def gnmodule_install_app(gn_db, gn_app):
    """
        Fonction principale permettant de réaliser les opérations d'installation du module :
    """
    # install frontend
    subprocess.call(["npm install"], cwd=str(ROOT_DIR / "frontend"), shell=True)

