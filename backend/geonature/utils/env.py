
""" Helpers to manipulate the execution environment """

import os
import sys

from pathlib import Path
from collections import ChainMap, namedtuple


from flask_sqlalchemy import SQLAlchemy

import pip

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
DEFAULT_CONFIG_FILE = ROOT_DIR / 'config/geonature_config.toml'

GEONATURE_ETC = Path('/etc/geonature')

DB = SQLAlchemy()

# L'import doit être réalisé après la déclaration de DB
from geonature.core.gn_commons.models import TModules


GN_MODULE_FILES = (
    'manifest.toml',
    '__init__.py',
    'backend/__init__.py',
    'backend/blueprint.py'
)

GN_EXTERNAL_MODULE = ROOT_DIR / 'external_modules'
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


def get_config_file_path(config_file=None):
    """ Return the config file path by checking several sources

        1 - Parameter passed
        2 - GEONATURE_CONFIG_FILE env var
        3 - Default config file value
    """
    config_file = config_file or os.environ.get('GEONATURE_CONFIG_FILE')
    return Path(config_file or DEFAULT_CONFIG_FILE)


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


def get_module_id(module_name):
    conf_path = '{}/{}/config/conf_gn_module.toml'.format(
        GN_EXTERNAL_MODULE,
        module_name
    )
    return load_and_validate_toml(
        conf_path,
        GnModuleProdConf
    )['id_application']


def list_and_import_gn_modules(app, mod_path=GN_EXTERNAL_MODULE):
    """
        Get all the module enabled from gn_commons.t_modules
    """
    with app.app_context():
        data = DB.session.query(TModules).filter(
            TModules.active_backend == True
        )
        enabled_modules = [d.as_dict()['module_name'] for d in data]

    # iter over external_modules dir
    #   and import only modules which are enabled
    for f in mod_path.iterdir():
        if f.is_dir():
            conf_manifest = load_and_validate_toml(
                str(f / 'manifest.toml'),
                ManifestSchemaProdConf
            )
            module_name = conf_manifest['module_name']
            if module_name in enabled_modules:
                # TODO CHECK WHAT MODULE NAME BELOW MEAN
                # import du module dans le sys.path
                module_path = Path(GN_EXTERNAL_MODULE / module_name)
                module_parent_dir = str(module_path.parent)
                module_name = "{}.config.conf_schema_toml".format(module_path.name)
                sys.path.insert(0, module_parent_dir)
                module = __import__(module_name, globals=globals())
                module_name = "{}.backend.blueprint".format(module_path.name)
                module_blueprint = __import__(module_name, globals=globals())
                sys.path.pop(0)

                class GnModuleSchemaProdConf(
                        module.config.conf_schema_toml.GnModuleSchemaConf,
                        GnModuleProdConf
                ):
                    pass
                conf_module = load_and_validate_toml(
                    str(f / 'config/conf_gn_module.toml'),
                    GnModuleSchemaProdConf
                )

                yield conf_module, conf_manifest, module_blueprint


def list_frontend_enabled_modules(mod_path=GN_EXTERNAL_MODULE):
    """
        Get all the module frontend enabled from gn_commons.t_modules
    """
    from geonature.utils.command import get_app_for_cmd
    from geonature.core.gn_commons.models import TModules

    app = get_app_for_cmd(DEFAULT_CONFIG_FILE, with_external_mods=False)
    with app.app_context():
        data = DB.session.query(TModules).filter(
            TModules.active_frontend == True
        ).all()
        enabled_modules = [d.as_dict()['module_name'] for d in data]
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
                str(f / 'config/conf_gn_module.toml'),
                GnModuleSchemaProdConf
            )
            if conf_manifest['module_name'] in enabled_modules:
                yield conf_module, conf_manifest
