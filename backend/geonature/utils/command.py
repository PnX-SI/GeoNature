"""
    Fichier de création des commandes geonature
    Ce module ne doit en aucun cas faire appel à des models ou au coeur de geonature
    dans les imports d'entête de fichier pour garantir un bon fonctionnement des fonctions
    d'administration de l'application GeoNature (génération des fichiers de configuration, des
    fichiers de routing du frontend etc...). Ces dernières doivent pouvoir fonctionner même si
    un paquet PIP du requirement GeoNature n'a pas été bien installé
"""
import json
import subprocess
from contextlib import nullcontext

from jinja2 import Template

from geonature import create_app
from geonature.utils.env import FRONTEND_DIR
from geonature.utils.config import config_frontend
from geonature.utils.module import get_dist_from_code, get_module_config


def create_frontend_config(input_file=None, output_file=None):
    if input_file is None:
        input_file = (FRONTEND_DIR / "src/conf/app.config.ts.sample").open("r")
    else:
        input_file = nullcontext(input_file)
    with input_file as f:
        template = Template(f.read())

    parameters = json.dumps(config_frontend, indent=True)
    app_config_template = template.render(parameters=parameters)

    if output_file is None:
        output_file = (FRONTEND_DIR / "src/conf/app.config.ts").open("w")
    else:
        output_file = nullcontext(output_file)
    with output_file as f:
        f.write(app_config_template)


def create_frontend_module_config(module_code, output_file=None):
    """
    Create the frontend config
    """
    module_code = module_code.upper()
    module_config = get_module_config(get_dist_from_code(module_code))
    if output_file is None:
        output_file = (
            FRONTEND_DIR / "external_modules" / module_code.lower() / "app/module.config.ts"
        ).open("w")
    else:
        output_file = nullcontext(output_file)
    with output_file as f:
        f.write("export const ModuleConfig = ")
        json.dump(module_config, f, indent=True, sort_keys=True)


def install_frontend_dependencies(module_frontend_path):
    with (FRONTEND_DIR / ".nvmrc").open("r") as f:
        node_version = f.read().strip()
    subprocess.run(
        ["/bin/bash", "-i", "-c", f"nvm exec {node_version} npm ci --omit=dev --omit=peer"],
        check=True,
        cwd=module_frontend_path,
    )


def build_frontend():
    subprocess.run(
        ["/bin/bash", "-i", "-c", "nvm exec npm run build"],
        check=True,
        cwd=str(FRONTEND_DIR),
    )
