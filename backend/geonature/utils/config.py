import os
from collections import ChainMap

from geonature.utils.config_schema import (
    GnGeneralSchemaConf,
    GnPySchemaConf,
)
from geonature.utils.utilstoml import load_and_validate_toml
from geonature.utils.env import DEFAULT_CONFIG_FILE


config_path = os.environ.get("GEONATURE_CONFIG_FILE", DEFAULT_CONFIG_FILE)
config_backend = load_and_validate_toml(config_path, GnPySchemaConf)
config_frontend = load_and_validate_toml(config_path, GnGeneralSchemaConf)
# Note: v.removeprefix('GEONATURE_') Python 3.9+
config_environ = { k: v[len('GEONATURE_'):] for k, v in os.environ.items() if k.startswith('GEONATURE_') }
config = ChainMap(config_environ, config_frontend, config_backend)
