import tempfile

import pytest
import sqlalchemy as sa
from flask import g

from geonature.core.gn_commons.models import TModules
from geonature.core.gn_commons.schemas import ModuleSchema
from geonature.utils.env import db
from geonature.utils.config_schema import GnPySchemaConf
from geonature.utils.utilstoml import *
from geonature.utils.errors import GeoNatureError, ConfigError
from jsonschema import validate
from json import loads

from .fixtures import *


#############################################################################
# BASIC TEMPLATE CONFIG FILE
#############################################################################

TEMPLATE_CONFIG_FILE = """
SQLALCHEMY_DATABASE_URI = "postgresql://monuser:monpassachanger@localhost:5432/mabase"
URL_APPLICATION = 'http://url.com/geonature'
API_ENDPOINT = 'http://url.com/geonature/api'

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

#############################################################################
# TAXON SHEET CONFIG FILE
#############################################################################

TEMPLATE_TAXON_SHEET_CONFIG_FILE = """
    SQLALCHEMY_DATABASE_URI = "postgresql://monuser:monpassachanger@localhost:5432/mabase"
    URL_APPLICATION = 'http://url.com/geonature'
    API_ENDPOINT = 'http://url.com/geonature/api'

    SECRET_KEY = 'super secret key'

    DEFAULT_LANGUAGE=fr
    [HOME]
    TITLE = "Bienvenue dans GeoNature"
    INTRODUCTION = "Texte d'introduction, configurable pour le modifier régulièrement ou le masquer"
    FOOTER = ""

    # Configuration liée aux ID de BDD
    [BDD]

    # Configuration générale du frontend
    [FRONTEND]
    ENABLE_PROFILES={ENABLE_PROFILES}

    # Configuration de la Synthese
    [SYNTHESE]
    ENABLE_TAXON_SHEETS={ENABLE_TAXON_SHEETS}
    [SYNTHESE.TAXON_SHEET]
    ENABLE_TAB_TAXONOMY={ENABLE_TAB_TAXONOMY}
    ENABLE_TAB_PROFILE={ENABLE_TAB_PROFILE}

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

    @pytest.mark.parametrize(
        "enable_profiles,enable_tab_profile,expected_enable_tab_profile",
        [(True, True, True), (True, False, False), (False, False, False), (False, True, False)],
    )
    def test_config_profiles_consistency(
        self, enable_profiles, enable_tab_profile, expected_enable_tab_profile
    ):

        profiles_config = TEMPLATE_TAXON_SHEET_CONFIG_FILE.format(
            ENABLE_TAXON_SHEETS=True,
            ENABLE_TAB_TAXONOMY=True,
            ENABLE_PROFILES=enable_profiles,
            ENABLE_TAB_PROFILE=enable_tab_profile,
        )

        with tempfile.NamedTemporaryFile(mode="w") as f:
            f.write(profiles_config)
            with pytest.raises(ConfigError):
                config = load_and_validate_toml(f.name, GnPySchemaConf)
                assert (
                    config["SYNTHESE"]["TAXON_SHEET"]["ENABLE_TAB_PROFILE"]
                    == expected_enable_tab_profile
                )


pagination_schema = {
    "type": "object",
    "properties": {
        "items": {"type": "array"},
        "page": {"type": "number"},
        "per_page": {"type": "number"},
        "pages": {"type": "number"},
        "total": {"type": "number"},
        "prev_num": {"type": ["number", "null"]},
        "next_num": {"type": ["number", "null"]},
    },
    "required": ["items", "page", "per_page", "pages", "total", "prev_num", "next_num"],
}


class TestJSONProvider:
    def test_serialize_row(self, app):
        query = sa.select(TModules.__table__)
        app.json.dumps(db.session.execute(query).fetchone())
        app.json.dumps(db.session.execute(query).fetchall())

    def test_serialize_pagination_asdict(self, app):
        query = sa.select(TModules)
        json_data = app.json.dumps(db.paginate(query))
        validate(loads(json_data), pagination_schema)

    def test_serialize_pagination_schema(self, app):
        query = sa.select(TModules)
        g.pagination_schema = ModuleSchema()
        json_data = app.json.dumps(db.paginate(query))
        validate(loads(json_data), pagination_schema)
