"""
    Entry point for the command line 'geonature'
"""

import logging
from os import environ
from collections import ChainMap

import toml
import click
from flask.cli import run_command

from geonature.utils.env import GEONATURE_VERSION, ROOT_DIR
from geonature.utils.command import (
    create_frontend_config,
    tsconfig_templating,
    tsconfig_app_templating,
)
from geonature.utils.config_schema import GnGeneralSchemaConf, GnPySchemaConf
from geonature import create_app
from geonature.core.gn_meta.mtd.mtd_utils import import_all_dataset_af_and_actors

# from rq import Queue, Connection, Worker
# import redis
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
@click.option(
    "--input",
    "input_file",
    type=click.File("r"),
    default=str(ROOT_DIR / "frontend/src/conf/app.config.ts.sample"),
)
@click.option(
    "--output",
    "output_file",
    type=click.File("w"),
    default=str(ROOT_DIR / "frontend/src/conf/app.config.ts"),
)
def generate_frontend_config(input_file, output_file):
    """
    Génération des fichiers de configurations pour javascript
    """
    create_frontend_config(input_file, output_file)
    log.info("Config successfully updated. Do not forget to rebuild frontend for production.")


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
def generate_frontend_tsconfig():
    """
    Génere tsconfig du frontend
    """
    tsconfig_templating()


@main.command()
def generate_frontend_tsconfig_app():
    """
    Génere tsconfig.app du frontend/src
    """
    tsconfig_app_templating()


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
