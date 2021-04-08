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
from geonature.utils.module import import_frontend_enabled_modules
from geonature.utils.config import config_frontend, config

log = logging.getLogger(__name__)

MSG_OK = "\033[92mok\033[0m\n"

def start_gunicorn_cmd(uri, worker):
    cmd = "gunicorn geonature.wsgi:app -w {gun_worker} -b {gun_uri} --reload-extra-file={extra_files}"
    subprocess.call(cmd.format(
        gun_worker=worker,
        gun_uri=uri,
        extra_files=ROOT_DIR / str('config/*.toml')
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


def process_prebuild_frontend(app=None):
    if not app:
        app = create_app(with_external_mods=False)

    with app.app_context():
        log.info("Process prebuild frontend")
        # recuperation de la configuration
        configs_gn = app.config

        with open(
            str(ROOT_DIR / "external_modules/index.ts.sample"), "r"
        ) as input_file:
            template = Template(input_file.read())
            modules = []
            for module_config in import_frontend_enabled_modules():
                location = Path(GN_EXTERNAL_MODULE / module_config['MODULE_PATH'])

                # test if module have frontend
                if (location / "frontend").is_dir():
                    modules.append(module_config)

            route_template = template.render(
                modules=modules,
            )

            with open(
                str(ROOT_DIR / "external_modules/index.ts"), "w"
            ) as output_file:
                output_file.write(route_template)

        log.info("...%s\n", MSG_OK)


def process_manage_frontend_assets():
    '''
        Ici on cherche à rendre le build du frontend 'indépendant' de la config
        Pour cela on crée directement des fichiers dans les assets du frontend, 
        dans les repertoires 'frontend/dist' et 'frontend/src'

        Les fichiers concernés:
            - pour fournir API_ENDPOINT au frontend :
                - config/api.config.json
    '''

    for mode in ['src', 'dist']:
        assets_dir = str(ROOT_DIR / "frontend/{}/assets".format(mode))
        if not os.path.exists(assets_dir):
            os.makedirs(assets_dir)

        assets_config_dir =  assets_dir + "/config"
        if not os.path.exists(assets_config_dir):
            os.makedirs(assets_config_dir)

        path = assets_config_dir + "/api.config.json"
        with open(path, "w") as outputfile:
            outputfile.write('"{}"'.format(config['API_ENDPOINT']))
