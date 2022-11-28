import os
from collections import ChainMap
from urllib.parse import urlsplit

from flask import Config
from flask.helpers import get_root_path

from geonature.utils.config_schema import (
    GnGeneralSchemaConf,
    GnPySchemaConf,
)
from geonature.utils.utilstoml import load_and_validate_toml
from geonature.utils.env import CONFIG_FILE


config_programmatic = Config(get_root_path("geonature"))
config_programmatic.from_prefixed_env(prefix="GEONATURE")
if "GEONATURE_SETTINGS" in os.environ:
    config_programmatic.from_object(os.environ["GEONATURE_SETTINGS"])
partial = config_programmatic.keys()
config_backend = load_and_validate_toml(CONFIG_FILE, GnPySchemaConf, partial=partial)
config_frontend = load_and_validate_toml(CONFIG_FILE, GnGeneralSchemaConf, partial=partial)
config_default = {
    # disable cache for downloaded files (PDF file stat for ex)
    # TODO: use Flask.get_send_file_max_age(filename) to return 0 only for generated PDF files
    "SEND_FILE_MAX_AGE_DEFAULT": 0,
}

config = ChainMap({}, config_programmatic, config_backend, config_frontend, config_default)

api_uri = urlsplit(config["API_ENDPOINT"])
if "APPLICATION_ROOT" not in config:
    config["APPLICATION_ROOT"] = api_uri.path
if "PREFERRED_URL_SCHEME" not in config:
    config["PREFERRED_URL_SCHEME"] = api_uri.scheme
