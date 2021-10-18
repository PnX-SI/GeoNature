"""
    Entry point for the command line 'geonature'
"""

import logging
from os import environ

import click
from flask.cli import run_command
import flask_migrate
from alembic.migration import MigrationContext
from alembic.context import EnvironmentContext
from alembic.script import ScriptDirectory
from flask_migrate.cli import db as db_cli
from flask.cli import with_appcontext

from geonature.utils.env import (
    db,
    migrate,
    DEFAULT_CONFIG_FILE,
    GEONATURE_VERSION,
)
from geonature.utils.command import (
    start_geonature_front,
    build_geonature_front,
    create_frontend_config,
    frontend_routes_templating,
    tsconfig_templating,
    tsconfig_app_templating,
    update_app_configuration,
)
from geonature import create_app
from geonature.core.gn_meta.mtd.mtd_utils import import_all_dataset_af_and_actors

# from rq import Queue, Connection, Worker
# import redis
from flask.cli import FlaskGroup


log = logging.getLogger()


@click.group(cls=FlaskGroup, create_app=create_app)
@click.version_option(version=GEONATURE_VERSION)
@click.pass_context
def main(ctx):
    pass


# Unused
# @main.command()
# def launch_redis_worker():
#     """ launch redis worker
#     """
#     app = create_app()
#     with app.app_context():
#         with Connection(redis.Redis(host='localhost', port='6379')):
#             q = Queue()
#             w = Worker(q)
#             w.work()


@main.command()
@click.option("--build", type=bool, required=False, default=True)
def generate_frontend_config(build):
    """
        Génération des fichiers de configurations pour javascript
        Relance le build du front par defaut
    """
    create_frontend_config()
    if build:
        build_geonature_front()
    log.info("Config successfully updated")


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
    if not environ.get('FLASK_ENV'):
        environ['FLASK_ENV'] = 'development'
    ctx.invoke(run_command, host=host, port=port)


@main.command()
def dev_front():
    """
        Démarre le frontend en mode develop
    """
    start_geonature_front()


@click.option("--build-sass", type=bool, default=False)
@main.command()
def frontend_build(build_sass):
    """
        Lance le build du frontend
    """
    build_geonature_front(build_sass)


@main.command()
def generate_frontend_modules_route():
    """
        Génere le fichier de routing du frontend
        à partir des modules GeoNature activé
    """
    frontend_routes_templating()


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
@click.option("--build", type=bool, required=False, default=True)
def update_configuration(build):
    """
        Regénère la configuration de l'application

        Example:

        - geonature update_configuration

        - geonature update_configuration --build=false (met à jour la configuration sans recompiler le frontend)

    """
    # Recréation du fichier de routing car il dépend de la conf
    frontend_routes_templating()
    update_app_configuration(build)


@main.command()
@click.argument('table_name')
def import_jdd_from_mtd(table_name):
    """
    Import les JDD et CA (et acters associé) à partir d'une table (ou vue) listant les UUID des JDD dans MTD
    """
    import_all_dataset_af_and_actors(table_name)


@db_cli.command()
@with_appcontext
def autoupgrade():
    config = migrate.get_config()
    script = ScriptDirectory.from_config(config)
    with EnvironmentContext(config, script) as env_context:
        env_context.configure(db.session.connection())
        heads = set(env_context.get_head_revisions())  # targets
        migration_context = env_context.get_context()
        current_heads = set(migration_context.get_current_heads())
    for head in current_heads - heads:
        revision = head + '@head'
        flask_migrate.upgrade(revision=revision)
