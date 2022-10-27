import os
from collections import ChainMap

from geonature.utils.config_schema import (
    GnGeneralSchemaConf,
    GnPySchemaConf,
)
from geonature.utils.utilstoml import load_and_validate_toml
from geonature.utils.env import CONFIG_FILE


config_backend = load_and_validate_toml(CONFIG_FILE, GnPySchemaConf)
config_frontend = load_and_validate_toml(CONFIG_FILE, GnGeneralSchemaConf)
config = ChainMap({}, config_frontend, config_backend)
