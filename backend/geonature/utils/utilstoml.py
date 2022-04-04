from pathlib import Path

import toml
from marshmallow import EXCLUDE
from marshmallow.exceptions import ValidationError

from geonature.utils.errors import ConfigError, GeoNatureError


def load_and_validate_toml(toml_file, config_schema):
    """
    Fonction qui charge un fichier toml
     et le valide avec un Schema marshmallow
    """
    toml_config = load_toml(toml_file)
    try:
        configs_py = config_schema().load(toml_config, unknown=EXCLUDE)
    except ValidationError as e:
        raise ConfigError(toml_file, e.messages)
    return configs_py


def load_toml(toml_file):
    """
    Fonction qui charge un fichier toml
    """
    if not Path(toml_file).is_file():
        raise GeoNatureError("Missing file {}".format(toml_file))
    return toml.load(str(toml_file))
