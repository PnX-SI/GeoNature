from flask import url_for

from pypnusershub.tests.utils import (
    set_logged_user_cookie,
    unset_logged_user_cookie,
    logged_user_headers,
)


def login(client, username="admin", password=None):
    data = {
        "login": username,
        "password": password if password else username,
        "id_application": client.application.config["ID_APPLICATION_GEONATURE"],
    }
    response = client.post(url_for("auth.login"), json=data)
    assert response.status_code == 200


jsonschema_definitions = {
    "geometries": {
        "BoundingBox": {
            "type": "array",
            "minItems": 4,
            "items": {"type": "number"},
        },
        "PointCoordinates": {"type": "array", "minItems": 2, "items": {"type": "number"}},
        "Point": {
            "title": "GeoJSON Point",
            "type": "object",
            "required": ["type", "coordinates"],
            "properties": {
                "type": {"type": "string", "enum": ["Point"]},
                "coordinates": {
                    "$ref": "#/definitions/geometries/PointCoordinates",
                },
                "bbox": {
                    "$ref": "#/definitions/geometries/BoundingBox",
                },
            },
        },
    },
    "feature": {
        "title": "GeoJSON Feature",
        "type": "object",
        "required": ["type", "properties", "geometry"],
        "properties": {
            "type": {"type": "string", "enum": ["Feature"]},
            "id": {"oneOf": [{"type": "number"}, {"type": "string"}]},
            "properties": {
                "oneOf": [
                    {"type": "null"},
                    {"$ref": "#/$defs/props"},
                ],
            },
            "geometry": {
                "oneOf": [
                    {"type": "null"},
                    {"$ref": "#/definitions/geometries/Point"},
                    # {"$ref": "#/definitions/geometries/LineString"},
                    # {"$ref": "#/definitions/geometries/Polygon"},
                    # {"$ref": "#/definitions/geometries/MultiPoint"},
                    # {"$ref": "#/definitions/geometries/MultiLineString"},
                    # {"$ref": "#/definitions/geometries/MultiPolygon"},
                    # {"$ref": "#/definitions/geometries/GeometryCollection"},
                ],
            },
            "bbox": {
                "$ref": "#/definitions/geometries/BoundingBox",
            },
        },
    },
    "featurecollection": {
        "title": "GeoJSON FeatureCollection",
        "type": "object",
        "required": ["type", "features"],
        "properties": {
            "type": {
                "type": "string",
                "enum": ["FeatureCollection"],
            },
            "features": {
                "type": "array",
                "items": {
                    "$ref": "#/definitions/feature",
                },
            },
            "bbox": {
                "$ref": "#/definitions/geometries/BoundingBox",
            },
        },
    },
}
