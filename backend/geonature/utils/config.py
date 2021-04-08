import os
import logging
from pathlib import Path
import sys

from collections import ChainMap

from pkg_resources import load_entry_point

from geonature.utils.config_schema import (
    GnGeneralSchemaConf,
    GnPySchemaConf,
)
from geonature.utils.utilstoml import load_and_validate_toml
from geonature.utils.env import (
    DEFAULT_CONFIG_FILE, DB, GN_EXTERNAL_MODULE,
    ROOT_DIR, MAIL
)

log = logging.getLogger(__name__)


config_path = os.environ.get("GEONATURE_CONFIG_FILE", DEFAULT_CONFIG_FILE)
config_backend = load_and_validate_toml(config_path, GnPySchemaConf)
config_frontend = load_and_validate_toml(config_path, GnGeneralSchemaConf)
config = ChainMap({}, config_frontend, config_backend)




