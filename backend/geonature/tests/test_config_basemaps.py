import pytest

from geonature.utils.config_basemaps import ConfigBasemap


@pytest.mark.usefixtures()
class TestConfigBasemap:
    def test_basemap_preprocessing_layer(self):
        test = ConfigBasemap.generate_basemap(
            {
                "layer": "test1_url",
                "name": "test1_name",
                "option1": "test1_option1",
                "options": {
                    "option2": "test1_option2",
                },
            }
        )
        assert "layer" not in test
        assert test["url"] == "test1_url"

        assert "option1" not in test
        assert test["options"]["option1"] == "test1_option1"
        assert test["options"]["option2"] == "test1_option2"
