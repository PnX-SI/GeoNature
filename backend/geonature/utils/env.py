
""" Helpers to manipulate the execution environment """
import subprocess
import os
import sys
import toml
import json
from pathlib import Path

from collections import namedtuple
from config_schema import GnGeneralSchemaConf, ConfigError


ROOT_DIR = Path(__file__).absolute().parent.parent.parent.parent
BACKEND_DIR = ROOT_DIR / 'backend'
DEFAULT_VIRTUALENV_DIR = BACKEND_DIR / "venv"

GEONATURE_VERSION = (ROOT_DIR / 'VERSION').read_text().strip()


def in_virtualenv():
    """ Return if we are in a virtualenv """
    return hasattr(sys, 'real_prefix')


def virtualenv_status():
    """ Return if we are in a virtualenv or not, and if it's allowed """
    VirtualenvStatus = namedtuple(  # pytlint: disable=C0101
        'VirtualenvStatus',
        'in_venv no_venv_allowed'
    )

    return VirtualenvStatus(
        in_virtualenv(),  # Are we in a venv ?
        os.environ.get('GEONATURE_NO_VIRTUALENV')  # By pass venv check ?
    )


def venv_path(*children):
    """ Return the path to the current virtualenv

        If additional arguments are passed, they are concatenated to the path.
    """
    if not in_virtualenv():
        raise EnvironmentError(
            'This function can only be called in a virtualenv'
        )
    path = sys.exec_prefix
    return Path(os.path.join(path, *children))


def venv_site_packages():
    """ Return the path to the virtualenv site-packages dir """

    venv = venv_path()
    for path in sys.path:
        if path.startswith(str(venv)) and path.endswith('site-packages'):
            return Path(path)


def add_geonature_pth_file():
    """ Return the path to the virtualenv site-packages dir

        Returns a tuple (path, bool), where path is the Path object to
        the .pth file and bool is wether or not the line was added.
    """

    path = venv_site_packages() / 'geonature.pth'
    try:
        if path.is_file() and path.read_text():
            return path, False

        with path.open('a') as f:
            f.write(str(BACKEND_DIR) + "\n")
    except OSError:
        return path, False

    return path, True


def install_geonature_command():
    """ Install an alias of geonature_cmd.py in the virtualenv bin dir """
    add_geonature_pth_file()
    python_executable = venv_path('bin', 'python')

    cmd_path = venv_path('bin', 'geonature')
    with cmd_path.open('w') as f:
        f.writelines([
            "#!{}\n".format(python_executable),
            "import geonature.core.command\n",
            "geonature.core.command.main()\n"
        ])
    cmd_path.chmod(0o777)


def create_frontend_config(conf_file):
    if not os.path.isfile(conf_file):
        raise FileNotFoundError

    conf_toml = toml.load(conf_file)
    configs_gn, configerrors = GnGeneralSchemaConf().load(conf_toml)
    if configerrors:
        raise ConfigError(configerrors)

    with open(
        str(ROOT_DIR / 'frontend/src/conf/app.config.ts'), 'w'
    ) as outputfile:
        outputfile.write("export const AppConfig = ")
        json.dump(configs_gn, outputfile, indent=True)


def start_gunicorn_cmd(uri, worker):
    cmd = 'gunicorn server:app -w {gun_worker} -b {gun_uri}'
    subprocess.call(
        cmd.format(gun_worker=worker, gun_uri=uri).split(" "),
        cwd=str(BACKEND_DIR)
    )


def start_flask_server_cmd(host, port):
    cmd = 'python server.py runserver -d -r -h {h} -p {p}'
    subprocess.call(cmd.format(h=host, p=port).split(" "), cwd=str(BACKEND_DIR))


def supervisor_cmd(action, app_name):
    cmd = 'sudo supervisorctl {action} {app}'
    subprocess.call(cmd.format(action=action, app=app_name).split(" "))


def start_geonature_front():
    subprocess.call(['npm', 'run', 'start'], cwd=str(ROOT_DIR / 'frontend'))
