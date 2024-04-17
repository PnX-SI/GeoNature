import os
import importlib

from collections import ChainMap
from urllib.parse import urlsplit

from flask import Config
from flask.helpers import get_root_path
from marshmallow import EXCLUDE, INCLUDE, Schema, fields
from marshmallow.exceptions import ValidationError

from geonature.utils.config_schema import (
    GnGeneralSchemaConf,
    GnPySchemaConf,
)
from geonature.utils.utilstoml import load_toml
from geonature.utils.env import CONFIG_FILE
from geonature.utils.errors import ConfigError


__all__ = ["config", "config_frontend"]


def load_config_provider(config: ChainMap, config_toml):

    for path_provider in config["AUTHENTICATION"]["PROVIDERS"]:
        import_path, class_name = (
            ".".join(path_provider.split(".")[:-1]),
            path_provider.split(".")[-1],
        )
        module = importlib.import_module(import_path)
        class_ = getattr(module, class_name)
        name_schema, schema_unique_provider = class_.configuration_schema()
        schema = Schema.from_dict(
            dict(
                CONFIG=fields.List(
                    fields.Nested(schema_unique_provider),
                )
            ),
            name=name_schema,
        )

        config["AUTHENTICATION"]["PROVIDERS_CONFIG"][name_schema] = schema().load(
            config_toml, unknown=EXCLUDE
        )

    return config


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

config = load_config_provider(config, config_toml)
print(config["AUTHENTICATION"])

api_uri = urlsplit(config["API_ENDPOINT"])
if "APPLICATION_ROOT" not in config:
    config["APPLICATION_ROOT"] = api_uri.path or "/"
if "PREFERRED_URL_SCHEME" not in config:
    config["PREFERRED_URL_SCHEME"] = api_uri.scheme
