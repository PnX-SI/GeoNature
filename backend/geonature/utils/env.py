""" Helpers to manipulate the execution environment """

import os
import subprocess
import sys

from pathlib import Path
from collections import ChainMap, namedtuple
import pkg_resources

from flask_sqlalchemy import SQLAlchemy
from sqlalchemy.orm.exc import NoResultFound
from flask_marshmallow import Marshmallow
from flask_mail import Mail


# Must be at top of this file. I don't know why (?)
MAIL = Mail()

# Define GEONATURE_VERSION before import config_shema module
# because GEONATURE_VERSION is imported in this module
ROOT_DIR = Path(__file__).absolute().parent.parent.parent.parent
try:
    GEONATURE_VERSION = pkg_resources.require("geonature")[0].version
except pkg_resources.DistributionNotFound:
    with open(str((ROOT_DIR / "VERSION"))) as v:
        GEONATURE_VERSION = v.read()
from geonature.utils.config_schema import (
    GnGeneralSchemaConf,
    GnPySchemaConf,
    ManifestSchemaProdConf,
)
from geonature.utils.utilstoml import load_and_validate_toml

BACKEND_DIR = ROOT_DIR / "backend"
DEFAULT_CONFIG_FILE = ROOT_DIR / "config/geonature_config.toml"

os.environ['FLASK_SQLALCHEMY_DB'] = 'geonature.utils.env.DB'
DB = SQLAlchemy()
MA = Marshmallow()

GN_MODULE_FILES = (
    "manifest.toml",
    "__init__.py",
    "backend/__init__.py",
    "backend/blueprint.py",
)

GN_EXTERNAL_MODULE = ROOT_DIR / "external_modules"
GN_MODULE_FE_FILE = "frontend/app/gnModule.module"


def get_config_file_path(config_file=None):
    """ Return the config file path by checking several sources

        1 - Parameter passed
        2 - GEONATURE_CONFIG_FILE env var
        3 - Default config file value
    """
    config_file = config_file or os.environ.get("GEONATURE_CONFIG_FILE")
    return Path(config_file or DEFAULT_CONFIG_FILE)


def load_config(config_file=None):
    """ Load the geonature configuration from a given file """
    # load and validate configuration
    configs_py = load_and_validate_toml(str(get_config_file_path(config_file)), GnPySchemaConf)

    # Settings also exported to backend
    configs_gn = load_and_validate_toml(
        str(get_config_file_path(config_file)), GnGeneralSchemaConf
    )

    return ChainMap({}, configs_py, configs_gn)


def import_requirements(req_file):
    from geonature.utils.errors import GeoNatureError

    cmd_return = subprocess.call(["pip", "install", "-r", req_file])
    if cmd_return != 0:
        raise GeoNatureError("Error while installing module backend dependencies")
