import os
import sys
import subprocess
import site
import importlib
from pathlib import Path
import pkg_resources
from pkg_resources import iter_entry_points

import click
from click import ClickException

from geonature.utils.env import ROOT_DIR
from geonature.utils.module import get_dist_from_code, module_db_upgrade

from geonature.core.command.main import main
from geonature.utils.config import config
from geonature.utils.command import (
    install_frontend_dependencies,
    create_frontend_module_config,
    build_frontend,
)


@main.command()
@click.argument("module_path")
@click.argument("module_code")
@click.option("--build", type=bool, required=False, default=True)
@click.option("--upgrade-db", type=bool, required=False, default=True)
def install_gn_module(module_path, module_code, build, upgrade_db):
    click.echo("Installation du backend…")
    subprocess.run(f"pip install -e '{module_path}'", shell=True, check=True)

    # refresh list of entry points
    importlib.reload(site)
    for entry in sys.path:
        pkg_resources.working_set.add_entry(entry)

    # load python package
    module_dist = get_dist_from_code(module_code)
    if not module_dist:
        raise ClickException(f"Aucun module ayant pour code {module_code} n’a été trouvé")

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

    if upgrade_db:
        click.echo("Installation de la basse de données…")
        module_db_upgrade(module_dist)


@main.command()
@click.argument("module_codes", metavar="[MODULE_CODE]...", nargs=-1)
def upgrade_modules(module_codes):
    for module_code_entry in iter_entry_points("gn_module", "code"):
        module_code = module_code_entry.resolve()
        if module_codes and module_code not in module_codes:
            continue
        if module_code in config["DISABLED_MODULES"]:
            click.echo(f"Omission du module {module_code} (déactivé)")
            continue
        click.echo(f"Mise-à-jour du module {module_code}…")
        module_dist = module_code_entry.dist
        module_db_upgrade(module_dist)
