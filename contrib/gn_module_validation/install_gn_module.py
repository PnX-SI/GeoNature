import os
import subprocess
import psycopg2
from pathlib import Path

ROOT_DIR = Path(__file__).absolute().parent


def gnmodule_install_app(gn_db, gn_app):
    """
        Fonction principale permettant de réaliser les opérations d'installation du module :
    """
    # install frontend
    subprocess.call(["npm install"], cwd=str(ROOT_DIR / "frontend"), shell=True)

