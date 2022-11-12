"""
    Fonctions utilisés pour l'installation et le chargement
    d'un nouveau module geonature
"""
import subprocess
import logging
import os
import json
from contextlib import ExitStack

from pathlib import Path
from sqlalchemy.orm.exc import NoResultFound

from geonature.utils.config import config
from geonature.utils.errors import GeoNatureError
from geonature.utils.module import get_dist_from_code, get_module_config
from geonature.core.gn_commons.models import TModules
from geonature import create_app

from geonature.utils.env import (
    ROOT_DIR,
    DB,
)

log = logging.getLogger(__name__)

MSG_OK = "\033[92mok\033[0m\n"


def gn_module_activate(module_code, activ_front, activ_back):
    # TODO utiliser les commande os de python
    log.info("Activate module")

    app = None
    # TODO gestion des erreurs
    if module_code in config["DISABLED_MODULES"]:
        raise GeoNatureError("Module {} is not activated".format(module_code))
    else:
        app = create_app()
        with app.app_context():
            try:
                module = (
                    DB.session.query(TModules)
                    .filter(TModules.module_code == module_code.upper())
                    .one()
                )
                module.active_frontend = activ_front
                module.active_backend = activ_back
                DB.session.merge(module)
                DB.session.commit()
            except NoResultFound:
                raise GeoNatureError(
                    """The module does not exist.
                    \n Check the gn_commons.t_module to get the module name"""
                )


def gn_module_deactivate(module_code, activ_front, activ_back):
    log.info("Desactivate module")

    app = None
    try:
        app = create_app()
        with app.app_context():
            module = (
                DB.session.query(TModules)
                .filter(TModules.module_code == module_code.upper())
                .one()
            )
            module.active_frontend = not activ_front
            module.active_backend = not activ_back
            DB.session.merge(module)
            DB.session.commit()
    except NoResultFound:
        raise GeoNatureError(
            """The module does not exist.
            \n Check the gn_commons.t_module to get the module name"""
        )


def create_external_assets_symlink(module_path, module_code):
    """
    Create a symlink for the module assets
    return True if module have a frontend. False otherwise
    """
    module_assets_dir = os.path.join(os.path.abspath(module_path), "frontend/assets")

    # test if module have frontend
    if not Path(module_assets_dir).is_dir():
        log.info("No frontend for this module \n")
        return False

    geonature_asset_symlink = os.path.join(
        str(ROOT_DIR), "frontend/src/external_assets", module_code
    )
    # create the symlink if not exist
    try:
        if not os.path.isdir(geonature_asset_symlink):
            log.info("Create a symlink for assets \n")
            assert (
                subprocess.call(
                    ["ln", "-s", module_assets_dir, module_code],
                    cwd=str(ROOT_DIR / "frontend/src/external_assets"),
                )
                == 0
            )
        else:
            log.info("symlink already exist \n")

        log.info("...%s\n", MSG_OK)
    except Exception as exp:
        log.info("...error when create symlink external assets \n")
        raise GeoNatureError(exp)
    return True


def install_frontend_dependencies(module_path):
    """
    Install module frontend dependencies in the GN node_modules directory
    """
    log.info("Installing JS dependencies...")
    frontend_module_path = Path(module_path) / "frontend"
    if (frontend_module_path / "package.json").is_file():
        try:
            subprocess.check_call(
                ["/bin/bash", "-i", "-c", "nvm use"], cwd=str(ROOT_DIR / "frontend")
            )
            try:
                subprocess.check_call(
                    ["npm", "ci"],
                    cwd=str(frontend_module_path),
                )
            except subprocess.CalledProcessError:  # probably missing package-lock.json
                subprocess.check_call(
                    ["npm", "install"],
                    cwd=str(frontend_module_path),
                )
        except Exception as ex:
            log.info("Error while installing JS dependencies")
            raise GeoNatureError(ex)
    else:
        log.info("No package.json - skip js packages installation")
    log.info("...%s\n", MSG_OK)


def create_frontend_module_config(module_code, output_file=None):
    """
    Create the frontend config
    """
    module_code = module_code.upper()
    module_config = get_module_config(get_dist_from_code(module_code))
    with ExitStack() as stack:
        if output_file is None:
            frontend_config_path = (
                ROOT_DIR
                / "frontend"
                / "external_modules"
                / module_code.lower()
                / "app"
                / "module.config.ts"
            )
            output_file = stack.enter_context(open(str(frontend_config_path), "w"))
        output_file.write("export const ModuleConfig = ")
        json.dump(module_config, output_file, indent=True, sort_keys=True)
