""" Helpers to manipulate the execution environment """

import os
import sys
from pathlib import Path

if sys.version_info < (3, 9):
    from importlib_metadata import version, PackageNotFoundError
else:
    from importlib.metadata import version, PackageNotFoundError

from flask_sqlalchemy import SQLAlchemy
from flask_marshmallow import Marshmallow
from flask_mail import Mail
from flask_migrate import Migrate


# Must be at top of this file. I don't know why (?)
MAIL = Mail()

# Define GEONATURE_VERSION before import config_shema module
# because GEONATURE_VERSION is imported in this module
BACKEND_DIR = Path(__file__).absolute().parent.parent.parent
ROOT_DIR = BACKEND_DIR.parent
FRONTEND_DIR = ROOT_DIR / "frontend"

try:
    GEONATURE_VERSION = version("geonature")
except PackageNotFoundError:
    with open(str((ROOT_DIR / "VERSION"))) as v:
        GEONATURE_VERSION = v.read()

DEFAULT_CONFIG_FILE = ROOT_DIR / "config/geonature_config.toml"
CONFIG_FILE = os.environ.get("GEONATURE_CONFIG_FILE", DEFAULT_CONFIG_FILE)

os.environ["FLASK_SQLALCHEMY_DB"] = "geonature.utils.env.db"
DB = db = SQLAlchemy()
os.environ["FLASK_MARSHMALLOW"] = "geonature.utils.env.ma"
MA = ma = Marshmallow()
ma.SQLAlchemySchema.OPTIONS_CLASS.session = db.session
ma.SQLAlchemyAutoSchema.OPTIONS_CLASS.session = db.session
os.environ["FLASK_MIGRATE"] = "geonature.utils.env.migrate"
migrate = Migrate()
