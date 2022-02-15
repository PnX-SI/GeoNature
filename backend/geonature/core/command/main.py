"""
    Entry point for the command line 'geonature'
"""

import logging
from os import environ
from collections import ChainMap

import toml
import click
from flask.cli import run_command
import flask_migrate
import alembic
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


@main.command()
def default_config():
    """
        Afficher l’ensemble des paramètres et leur valeur par défaut.
    """
    required_fields = (
        'URL_APPLICATION',
        'API_ENDPOINT',
        'API_TAXHUB',

        'SECRET_KEY',
        'SQLALCHEMY_DATABASE_URI',
    )
    backend_defaults = GnPySchemaConf().load({}, partial=required_fields)
    frontend_defaults = GnGeneralSchemaConf().load({}, partial=required_fields)
    defaults = ChainMap(backend_defaults, frontend_defaults)
    print(toml.dumps(defaults))


@db_cli.command()
@click.option('-d', '--directory', default=None,
              help=('Migration script directory (default is "migrations")'))
@click.option('--sql', is_flag=True,
              help=('Don\'t emit SQL to database - dump to standard output '
                    'instead'))
@click.option('--tag', default=None,
              help=('Arbitrary "tag" name - can be used by custom env.py '
                    'scripts'))
@click.option('-x', '--x-arg', multiple=True,
              help='Additional arguments consumed by custom env.py scripts')
@with_appcontext
def autoupgrade(directory, sql, tag, x_arg):
    config = migrate.get_config(directory, x_arg)
    script = ScriptDirectory.from_config(config)
    heads = set(script.get_heads())
    migration_context = MigrationContext.configure(db.session.connection())
    current_heads = migration_context.get_current_heads()
    # get_current_heads does not return implicit revision through dependecies, get_all_current does
    current_heads = set(map(lambda rev: rev.revision, script.get_all_current(current_heads)))
    for head in current_heads - heads:
        revision = head + '@head'
        flask_migrate.upgrade(directory, revision, sql, tag, x_arg)


@db_cli.command()
@click.option('-d', '--directory', default=None,
              help=('Migration script directory (default is "migrations")'))
@click.option('-x', '--x-arg', multiple=True,
              help='Additional arguments consumed by custom env.py scripts')
@with_appcontext
def status(directory, x_arg):
    """Show all revisions sorted by branches."""
    config = migrate.get_config(directory, x_arg)
    script = ScriptDirectory.from_config(config)
    migration_context = MigrationContext.configure(db.session.connection())
    current_heads = migration_context.get_current_heads()
    unknown_heads = []
    for head in current_heads:
        try:
            script.get_revision(head)
        except alembic.util.exc.CommandError:
            unknown_heads.append(head)
    if unknown_heads:
        current_heads = set()
    else:
        current_heads = script.get_all_current(current_heads)
    outdated = False
    bases = [ script.get_revision(base) for base in script.get_bases() ]
    for rev in sorted(bases, key=lambda rev: next(iter(rev.branch_labels))):
        branch, = rev.branch_labels
        rev_list = [rev]
        while rev.nextrev:
            nextrev, = rev.nextrev
            rev = script.get_revision(nextrev)
            rev_list.append(rev)
        enabled_branch = set(rev_list) & current_heads
        fg = 'white' if enabled_branch else None
        if enabled_branch:
            if rev_list[-1] in current_heads:
                fg = 'white'
                check = ' ✓'
            else:
                fg = 'red'
                check = ' ×'
                outdated = True
        else:
            fg = None
            check = ''
        click.secho(f"[{branch}{check}]", bold=True, fg=fg)
        applied = enabled_branch
        for i, rev in enumerate(rev_list, 1):
            fg = 'white' if applied else 'red' if enabled_branch else None
            check = 'x' if applied else ' '
            click.secho(f"  [{check}] {i:04d} ({rev.revision}) {rev.doc}", fg=fg)
            if rev in current_heads:
                applied = False
    if unknown_heads:
       click.secho("⚠ UNABLE TO CHECK DATABASE STATUS ⚠", bold=True, fg="red")
       click.secho("These revisions are present in alembic version table "
                   "but their script was not found:", bold=True, fg="red")
       for unknown_head in unknown_heads:
           click.secho(f"  · {unknown_head}", bold=True, fg="red")
    elif outdated:
        click.secho("Some branches are outdated, you can upgrade with: geonature db autoupgrade", fg="red")
