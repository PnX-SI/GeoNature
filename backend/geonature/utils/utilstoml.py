from pathlib import Path

# tomli plutôt que tomllib : les tables en ligne multilignes des configs sont du TOML 1.1
import tomli
from marshmallow import EXCLUDE
from marshmallow.exceptions import ValidationError

from geonature.utils.errors import ConfigError, GeoNatureError


def load_and_validate_toml(toml_file, config_schema, partial=None):
    """
    Fonction qui charge un fichier toml
     et le valide avec un Schema marshmallow
    """
    if toml_file:
        toml_config = load_toml(toml_file)
    else:
        toml_config = {}
    try:
        configs_py = config_schema().load(toml_config, unknown=EXCLUDE, partial=partial)
    except ValidationError as e:
        raise ConfigError(toml_file, e.messages)
    return configs_py


def load_toml(toml_file):
    """
    Fonction qui charge un fichier toml
    """
    if not Path(toml_file).is_file():
        raise GeoNatureError("Missing file {}".format(toml_file))
    with open(toml_file, "rb") as f:
        return tomli.load(f)
