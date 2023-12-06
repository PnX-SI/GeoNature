import importlib
import os
import site
import subprocess
import sys
from pathlib import Path

import pathlib  # For testing purposes
import click
import geonature.utils.config
from click import ClickException
from geonature.core.command.main import main
from geonature.utils.command import (
    build_frontend,
    create_frontend_module_config,
    install_frontend_dependencies,
)
from geonature.utils.config import config
from geonature.utils.env import ROOT_DIR
from geonature.utils.module import get_dist_from_code, iter_modules_dist, module_db_upgrade


@main.command()
@click.option(
    "-x", "--x-arg", multiple=True, help="Additional arguments consumed by custom env.py scripts"
)
@click.argument("module_path", type=click.Path(exists=True, file_okay=False, path_type=Path))
@click.argument("module_code", required=False)
@click.option("--build", type=bool, required=False, default=True)
@click.option("--upgrade-db", type=bool, required=False, default=True)
def install_gn_module(x_arg, module_path, module_code, build, upgrade_db):
    """
    Command definition to install a GeoNature module

    Parameters
    ----------
    x_arg : list
        additional arguments
    module_path : str
        path of the module directory
    module_code : str
        code of the module, deprecated in future release
    build : boolean
        is the frontend rebuild
    upgrade_db : boolean
        migrate the revision associated with the module

    Raises
    ------
    ClickException
        No module found with the given module code
    ClickException
        No module code was detected in the code
    """
    click.echo("Installation du backend…")
    subprocess.run(f"pip install -e '{module_path}'", shell=True, check=True)

    # refresh list of entry points
    importlib.reload(site)
    importlib.reload(geonature.utils.config)

    if module_code:
        # load python package
        module_dist = get_dist_from_code(module_code)
        if not module_dist:  # FIXME : technically can't go there...
            raise ClickException(f"Aucun module ayant pour code {module_code} n’a été trouvé")
    else:
        for module_dist in iter_modules_dist():
            module = module_dist.entry_points["code"].module
            if module not in sys.modules:
                path = Path(importlib.import_module(module).__file__)
            else:
                path = Path(sys.modules[module].__file__)
            if module_path.resolve() in path.parents:
                module_code = module_dist.entry_points["code"].load()
                break
        else:
            raise ClickException(
                f"Impossible de détecter le code du module, essayez de le spécifier."
            )
    # symlink module in exernal module directory
    module_frontend_path = (module_path / "frontend").resolve()
    module_symlink = ROOT_DIR / "frontend" / "external_modules" / module_code.lower()
    if os.path.exists(module_symlink):
        if module_frontend_path != os.readlink(module_symlink):
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
        click.echo("Installation / mise à jour de la base de données…")
        if not module_db_upgrade(module_dist, x_arg=x_arg):
            click.echo(
                "Le module est déjà déclaré en base. "
                "Installation de la base de données ignorée."
            )


@main.command()
@click.option(
    "-d",
    "--directory",
    default=None,
    help=('Migration script directory (default is "migrations")'),
)
@click.option(
    "--sql", is_flag=True, help=("Don't emit SQL to database - dump to standard output " "instead")
)
@click.option(
    "--tag", default=None, help=('Arbitrary "tag" name - can be used by custom env.py ' "scripts")
)
@click.option(
    "-x", "--x-arg", multiple=True, help="Additional arguments consumed by custom env.py scripts"
)
@click.argument("module_codes", metavar="[MODULE_CODE]...", nargs=-1)
def upgrade_modules_db(directory, sql, tag, x_arg, module_codes):
    for module_dist in iter_modules_dist():
        module_code = module_dist.entry_points["code"].load()
        if module_codes and module_code not in module_codes:
            continue
        if module_code in config["DISABLED_MODULES"]:
            click.echo(f"Omission du module {module_code} (déactivé)")
            continue
        click.echo(f"Mise-à-jour du module {module_code}…")
        if not module_db_upgrade(module_dist, directory, sql, tag, x_arg):
            click.echo(
                "Le module est déjà déclaré en base. "
                "Installation de la base de données ignorée."
            )
