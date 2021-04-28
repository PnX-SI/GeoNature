"""   
    Fichier de création des commandes geonature
    Ce module ne doit en aucun cas faire appel à des models ou au coeur de geonature
    dans les imports d'entête de fichier pour garantir un bon fonctionnement des fonctions
    d'administration de l'application GeoNature (génération des fichiers de configuration, des 
    fichiers de routing du frontend etc...). Ces dernières doivent pouvoir fonctionner même si 
    un paquet PIP du requirement GeoNature n'a pas été bien installé
"""
import os
import sys
import logging
import subprocess
import json
import shutil

from jinja2 import Template
from pathlib import Path

# from geonature import create_app
from geonature.utils.env import (
    BACKEND_DIR,
    ROOT_DIR,
    GN_MODULE_FE_FILE,
    DB,
    GN_EXTERNAL_MODULE,
)
from geonature.utils.errors import ConfigError
from geonature.utils.utilstoml import load_and_validate_toml
from geonature.utils.config_schema import GnGeneralSchemaConf

from geonature.utils.module import list_frontend_enabled_modules
from geonature.utils.config import config_frontend, config
from geonature.utils.assets import extra_files

from geonature import create_app

log = logging.getLogger(__name__)

MSG_OK = "\033[92mok\033[0m\n"

def start_gunicorn_cmd(uri, worker):

    cmd = "gunicorn geonature.wsgi:app -w {gun_worker} -b {gun_uri}"
    subprocess.call(cmd.format(
        gun_worker=worker,
        gun_uri=uri
    ).split(" "), cwd=str(BACKEND_DIR))


def supervisor_cmd(action, app_name):
    cmd = "sudo supervisorctl {action} {app}"
    subprocess.call(cmd.format(action=action, app=app_name).split(" "))


def start_geonature_front():
    subprocess.call(["npm", "run", "start"], cwd=str(ROOT_DIR / "frontend"))


def build_geonature_front(rebuild_sass=False):
    if rebuild_sass:
        subprocess.call(["npm", "rebuild", "node-sass", "--force"], cwd=str(ROOT_DIR / "frontend"))
    subprocess.call(["npm", "run", "build"], cwd=str(ROOT_DIR / "frontend"))
