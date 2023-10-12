"""
    Entry point for the command line 'geonature'
"""

import logging
from os import environ
from collections import ChainMap

import toml
import click
from flask.cli import run_command

from geonature.utils.env import GEONATURE_VERSION
from geonature.utils.module import iter_modules_dist
from geonature import create_app
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
    click.secho("OK", fg="green")
    if modules:
        for dist in iter_modules_dist():
            module_code = dist.entry_points["code"].load()
            click.echo(f"  Module {module_code} … ", nl=False)
            if module_code in config["DISABLED_MODULES"]:
                click.secho("désactivé, ignoré", fg="white")
                continue
            create_frontend_module_config(module_code)
            click.secho("OK", fg="green")
    if build:
        click.echo("Rebuild du frontend …")
        build_frontend()
        click.secho("Rebuild du frontend terminé.", fg="green")


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


@click.argument("key", type=str, required=False)
@main.command()
def get_config(key=None):
    """
    Afficher l’ensemble des paramètres
    """
    printed_config = config.copy()
    if key:
        try:
            printed_config = printed_config[key]
        except KeyError:
            click.secho(f"The key {key} does not exist in config", fg="red")
            return
    if type(printed_config) is dict:
        print(toml.dumps(printed_config))
    else:
        print(printed_config)
