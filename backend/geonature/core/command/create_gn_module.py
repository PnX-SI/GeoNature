"""
    Fonctions permettant d'ajouter un module tiers à GN
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

from pathlib import Path

import click
from sqlalchemy.orm.exc import NoResultFound

from geonature.utils.env import DB, DEFAULT_CONFIG_FILE

from geonature.utils.command import (
    build_geonature_front,
    tsconfig_app_templating,
)
from geonature.core.command.main import main
from geonature.utils.gn_module_import import (
    check_gn_module_file,
    check_manifest,
    gn_module_import_requirements,
    gn_module_register_config,
    gn_module_activate,
    gn_module_deactivate,
    install_frontend_dependencies,
    check_codefile_validity,
    create_external_assets_symlink,
    add_application_db,
    remove_application_db,
    create_module_config,
    copy_in_external_mods,
    frontend_routes_templating,
    MSG_OK,
)
from geonature.utils.errors import GNModuleInstallError, GeoNatureError
from geonature.core.gn_commons.models import TModules
from geonature import create_app


log = logging.getLogger(__name__)


@main.command()
@click.argument("module_path")
@click.argument("url")  # url de l'api
@click.option("--conf-file", required=False, default=DEFAULT_CONFIG_FILE)
@click.option("--build", type=bool, required=False, default=True)
@click.option("--enable_backend", type=bool, required=False, default=True)
def install_gn_module(module_path, url, conf_file, build, enable_backend):
    """
    Installation d'un module gn
    """
    try:

        # Indique si l'utilisateur est en train de
        #   réaliser une installation du module
        #   et non pas une mise à jour
        # Permet qu'en cas d'erreur à l'installation de supprimer
        #       les traces d'installation de ce module
        fresh_install = False
        # Vérification que le chemin module path soit correct
        if not Path(module_path).is_dir():
            raise GeoNatureError("dir {} doesn't exists".format(module_path))
        # TODO vérifier que l'utilisateur est root ou du groupe geonature
        app = create_app(with_external_mods=False)
        with app.app_context():
            sys.path.append(module_path)
            # Vérification de la conformité du module

            # Vérification de la présence de certain fichiers
            check_gn_module_file(module_path)
            # Vérification de la version de geonature par rapport au manifest
            module_code = None
            module_code = check_manifest(module_path)
            try:
                # Vérification que le module n'est pas déjà activé
                DB.session.query(TModules).filter(TModules.module_code == module_code).one()
            except NoResultFound:
                try:
                    # Si le module n'est pas déjà dans la table gn_commons.t_modules, on l'installe
                    # sinon on leve une execption et on arrête la commande

                    # Installation des dépendances python
                    gn_module_import_requirements(module_path)

                    # Vérification de la conformité du code :
                    #   installation
                    #   front end
                    #   backend
                    check_codefile_validity(module_path, module_code)

                    # copie dans external mods:
                    copy_in_external_mods(module_path, module_code.lower())

                    # creation du lien symbolique des assets externes
                    enable_frontend = create_external_assets_symlink(
                        module_path, module_code.lower()
                    )

                    # ajout du module dans la table gn_commons.t_modules
                    fresh_install = add_application_db(
                        app, module_code, url, enable_frontend, enable_backend
                    )

                    # Installation du module
                    run_install_gn_module(app, module_path)
                    # Enregistrement de la config du module
                    gn_module_register_config(module_code)

                    if enable_frontend:
                        install_frontend_dependencies(module_path)
                        # generation du fichier tsconfig.app.json
                        tsconfig_app_templating(
                            module_code=module_code,
                            app=app
                        )
                        # generation du routing du frontend
                        frontend_routes_templating(
                            app=app
                        )
                        # generation du fichier de configuration du frontend
                        create_module_config(app, module_code, build=False)
                    if build and enable_frontend:
                        # Rebuild the frontend
                        build_geonature_front(rebuild_sass=True)

                    # finally restart geonature backend via supervisor
                    subprocess.call(["sudo", "supervisorctl", "restart", "geonature2"])
                except Exception as e:
                    log.error("%s", e)
                    raise GeoNatureError(
                        "Error during module {} installation".format(module_code)
                    )  # noqa

            else:
                raise GeoNatureError(
                    "The module {} is already installed, but maybe not activated".format(
                        module_code
                    )
                )  # noqa

    except (GNModuleInstallError, GeoNatureError) as ex:
        log.critical(
            (
                "\n\n\033[91mError while installing GN module \033[0m.The process returned:\n\t{}"
            ).format(ex)
        )
        # S'il y a une erreur lors de l'installation initiale du module
        #   suppression de ce module
        if fresh_install:
            remove_application_db(app, module_code)

        sys.exit(1)


def run_install_gn_module(app, module_path):
    """
    Installation du module en executant :
        configurations
        install_env.sh
        install_db.py
        install_app.py
    """

    #   ENV
    gn_file = Path(module_path) / "install_env.sh"
    log.info("run install_env.sh")

    try:
        subprocess.call([str(gn_file)], cwd=str(module_path))
        log.info("...%s\n", MSG_OK)
    except FileNotFoundError:
        pass
    except OSError as ex:

        if ex.errno == 8:
            raise GNModuleInstallError(
                (
                    "Unable to execute '{}'. One possible reason is " "the lack of shebang line."
                ).format(gn_file)
            )

        if os.access(str(gn_file), os.X_OK):
            # TODO: try to make it executable
            # TODO: change exception type
            # TODO: make error message
            raise GNModuleInstallError("File {} not excecutable".format(str(gn_file)))

    #   APP
    gn_file = Path(module_path) / "install_gn_module.py"
    if gn_file.is_file():
        log.info("run install_gn_module.py")
        from install_gn_module import gnmodule_install_app

        gnmodule_install_app(DB, app)
        log.info("...%s\n", MSG_OK)


@click.option("--frontend", type=bool, required=False, default=True)
@click.option("--backend", type=bool, required=False, default=True)
@main.command()
@click.argument("module_code")
def activate_gn_module(module_code, frontend, backend):
    """
    Active un module gn installé

    Exemples:
    # Active que le backend du module occtax
    - geonature activate_gn_module occtax --frontend=false
    # Active que le frontend du module occtax)
    - geonature activate_gn_module occtax --backend=false

    """
    # TODO vérifier que l'utilisateur est root ou du groupe geonature
    gn_module_activate(module_code.upper(), frontend, backend)


@click.option("--frontend", type=bool, required=False, default=True)
@click.option("--backend", type=bool, required=False, default=True)
@main.command()
@click.argument("module_code")
def deactivate_gn_module(module_code, frontend, backend):
    """
    Desactive un module gn activé


    Exemples:
    # Désactive que le backend du module occtax
    - geonature deactivate_gn_module occtax --frontend=false
    # Désactive que le frontend du module occtax
    - geonature deactivate_gn_module occtax --backend=false (

    """
    # TODO vérifier que l'utilisateur est root ou du groupe geonature
    gn_module_deactivate(module_code.upper(), frontend, backend)


@main.command()
@click.argument("module_code")
@click.option("--build", type=bool, required=False, default=True)
@click.option("--prod", type=bool, required=False, default=True)
def update_module_configuration(module_code, build, prod):
    """
    Génère la config frontend d'un module

    Example:

    - geonature update_module_configuration occtax

    - geonature update_module_configuration --build False --prod False occtax

    """
    if prod:
        subprocess.call(["sudo", "supervisorctl", "reload"])
    app = create_app(with_external_mods=False)
    create_module_config(app, module_code, build=build)
