import pytest

from geonature.utils.config import config
from geonature.utils.utilstoml import load_and_validate_toml

occtax = pytest.importorskip("occtax")
pytestmark = pytest.mark.skipif("OCCTAX" in config["DISABLED_MODULES"], reason="OccTax is disabled")

from occtax.conf_schema_toml import GnModuleSchemaConf

# Un vrai fichier occtax_config.toml, comme dans occtax_config.toml.example,
# avec un sous-module FLORE qui redéfinit certains champs.
OCCTAX_CONFIG_TOML = """
observers_txt = false
export_available_format = ["csv", "geojson", "shapefile", "gpkg"]

[form_fields]
date_min = true
habitat = true

# Exemple de duplication du module OCCTAX en sous-module FLORE
[MODULE_CONFS.FLORE]
observers_txt = true

[MODULE_CONFS.FLORE.form_fields]
date_min = true
habitat = false
"""


@pytest.fixture
def occtax_config_toml_file(tmp_path):
    toml_file = tmp_path / "occtax_config.toml"
    toml_file.write_text(OCCTAX_CONFIG_TOML)
    return toml_file


def test_flore_submodule_config_is_duplicated_from_occtax_toml(occtax_config_toml_file):
    """
    On charge un vrai fichier toml (comme le ferait GeoNature au démarrage)
    contenant une section [MODULE_CONFS.FLORE], et on vérifie que le
    sous-module FLORE récupère bien sa propre config : une copie de celle
    d'OCCTAX, avec ses overrides appliqués par-dessus.
    """
    conf = load_and_validate_toml(occtax_config_toml_file, GnModuleSchemaConf)

    # La config racine OCCTAX garde ses propres valeurs
    assert conf["observers_txt"] is False
    assert conf["form_fields"]["habitat"] is True

    # FLORE existe bien en tant que sous-module, avec ses overrides à lui
    flore_conf = conf["MODULE_CONFS"]["FLORE"]
    assert flore_conf["observers_txt"] is True
    assert flore_conf["form_fields"]["date_min"] is True
    assert flore_conf["form_fields"]["habitat"] is False

    # Les champs non redéfinis pour FLORE sont bien hérités (dupliqués) d'OCCTAX
    assert flore_conf["export_available_format"] == ["csv", "geojson", "shapefile", "gpkg"]
