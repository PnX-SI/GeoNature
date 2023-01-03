"""
    Entry point for the command line 'geonature'
"""

import logging
from os import environ
from collections import ChainMap
from pkg_resources import iter_entry_points

import toml
import click
from flask.cli import run_command

from geonature.utils.env import GEONATURE_VERSION
from geonature.utils.command import (
    create_frontend_config,
)
from geonature import create_app
from geonature.core.gn_meta.mtd.mtd_utils import import_all_dataset_af_and_actors
from geonature.utils.config import config
from geonature.utils.config_schema import GnGeneralSchemaConf, GnPySchemaConf
from geonature.utils.command import (
    create_frontend_module_config,
    build_frontend,
)

from flask.cli import FlaskGroup


log = logging.getLogger()


def normalize(name):
    return name.replace("_", "-")


@click.group(
    cls=FlaskGroup,
    create_app=create_app,
    context_settings={"token_normalize_func": normalize},
)
@click.version_option(version=GEONATURE_VERSION)
@click.pass_context
def main(ctx):
    pass


@main.command()
@click.option("--host", default="0.0.0.0")
@click.option("--port", default=8000)
@click.pass_context
def dev_back(ctx, host, port):
    """
    Lance l'api du backend avec flask

    Exemples

    - geonature dev_back

    - geonature dev_back --port=8080 --port=0.0.0.0
    """
    if not environ.get("FLASK_DEBUG"):
        environ["FLASK_DEBUG"] = "true"
    ctx.invoke(run_command, host=host, port=port)


@main.command()
@click.option(
    "--input",
    "input_file",
    type=click.File("r"),
)
@click.option(
    "--output",
    "output_file",
    type=click.File("w"),
)
def generate_frontend_config(input_file, output_file):
    """
    Génération des fichiers de configurations pour javascript
    """
    create_frontend_config(input_file, output_file)
    click.echo(
        "Configuration générée. Pensez à rebuilder le frontend pour la production.", err=True
    )


@main.command()
@click.argument("module_code")
@click.option(
    "--output",
    "output_file",
    type=click.File("w"),
)
def generate_frontend_module_config(module_code, output_file):
    """
    Génère la config frontend d'un module

    Example:

    - geonature generate-frontend-module-config OCCTAX

    """
    create_frontend_module_config(module_code, output_file)
    click.echo(
        "Configuration générée. Pensez à rebuilder le frontend pour la production.", err=True
    )


@main.command()
@click.option("--modules", type=bool, required=False, default=True)
@click.option("--build", type=bool, required=False, default=True)
def update_configuration(modules, build):
    """
    Régénère la configuration du front et lance le rebuild.
    """
    click.echo("Génération de la configuration du frontend :")
    click.echo("  GeoNature … ", nl=False)
    create_frontend_config()
    click.secho("OK", fg="green")
    if modules:
        for module_code_entry in iter_entry_points("gn_module", "code"):
            module_code = module_code_entry.resolve()
            click.echo(f"  Module {module_code} … ", nl=False)
            if module_code in config["DISABLED_MODULES"]:
                click.secho("désactivé, ignoré", fg="white")
                continue
            click.secho("OK", fg="green")
            create_frontend_module_config(module_code)
    if build:
        click.echo("Rebuild du frontend …")
        build_frontend()
        click.secho("Rebuild du frontend terminé.", fg="green")


@main.command()
@click.argument("table_name")
def import_jdd_from_mtd(table_name):
    """
    Import les JDD et CA (et acters associé) à partir d'une table (ou vue) listant les UUID des JDD dans MTD
    """
    import_all_dataset_af_and_actors(table_name)


@main.command()
def default_config():
    """
    Afficher l’ensemble des paramètres et leur valeur par défaut.
    """
    required_fields = (
        "URL_APPLICATION",
        "API_ENDPOINT",
        "API_TAXHUB",
        "SECRET_KEY",
        "SQLALCHEMY_DATABASE_URI",
    )
    backend_defaults = GnPySchemaConf().load({}, partial=required_fields)
    frontend_defaults = GnGeneralSchemaConf().load({}, partial=required_fields)
    defaults = ChainMap(backend_defaults, frontend_defaults)
    print(toml.dumps(defaults))
