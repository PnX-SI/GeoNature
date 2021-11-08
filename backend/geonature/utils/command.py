"""   
    Fichier de création des commandes geonature
    Ce module ne doit en aucun cas faire appel à des models ou au coeur de geonature
    dans les imports d'entête de fichier pour garantir un bon fonctionnement des fonctions
    d'administration de l'application GeoNature (génération des fichiers de configuration, des 
    fichiers de routing du frontend etc...). Ces dernières doivent pouvoir fonctionner même si 
    un paquet PIP du requirement GeoNature n'a pas été bien installé
"""
import sys
import logging
import subprocess
import json

from flask import current_app
from jinja2 import Template
from pathlib import Path

from geonature import create_app
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
from geonature.utils.config import config_frontend

log = logging.getLogger(__name__)

MSG_OK = "\033[92mok\033[0m\n"


def start_geonature_front():
    subprocess.call(["npm", "run", "start"], cwd=str(ROOT_DIR / "frontend"))


def build_geonature_front(rebuild_sass=False):
    if rebuild_sass:
        subprocess.call(["npm", "rebuild", "node-sass", "--force"], cwd=str(ROOT_DIR / "frontend"))
    subprocess.call(["npm", "run", "build"], cwd=str(ROOT_DIR / "frontend"))


def frontend_routes_templating(app=None):
    if not app:
        app = create_app(with_external_mods=False)

    with app.app_context():

        log.info("Generating frontend routing")
        # recuperation de la configuration
        configs_gn = app.config

        with open(
            str(ROOT_DIR / "frontend/src/app/routing/app-routing.module.ts.sample"), "r"
        ) as input_file:
            template = Template(input_file.read())
            routes = []
            for module_object in list_frontend_enabled_modules():
                module_dir = Path(GN_EXTERNAL_MODULE / module_object.module_code.lower())
                # test if module have frontend
                if (module_dir / "frontend").is_dir():
                    path = module_object.module_path.lstrip("/")
                    location = "{}/{}#GeonatureModule".format(module_dir, GN_MODULE_FE_FILE)
                    routes.append({"path": path, "location": location, "module_code": module_object.module_code})

                # TODO test if two modules with the same name is okay for Angular

            route_template = template.render(
                routes=routes,
                enable_user_management=configs_gn["ACCOUNT_MANAGEMENT"].get("ENABLE_USER_MANAGEMENT"),
                enable_sign_up=configs_gn["ACCOUNT_MANAGEMENT"].get("ENABLE_SIGN_UP"),
            )

            with open(
                str(ROOT_DIR / "frontend/src/app/routing/app-routing.module.ts"), "w"
            ) as output_file:
                output_file.write(route_template)

        log.info("...%s\n", MSG_OK)


def tsconfig_templating():
    log.info("Generating tsconfig.json")
    with open(str(ROOT_DIR / "frontend/tsconfig.json.sample"), "r") as input_file:
        template = Template(input_file.read())
        tsconfig_templated = template.render(geonature_path=ROOT_DIR)

    with open(str(ROOT_DIR / "frontend/tsconfig.json"), "w") as output_file:
        output_file.write(tsconfig_templated)
    log.info("...%s\n", MSG_OK)


def tsconfig_app_templating(app=None):
    if not app:
        app = create_app(with_external_mods=False)

    with app.app_context():

        log.info("Generating tsconfig.app.json")

        with open(str(ROOT_DIR / "frontend/src/tsconfig.app.json.sample"), "r") as input_file:
            template = Template(input_file.read())
            routes = []
            for module in list_frontend_enabled_modules():
                module_dir = Path(GN_EXTERNAL_MODULE / module.module_code.lower())
                # test if module have frontend
                if (module_dir/ "frontend").is_dir():
                    location = "{}/frontend/app".format(module_dir)
                    routes.append({"location": location})

                # TODO test if two modules with the same name is okay for Angular

            route_template = template.render(routes=routes)

            with open(str(ROOT_DIR / "frontend/src/tsconfig.app.json"), "w") as output_file:
                output_file.write(route_template)

        log.info("...%s\n", MSG_OK)


def create_frontend_config():
    log.info("Generating configuration")

    with open(str(ROOT_DIR / "frontend/src/conf/app.config.ts.sample"), "r") as input_file:
        template = Template(input_file.read())
        parameters = json.dumps({
            **config_frontend,
            'ID_APPLICATION_GEONATURE': current_app.config['ID_APP'],
        }, indent=True)
        app_config_template = template.render(parameters=parameters)

        with open(str(ROOT_DIR / "frontend/src/conf/app.config.ts"), "w") as output_file:
            output_file.write(app_config_template)

    log.info("...%s\n", MSG_OK)


def update_app_configuration(build=True):
    log.info("Update app configuration")
    create_frontend_config()
    if build:
        subprocess.call(["npm", "run", "build"], cwd=str(ROOT_DIR / "frontend"))
    log.info("...%s\n", MSG_OK)
    log.info("Si vous avez changé des paramtères de configuration nécessaire au backend, "
             "pensez à également relancer ce dernier.")
