import tempfile

from geonature.utils.config_schema import GnPySchemaConf
from .fixtures import *
import pytest
from geonature.utils.utilstoml import *
from geonature.utils.errors import GeoNatureError, ConfigError
from marshmallow.exceptions import ValidationError


TEMPLATE_CONFIG_FILE = """
SQLALCHEMY_DATABASE_URI = "postgresql://monuser:monpassachanger@localhost:5432/mabase"
URL_APPLICATION = 'http://url.com/geonature'
API_ENDPOINT = 'http://url.com/geonature/api'
API_TAXHUB = 'http://url.com/taxhub/api'

SECRET_KEY = 'super secret key'

DEFAULT_LANGUAGE={language}
[HOME]
TITLE = "Bienvenue dans GeoNature"
INTRODUCTION = "Texte d'introduction, configurable pour le modifier régulièrement ou le masquer"
FOOTER = ""

# Configuration liée aux ID de BDD
[BDD]

# Configuration générale du frontend
[FRONTEND]

# Configuration de la Synthese
[SYNTHESE]

# Configuration cartographique
[MAPCONFIG]

# Configuration médias
[MEDIAS]
"""


@pytest.mark.usefixtures("temporary_transaction")
class TestUtils:
    def test_utilstoml(self):
        # Test if file not exists
        with pytest.raises(GeoNatureError):
            load_toml("IDONTEXIST.md")
        # Test bad config file
        bad_config = TEMPLATE_CONFIG_FILE.format(language=2)
        with tempfile.NamedTemporaryFile(mode="w") as f:
            f.write(bad_config)

            with pytest.raises(ConfigError):
                load_and_validate_toml(f.name, GnPySchemaConf)

        # Test if good config file
        good_config = TEMPLATE_CONFIG_FILE.format(language="fr")
        with tempfile.NamedTemporaryFile(mode="w") as f:
            f.write(good_config)

            with pytest.raises(ConfigError):
                load_and_validate_toml(f.name, GnPySchemaConf)
