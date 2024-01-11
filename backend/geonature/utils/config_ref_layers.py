#
# REF LAYERS
#

from enum import Enum, unique

class ConfigRefLayers:
    """
    Class that namespace the handling of config ref layers
    """

    DEFAULT = [
        {
            "code": "limitesadministratives",
            "label": "Limites administratives (IGN)",
            "type": "wms",
            "url": "https://data.geopf.fr/wms-r",
            "activate": False,
            "params": {
                "sevice": "wms",
                "version": "1.3.0",
                "request": "GetMap",
                "layers": "LIMITES_ADMINISTRATIVES_EXPRESS.LATEST",
                "styles": "normal",
                "format": "image/png",
                "crs": "CRS:84",
                "dpiMode": 7,
            },
        }, {
            "code": "znieff1",
            "label": "ZNIEFF1 (INPN)",
            "type": "wms",
            "url": "https://ws.carmencarto.fr/WMS/119/fxx_inpn",
            "activate": False,
            "params": {
                "service": "wms",
                "version": "1.3.0",
                "request": "GetMap",
                "layers": "znieff1",
                "format": "image/png",
                "crs": "EPSG:4326",
                "opacity": 0.2,
                "transparent": True,
            },
        },
    ]
