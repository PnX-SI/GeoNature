import importlib
import os
from collections import ChainMap
from urllib.parse import urlsplit

from flask import Config
from flask.helpers import get_root_path
from geonature.utils.config_schema import GnGeneralSchemaConf, GnPySchemaConf
from geonature.utils.env import CONFIG_FILE
from geonature.utils.errors import ConfigError
from geonature.utils.utilstoml import load_toml
from marshmallow import EXCLUDE
from marshmallow.exceptions import ValidationError

__all__ = ["config", "config_frontend"]


def validate_provider_config(config, config_toml):
    """
    Validate the authentication providers configuration.

    Parameters
    ----------
    config : dict
        The Flask application configuration.
    config_toml : dict
        The TOML configuration.


    Raises
    ------
        ValidationError
            If the authentication providers configuration is invalid.

    """
    if not "AUTHENTICATION" in config_toml:
        return
    for path_provider in config_toml["AUTHENTICATION"]["PROVIDERS"]:
        import_path, class_name = (
            ".".join(path_provider.split(".")[:-1]),
            path_provider.split(".")[-1],
        )
        module = importlib.import_module(import_path)
        class_ = getattr(module, class_name)
        schema_unique_provider = class_.configuration_schema()
        config["AUTHENTICATION"][class_.name] = schema_unique_provider(many=True).load(
            config_toml["AUTHENTICATION"][class_.name], unknown=EXCLUDE
        )


# Load config from GEONATURE_* env vars and from GEONATURE_SETTINGS python module (if any)
config_programmatic = Config(get_root_path("geonature"))
config_programmatic.from_prefixed_env(prefix="GEONATURE")
if "GEONATURE_SETTINGS" in os.environ:
    config_programmatic.from_object(os.environ["GEONATURE_SETTINGS"])

# Load toml file and override with env & py config

config_toml = load_toml(CONFIG_FILE) if CONFIG_FILE else {}
config_toml.update(config_programmatic)

# Validate config
try:
    config_backend = GnPySchemaConf().load(config_toml, unknown=EXCLUDE)
    config_frontend = GnGeneralSchemaConf().load(config_toml, unknown=EXCLUDE)
except ValidationError as e:
    raise ConfigError(CONFIG_FILE, e.messages)

config_default = {
    # disable cache for downloaded files (PDF file stat for ex)
    # TODO: use Flask.get_send_file_max_age(filename) to return 0 only for generated PDF files
    "SEND_FILE_MAX_AGE_DEFAULT": 0,
}

config = ChainMap({}, config_programmatic, config_backend, config_frontend, config_default)

validate_provider_config(config, config_toml)

api_uri = urlsplit(config["API_ENDPOINT"])
if "APPLICATION_ROOT" not in config:
    config["APPLICATION_ROOT"] = api_uri.path or "/"
if "PREFERRED_URL_SCHEME" not in config:
    config["PREFERRED_URL_SCHEME"] = api_uri.scheme
