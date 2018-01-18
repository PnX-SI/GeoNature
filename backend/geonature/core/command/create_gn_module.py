'''
    Fonction permettant d'ajouter un module tiers à GN

'''
import os

import click
import sys
import toml
import subprocess
import pip

from pathlib import Path
from packaging import version

from geonature.utils.env import (
    DB,
    GEONATURE_VERSION,
    GN_MODULE_FILES
)
from server import app

from geonature.core.command.main import main
from geonature.utils.gn_module_import import (
    check_gn_module_file,
    check_manifest,
    gnmodule_import_requirements,
    gn_module_register_config
)
from geonature.utils.errors import ConfigError

@main.command()
@click.argument('module_path')
def install_gn_module(module_path):
    """
        Installation d'un module gn
    """
    sys.path.append(module_path)
    # Vérification de la conformité du module
    #   Vérification de la présence de certain fichiers
    check_gn_module_file(module_path)

    #   Verification de la version de geonature par rapport au manifest
    module_name = check_manifest(module_path)

    # @TODO Vérification de la conformité du code : point d'entré pour l'api et le front

    # Installation du module
    run_install_gn_module(module_path, module_name)


def run_install_gn_module(module_path, module_name):
    '''
        Installation du module en executant :
            configurations
            install_env.sh
            installation des dépendances python
            install_db.py
            install_app.py
    '''
    #   configs
    gn_file = Path(module_path) / "conf_gn_module.toml"
    if gn_file.is_file():
        from conf_schema_toml import GnModuleSchemaConf
        cm = toml.load(str(gn_file))
        configs_py, configerrors = GnModuleSchemaConf().load(cm)
        if configerrors:
            raise ConfigError(configerrors)

    #   ENV
    gn_file = Path(module_path) / "install_env.sh"
    if gn_file.is_file():
        print("run install_env.sh")
        if os.access(str(gn_file), os.X_OK):
            subprocess.call([str(gn_file)], cwd=module_path)
            print("...ok")
        else:
            raise Exception("File {} not excecutable".format(str(gn_file)))

    #   requirements
    gnmodule_import_requirements(module_path)

    #   DB
    gn_file = Path(module_path) / "install_db.py"
    if gn_file.is_file():
        print("run install_db.py")
        from install_db import gnmodule_install_db
        gnmodule_install_db(DB, app)
        print("...ok")

    #   APP
    gn_file = Path(module_path) / "install_app.py"
    if gn_file.is_file():
        print("run install_db.py")
        from install_app import gnmodule_install_app
        gnmodule_install_app(DB, app)
        print("...ok")

    #   Enregistrement du module
    gn_module_register_config(module_name, module_path)


@main.command()
def activate_gn_module():
    """
        Active un module gn installé
    """
    pass
