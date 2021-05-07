"""
    Entry point for the command line 'geonature'
"""

import logging
from os import environ, path, listdir

import click

from geonature.utils.env import (
    DEFAULT_CONFIG_FILE,
    GEONATURE_VERSION,
ROOT_DIR,
)
from geonature.utils.command import (
    start_gunicorn_cmd,
    supervisor_cmd,
    start_geonature_front,
    build_geonature_front,
)

from geonature.utils.assets import extra_files
from geonature import create_app

# from rq import Queue, Connection, Worker
# import redis
from flask import Flask


log = logging.getLogger()


@click.group()
@click.version_option(version=GEONATURE_VERSION)
@click.pass_context
def main(ctx):
    pass


@main.command()
@click.option("--uri", default="0.0.0.0:8000")
@click.option("--worker", default=4)
def start_gunicorn(uri, worker):
    """
        Lance l'api du backend avec gunicorn
    """
    start_gunicorn_cmd(uri, worker)


@main.command()
@click.option("--host", default="0.0.0.0")
@click.option("--port", default=8000)
def dev_back(host, port):
    """
        Lance l'api du backend avec flask

        Exemples

        - geonature dev_back

        - geonature dev_back --port=8080 --port=0.0.0.0
    """
    if not environ.get('FLASK_ENV'):
        environ['FLASK_ENV'] = 'development'

    app = create_app()
    app.run(
        host=host,
        port=int(port),
        extra_files=extra_files()
    )


@main.command()
@click.option("--action", default="restart", type=click.Choice(["start", "stop", "restart"]))
@click.option("--app_name", default="geonature2")
def supervisor(action, app_name):
    """
        Lance les actions du supervisor
    """
    supervisor_cmd(action, app_name)


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
@click.argument('table_name')
def import_jdd_from_mtd(table_name):
    """
    Import les JDD et CA (et acters associé) à partir d'une table (ou vue) listant les UUID des JDD dans MTD
    """
    app = create_app()
    with app.app_context():
        from geonature.core.gn_meta.mtd.mtd_utils import import_all_dataset_af_and_actors
        import_all_dataset_af_and_actors(table_name)    
