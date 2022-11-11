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
from pathlib import Path
import pkg_resources
from pkg_resources import load_entry_point, get_entry_info
import sqlalchemy.orm.exc as sa_exc

import click
from click import ClickException
from flask import current_app
from flask_migrate import upgrade as db_upgrade

from geonature.utils.env import db, ROOT_DIR
from geonature.utils.module import get_dist_from_code

from geonature.core.command.main import main
from geonature.utils.command import (
    install_frontend_dependencies,
    create_frontend_module_config,
    build_frontend,
)
from geonature.utils.module import get_module_config_path
from geonature.core.gn_commons.models import TModules


log = logging.getLogger(__name__)


@main.command()
@click.argument("module_path")
@click.argument("module_code")
@click.option("--build", type=bool, required=False, default=True)
def install_gn_module(module_path, module_code, build):
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
    module_frontend_path = os.path.realpath(f"{module_path}/frontend")
    module_symlink = ROOT_DIR / "frontend" / "external_modules" / module_code.lower()
    if os.path.exists(module_symlink):
        if module_frontend_path != os.path.realpath(os.readlink(module_symlink)):
            click.echo(f"Correction du lien symbolique {module_symlink} → {module_frontend_path}")
            os.unlink(module_symlink)
            os.symlink(module_frontend_path, module_symlink)
    else:
        click.echo(f"Création du lien symbolique {module_symlink} → {module_frontend_path}")
        os.symlink(module_frontend_path, module_symlink)

    if (Path(module_path) / "frontend" / "package-lock.json").is_file():
        click.echo("Installation des dépendances frontend…")
        install_frontend_dependencies(module_frontend_path)

    click.echo("Création de la configuration frontend…")
    create_frontend_module_config(module_code)

    if build:
        click.echo("Rebuild du frontend …")
        build_frontend()
        click.secho("Rebuild du frontend terminé.", fg="green")
