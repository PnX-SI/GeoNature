""" Helpers to manipulate the execution environment """

import os
import subprocess

from pathlib import Path
import pkg_resources

from flask_sqlalchemy import SQLAlchemy
from flask_marshmallow import Marshmallow
from flask_mail import Mail
from flask_migrate import Migrate


# Must be at top of this file. I don't know why (?)
MAIL = Mail()

from flask import current_app

# Define GEONATURE_VERSION before import config_shema module
# because GEONATURE_VERSION is imported in this module
ROOT_DIR = Path(__file__).absolute().parent.parent.parent.parent
try:
    GEONATURE_VERSION = pkg_resources.get_distribution("geonature").version
except pkg_resources.DistributionNotFound:
    with open(str((ROOT_DIR / "VERSION"))) as v:
        GEONATURE_VERSION = v.read()

BACKEND_DIR = ROOT_DIR / "backend"
DEFAULT_CONFIG_FILE = ROOT_DIR / "config/geonature_config.toml"

os.environ["FLASK_SQLALCHEMY_DB"] = "geonature.utils.env.db"
DB = db = SQLAlchemy()
os.environ["FLASK_MARSHMALLOW"] = "geonature.utils.env.ma"
MA = ma = Marshmallow()
os.environ["FLASK_MIGRATE"] = "geonature.utils.env.migrate"
migrate = Migrate()

GN_MODULE_FILES = (
    "manifest.toml",
    "__init__.py",
    "backend/__init__.py",
    "backend/blueprint.py",
)

GN_EXTERNAL_MODULE = ROOT_DIR / "external_modules"
GN_MODULE_FE_FILE = "frontend/app/gnModule.module"


def import_requirements(req_file):
    from geonature.utils.errors import GeoNatureError

    cmd_return = subprocess.call(["pip", "install", "-r", req_file])
    if cmd_return != 0:
        raise GeoNatureError("Error while installing module backend dependencies")
