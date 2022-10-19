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
import pkg_resources
from pkg_resources import load_entry_point, get_entry_info
import sqlalchemy.orm.exc as sa_exc

import click
from click import ClickException
from flask import current_app
from flask_migrate import upgrade as db_upgrade

from geonature.utils.env import db, GN_EXTERNAL_MODULE
from geonature.utils.module import get_dist_from_code

from geonature.utils.command import (
    tsconfig_app_templating,
)
from geonature.core.command.main import main
from geonature.utils.gn_module_import import (
    gn_module_activate,
    gn_module_deactivate,
    install_frontend_dependencies,
    create_external_assets_symlink,
    create_module_config,
)
from geonature.utils.module import get_module_config_path
from geonature.core.gn_commons.models import TModules


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
        # generation du fichier de configuration du frontend
        create_module_config(module_code)

    log.info("Module installé, pensez à recompiler le frontend.")


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
@click.option(
    "--output",
    "output_file",
    type=click.File("w"),
)
def update_module_configuration(module_code, output_file):
    """
    Génère la config frontend d'un module

    Example:

    - geonature update-module-configuration OCCTAX

    """
    create_module_config(module_code, output_file)
    log.info("Pensez à rebuilder le frontend")
