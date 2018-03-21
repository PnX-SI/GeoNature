'''
    Fonctions permettant d'ajouter un module tiers à GN
'''

import os
import sys
import logging
import subprocess

from pathlib import Path

import click

from geonature.utils.env import (
    DB,
    DEFAULT_CONFIG_FIlE,
    GN_MODULES_ETC_ENABLED
)

from geonature.utils.command import (
    get_app_for_cmd,
    build_geonature_front
)
from geonature.core.command.main import main
from geonature.utils.gn_module_import import (
    check_gn_module_file,
    check_manifest,
    gn_module_import_requirements,
    gn_module_register_config,
    gn_module_activate,
    gn_module_deactivate,
    check_codefile_validity,
    create_external_assets_symlink,
    add_application_db
)
from geonature.utils.errors import (
    ConfigError, GNModuleInstallError, GeoNatureError
)
from geonature.utils.utilstoml import load_and_validate_toml

log = logging.getLogger(__name__)


@main.command()
@click.argument('module_path')
@click.argument('url')  # url de l'api
@click.option(
    '--conf-file',
    required=False,
    default=DEFAULT_CONFIG_FIlE
)
def install_gn_module(module_path, url, conf_file):
    """
        Installation d'un module gn
    """
    # Installation du module
    module_name = ''
    try:
        # Vérification que le chemin module path soit correct
        if not Path(module_path).is_dir():
            raise GeoNatureError("dir {} doesn't exists".format(module_path))

        # TODO vérifier que l'utilisateur est root ou du groupe geonature
        app = get_app_for_cmd(conf_file)

        sys.path.append(module_path)
        # Vérification de la conformité du module
        #   Vérification de la présence de certain fichiers
        check_gn_module_file(module_path)

        #   Vérification de la version de geonature par rapport au manifest
        try:
            module_name = check_manifest(module_path)
            # Vérification que le module n'est pas déjà activé
            if (GN_MODULES_ETC_ENABLED / module_name).is_symlink():
                raise GeoNatureError("...module {} already activated".format(module_name))
        except ConfigError as ex:
            log.critical(str(ex) + "\n")
            sys.exit(1)

        # Vérification de la conformité du code :
        #   installation
        #   front end
        #   backend
        check_codefile_validity(module_path, module_name)

        # Installation du module
        run_install_gn_module(app, module_path, module_name, url)
        # Activation du module
        gn_module_activate(module_name)
        # Rebuild the frontend
        build_geonature_front(rebuild_sass=True)

    except (GNModuleInstallError, GeoNatureError) as ex:
        log.critical((
            "\n\nError while installing GN module '{}'.The process returned:\n\t{}"
        ).format(module_name, ex))
        sys.exit(1)


def run_install_gn_module(app, module_path, module_name, url):
    '''
        Installation du module en executant :
            configurations
            install_env.sh
            installation des dépendances python
            install_db.py
            install_app.py
    '''
    #   configs
    try:
        from conf_schema_toml import GnModuleSchemaConf
        load_and_validate_toml(
            Path(module_path) / "conf_gn_module.toml",
            GnModuleSchemaConf
        )
    except ImportError:
        log.info('No specific config file')
        pass

    #   requirements
    gn_module_import_requirements(module_path)

    #   ENV
    gn_file = Path(module_path) / "install_env.sh"
    log.info("run install_env.sh")

    try:
        subprocess.call([str(gn_file)], cwd=str(module_path))
        log.info("...ok\n")
    except FileNotFoundError:
        pass
    except OSError as ex:

        if ex.errno == 8:
            raise GNModuleInstallError((
                "Unable to execute '{}'. One possible reason is "
                "the lack of shebang line."
            ).format(gn_file))

        if os.access(str(gn_file), os.X_OK):
            # TODO: try to make it executable
            # TODO: change exception type
            # TODO: make error message
            # TODO: change print to log
            raise GNModuleInstallError(
                "File {} not excecutable".format(str(gn_file))
            )

    #   APP
    gn_file = Path(module_path) / "install_gn_module.py"
    if gn_file.is_file():
        log.info("run install_gn_module.py")
        from install_gn_module import gnmodule_install_app
        gnmodule_install_app(DB, app)
        log.info("...ok\n")

    #   Enregistrement du module
    gn_module_register_config(module_name, module_path, url)

    # ajout du module dans la table users.t_application
    add_application_db(module_name)
    # creation du lien symbolique des assets externes
    create_external_assets_symlink(module_path, module_name)


@main.command()
@click.argument('module_name')
def activate_gn_module(module_name):
    """
        Active un module gn installé
    """
    # TODO vérifier que l'utilisateur est root ou du groupe geonature
    gn_module_activate(module_name)


@main.command()
@click.argument('module_name')
def deactivate_gn_module(module_name):
    """
        Desactive un module gn activé
    """
    # TODO vérifier que l'utilisateur est root ou du groupe geonature
    gn_module_deactivate(module_name)
