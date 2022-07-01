"""
    Fichier de création des commandes geonature
    Ce module ne doit en aucun cas faire appel à des models ou au coeur de geonature
    dans les imports d'entête de fichier pour garantir un bon fonctionnement des fonctions
    d'administration de l'application GeoNature (génération des fichiers de configuration, des
    fichiers de routing du frontend etc...). Ces dernières doivent pouvoir fonctionner même si
    un paquet PIP du requirement GeoNature n'a pas été bien installé
"""
import logging
import json
from contextlib import nullcontext

from jinja2 import Template
from pathlib import Path

from geonature import create_app
from geonature.utils.env import ROOT_DIR
from geonature.utils.config import config_frontend

log = logging.getLogger(__name__)

MSG_OK = "\033[92mok\033[0m\n"


def create_frontend_config(input_file=None, output_file=None):
    log.info("Generating configuration")

    if input_file is None:
        input_file = (ROOT_DIR / "frontend/src/conf/app.config.ts.sample").open("r")
    else:
        input_file = nullcontext(input_file)
    with input_file as f:
        template = Template(f.read())

    parameters = json.dumps(config_frontend, indent=True)
    app_config_template = template.render(parameters=parameters)

    if output_file is None:
        output_file = (ROOT_DIR / "frontend/src/conf/app.config.ts").open("w")
    else:
        ouptut_file = nullcontext(output_file)
    with output_file as f:
        f.write(app_config_template)

    log.info("...%s\n", MSG_OK)
