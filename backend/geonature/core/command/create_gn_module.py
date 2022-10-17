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
import site
import importlib
from warnings import warn
import pkg_resources
from pkg_resources import load_entry_point, get_entry_info
from importlib import invalidate_caches
from pathlib import Path
import sqlalchemy.orm.exc as sa_exc

import click
from click import ClickException
from flask import current_app
from flask_migrate import upgrade as db_upgrade
from sqlalchemy.orm.exc import NoResultFound

from geonature.utils.env import DB, db, DEFAULT_CONFIG_FILE, GN_EXTERNAL_MODULE
from geonature.utils.module import get_dist_from_code

from geonature.utils.command import (
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
from geonature.utils.module import get_module_config_path
from geonature.utils.errors import GNModuleInstallError, GeoNatureError
from geonature.core.gn_commons.models import TModules
from geonature import create_app


log = logging.getLogger(__name__)


@main.command()
@click.argument("module_path")
@click.argument("module_code")
@click.option("--skip-frontend", is_flag=True)
def install_packaged_gn_module(module_path, module_code, skip_frontend):
    # install python package and dependencies
    subprocess.run(f"pip install -e '{module_path}'", shell=True, check=True)

    # refresh list of entry points
    importlib.reload(site)
    for entry in sys.path:
        pkg_resources.working_set.add_entry(entry)

    # load python package
    module_dist = get_dist_from_code(module_code)
    if not module_dist:
        raise ClickException(f"Unable to load module with code {module_code}")

    # add module to database
    try:
        module_picto = load_entry_point(module_dist, "gn_module", "picto")
    except ImportError:
        module_picto = "fa-puzzle-piece"
    try:
        module_type = load_entry_point(module_dist, "gn_module", "type")
    except ImportError:
        module_type = None
    try:
        module_object = TModules.query.filter_by(module_code=module_code).one()
        module_object.module_picto = module_picto
        db.session.merge(module_object)
    except sa_exc.NoResultFound:
        module_object = TModules(
            type=module_type,
            module_code=module_code,
            module_label=module_code.capitalize(),
            module_path=module_code.lower(),
            module_target="_self",
            module_picto=module_picto,
            active_frontend=True,
            active_backend=True,
            ng_module=module_code.lower(),
        )
        db.session.add(module_object)
    db.session.commit()

    info = get_entry_info(module_dist, "gn_module", "migrations")
    if info is not None:
        try:
            alembic_branch = load_entry_point(module_dist, "gn_module", "alembic_branch")
        except ImportError:
            alembic_branch = module_code.lower()
        db_upgrade(revision=alembic_branch + "@head")
    else:
        log.info("Module do not provide any migration files, skipping database upgrade.")

    # symlink module in exernal module directory
    module_symlink = GN_EXTERNAL_MODULE / module_code.lower()
    if os.path.exists(module_symlink):
        target = os.readlink(module_symlink)
        if os.path.realpath(module_path) != os.path.realpath(target):
            raise ClickException(f"Module symlink has wrong target: '{target}'")
    else:
        os.symlink(os.path.abspath(module_path), module_symlink)

    # creation du fichier conf_gn_module.toml
    module_config_path = get_module_config_path(module_object.module_code)
    module_config_path.touch(exist_ok=True)

    ### Frontend
    if not skip_frontend:
        # creation du lien symbolique des assets externes
        enable_frontend = create_external_assets_symlink(module_path, module_code.lower())

        install_frontend_dependencies(os.path.abspath(module_path))
        # generation du fichier tsconfig.app.json
        tsconfig_app_templating(app=current_app)
        # generation du routing du frontend
        frontend_routes_templating(app=current_app)
        # generation du fichier de configuration du frontend
        create_module_config(current_app, module_code)

    log.info("Module installé, pensez à recompiler le frontend.")


@main.command()
@click.argument("module_path")
@click.argument("url")  # url de l'api
@click.option("--conf-file", required=False, default=DEFAULT_CONFIG_FILE)
@click.option("--enable_backend", type=bool, required=False, default=True)
def install_gn_module(module_path, url, conf_file, enable_backend):
    """
    Installation d'un module gn
    """
    warn(
        "Cette commande sera supprimée au profit de la commande install_packaged_gn_module "
        "dans la prochaine version de GeoNature. Pensez à packager vos modules.",
        DeprecationWarning,
    )
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
                        tsconfig_app_templating(app=app)
                        # generation du routing du frontend
                        frontend_routes_templating(app=app)
                        # generation du fichier de configuration du frontend
                        create_module_config(app, module_code)

                    log.info("Pensez à relancer geonature (sudo systemctl restart geonature)")
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
def update_module_configuration(module_code):
    """
    Génère la config frontend d'un module

    Example:

    - geonature update-module-configuration OCCTAX

    """
    app = create_app(with_external_mods=False)
    with app.app_context():
        create_module_config(app, module_code)
    log.info(
        "Pensez à relancer geonature (sudo systemctl restart geonature) et rebuilder le frontend"
    )
