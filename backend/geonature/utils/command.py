import sys
import logging
import subprocess

from server import get_app
from geonature.utils.env import BACKEND_DIR, ROOT_DIR, load_config

from geonature.utils.errors import ConfigError

log = logging.getLogger(__name__)


def start_gunicorn_cmd(uri, worker):
    cmd = 'gunicorn server:app -w {gun_worker} -b {gun_uri}'
    subprocess.call(
        cmd.format(gun_worker=worker, gun_uri=uri).split(" "),
        cwd=str(BACKEND_DIR)
    )


def get_app_for_cmd(config_file=None):
    """ Return the flask app object, logging error instead of raising them"""
    try:
        return get_app(load_config(config_file))
    except ConfigError as e:
        log.critical(str(e) + "\n")
        sys.exit(1)


def supervisor_cmd(action, app_name):
    cmd = 'sudo supervisorctl {action} {app}'
    subprocess.call(cmd.format(action=action, app=app_name).split(" "))


def start_geonature_front():
    subprocess.call(['npm', 'run', 'start'], cwd=str(ROOT_DIR / 'frontend'))


def build_geonature_front(rebuild_sass=False):
    if rebuild_sass:
        subprocess.call(['npm', 'rebuild', 'node-sass', '--force'], cwd=str(ROOT_DIR / 'frontend'))
    subprocess.call(['npm', 'run', 'build'], cwd=str(ROOT_DIR / 'frontend'))

