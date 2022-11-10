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


def create_module_config(module_code, output_file=None):
    """
    Create the frontend config
    """
    module_code = module_code.upper()
    module_config = config[module_code]
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
