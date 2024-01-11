#
# Config Default
#

import typing

from geonature.utils.config_basemaps import ConfigBasemap


class ConfigProcessing:
    """
    Class that namespace the handling of config processing
    """

    @staticmethod
    def process_basemaps(config: typing.Dict) -> typing.Dict:
        # Apply preprocessing on some field
        if "MAPCONFIG" in config:
            # handle preset basemap profile
            if "BASEMAP" in config["MAPCONFIG"]:
                config["MAPCONFIG"]["BASEMAP"] = [
                    ConfigBasemap.generate_basemap(basemap)
                    for basemap in config["MAPCONFIG"]["BASEMAP"]
                ]
        return config
