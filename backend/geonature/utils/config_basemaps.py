#
# BASEMAPS
#

from enum import Enum, unique
import typing


class ConfigBasemap:
    """
    Class that namespace the handling of config basemaps
    """

    DEFAULT = [
        {
            "name": "OpenStreetMap",
            "url": "//{s}.tile.openstreetmap.fr/hot/{z}/{x}/{y}.png",
            "options": {
                "attribution": "<a href='https://www.openstreetmap.org/copyright' target='_blank'>© OpenStreetMap contributors</a>",
            },
        },
        {
            "name": "OpenTopoMap",
            "url": "//a.tile.opentopomap.org/{z}/{x}/{y}.png",
            "options": {
                "attribution": "Map data: © <a href='https://www.openstreetmap.org/copyright' target='_blank'>OpenStreetMap contributors</a>, SRTM | Map style: © <a href='https://opentopomap.org' target='_blank'>OpenTopoMap</a> (<a href='https://creativecommons.org/licenses/by-sa/3.0/' target='_blank'>CC-BY-SA</a>)",
            },
        },
        {
            "name": "Google Satellite",
            "url": "//{s}.google.com/vt/lyrs=s&x={x}&y={y}&z={z}",
            "options": {
                "attribution": "© Google Maps",
                "subdomains": ["mt0", "mt1", "mt2", "mt3"],
            },
        },
    ]

    @staticmethod
    def __extract_option_subdict(config_basemap: typing.Dict):
        typing.Dict
        """
        Utility method
        Create a dictionary that contains only options item using a list of "not options" fields
        """
        NOT_OPTION_FIELDS = [
            "apikey",
            "layer",
            "name",
            "options",
            "service",
            "url",
        ]
        return {x: config_basemap[x] for x in config_basemap if x not in NOT_OPTION_FIELDS}

    @staticmethod
    def map_field_for_retro_compatibility(config_basemap: typing.Dict):
        typing.Dict
        """
        Utility method
        Map field for compatibility with previous version
        ex: layer --> url, etc. move options to options
        """
        # layer --> url
        if "layer" in config_basemap:
            config_basemap["url"] = config_basemap["layer"]
            del config_basemap["layer"]

        # zoom, maxzoom, etc. --> "options: { zoom, max zoom , etc.}"
        if "options" not in config_basemap:
            config_basemap["options"] = {}

        # get option
        options = ConfigBasemap.__extract_option_subdict(config_basemap)
        config_basemap["options"] = config_basemap["options"] | options
        for option in options.keys():
            del config_basemap[option]

        return config_basemap

    @staticmethod
    def generate_basemap(config_basemap: typing.Dict) -> typing.Dict:
        """
        Facade method
        Generate a basemap based on configuration
        It handles option mapping and the retro compatibility
        """

        # retrocompatiblity
        config_basemap = ConfigBasemap.map_field_for_retro_compatibility(config_basemap)

        # update basemap with content
        basemap = {"name": "", "url": "", "options": {}}

        for field in ["name", "url", "service", "options"]:
            if field in config_basemap:
                basemap[field] = config_basemap[field]

        return basemap
