
""" Helpers to manipulate the execution environment """

import os
import sys
import pip
import json
import subprocess

from pathlib import Path
from collections import ChainMap, namedtuple

from flask_sqlalchemy import SQLAlchemy
from jinja2 import Template

from geonature.utils.config_schema import (
    GnGeneralSchemaConf, GnPySchemaConf,
    GnModuleProdConf, ManifestSchemaProdConf
)
from geonature.utils.utilstoml import load_and_validate_toml

ROOT_DIR = Path(__file__).absolute().parent.parent.parent.parent
BACKEND_DIR = ROOT_DIR / 'backend'
DEFAULT_VIRTUALENV_DIR = BACKEND_DIR / "venv"
with open(str((ROOT_DIR / 'VERSION'))) as v:
    GEONATURE_VERSION = v.read()
DEFAULT_CONFIG_FIlE = Path('/etc/geonature/geonature_config.toml')

GEONATURE_ETC = Path('/etc/geonature')

DB = SQLAlchemy()

GN_MODULE_FILES = (
    'manifest.toml',
    '__init__.py',
    'backend/__init__.py',
    'backend/blueprint.py'
)
GN_MODULES_ETC_AVAILABLE = GEONATURE_ETC / 'mods-available'
GN_MODULES_ETC_ENABLED = GEONATURE_ETC / 'mods-enabled'
GN_MODULES_ETC_FILES = ("manifest.toml", "conf_gn_module.toml")
GN_MODULE_FE_FILE = 'frontend/app/gnModule.module'


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
        if path.is_file():
            return path, True

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
    configs_gn = load_and_validate_toml(conf_file, GnGeneralSchemaConf)

    with open(
        str(ROOT_DIR / 'frontend/src/conf/app.config.ts'), 'w'
    ) as outputfile:
        outputfile.write("export const AppConfig = ")
        json.dump(configs_gn, outputfile, indent=True)


def get_config_file_path(config_file=None):
    """ Return the config file path by checking several sources

        1 - Parameter passed
        2 - GEONATURE_CONFIG_FILE env var
        3 - Default config file value
    """
    config_file = config_file or os.environ.get('GEONATURE_CONFIG_FILE')
    return Path(config_file or DEFAULT_CONFIG_FIlE)


def load_config(config_file=None):
    """ Load the geonature configuration from a given file """

    # load and validate configuration
    configs_py = load_and_validate_toml(
        str(get_config_file_path(config_file)),
        GnPySchemaConf
    )

    # Settings also exported to backend
    configs_gn = load_and_validate_toml(
        str(get_config_file_path(config_file)),
        GnGeneralSchemaConf
    )

    return ChainMap({}, configs_py, configs_gn)


def import_requirements(req_file):
    with open(req_file, 'r') as requirements:
        for req in requirements:
            if pip.main(["install", req]) == 1:
                raise Exception('Package {} not installed'.format(req))


def list_and_import_gn_modules(mod_path=GN_MODULES_ETC_ENABLED):
    for f in mod_path.iterdir():
        if f.is_dir():
            conf_manifest = load_and_validate_toml(
                str(f / 'manifest.toml'),
                ManifestSchemaProdConf
            )

            # import du module dans le sys.path
            module_path = Path(conf_manifest['module_path'])
            module_parent_dir = str(module_path.parent)
            module_name = "{}.conf_schema_toml".format(module_path.name)
            sys.path.insert(0, module_parent_dir)
            module = __import__(module_name, globals=globals())
            module_name = "{}.backend.blueprint".format(module_path.name)
            module_blueprint = __import__(module_name, globals=globals())
            sys.path.pop(0)

            class GnModuleSchemaProdConf(
                module.conf_schema_toml.GnModuleSchemaConf,
                GnModuleProdConf
            ):
                pass

            conf_module = load_and_validate_toml(
                str(f / 'conf_gn_module.toml'),
                GnModuleSchemaProdConf
            )

            yield conf_module, conf_manifest, module_blueprint


def list_enabled_module(mod_path=GN_MODULES_ETC_ENABLED):
    for f in mod_path.iterdir():
        if f.is_dir():
            conf_manifest = load_and_validate_toml(
                str(f / 'manifest.toml'),
                ManifestSchemaProdConf
            )
            class GnModuleSchemaProdConf(
                GnModuleProdConf
            ):
                pass

            conf_module = load_and_validate_toml(
                str(f / 'conf_gn_module.toml'),
                GnModuleSchemaProdConf
            )
            yield conf_module, conf_manifest


def frontend_routes_templating():
    with open(
        str(ROOT_DIR / 'frontend/src/app/routing/app-routing.module.ts.sample'),
        'r'
    ) as input_file:

        template = Template(input_file.read())
        routes = []
        for conf, manifest in list_enabled_module():
            location = Path(manifest['module_path'])

            # test if module have frontend
            if not (location / 'frontend').is_dir():
                break

            path = conf['api_url'].lstrip('/')
            location = '{}/{}#GeonatureModule'.format(
                location, GN_MODULE_FE_FILE
            )
            routes.append({'path': path, 'location': location})

            # TODO test if two modules with the same name is okay for Angular

        route_template = template.render(routes=routes)

    with open(
        str(ROOT_DIR / 'frontend/src/app/routing/app-routing.module.ts'), 'w'
    ) as output_file:
        output_file.write(route_template)


def tsconfig_templating():
    with open(
        str(ROOT_DIR / 'frontend/tsconfig.json.sample'), 'r'
    ) as input_file:
        template = Template(input_file.read())
        tsconfig_templated = template.render(geonature_path=ROOT_DIR)

    with open(
        str(ROOT_DIR / 'frontend/tsconfig.json'), 'w'
    ) as output_file:
        output_file.write(tsconfig_templated)


def update_app_configuration(conf_file):
    subprocess.call(['sudo', 'supervisorctl', 'reload'])
    create_frontend_config(conf_file)
    subprocess.call(['npm', 'run', 'build'], cwd=str(ROOT_DIR / 'frontend'))


