import pytest
from flask import url_for
from werkzeug.exceptions import Unauthorized
from jsonschema import validate as validate_json

from geonature.tests.utils import set_logged_user
from geonature.core.gn_commons.models import TModules

from geonature.core.imports.models import (
    Destination,
    BibThemes,
)

from .jsonschema_definitions import jsonschema_definitions


@pytest.fixture()
def dest():
    return Destination.query.filter(
        Destination.module.has(TModules.module_code == "SYNTHESE")
    ).one()


@pytest.mark.usefixtures("client_class", "temporary_transaction", "default_synthese_destination")
class TestFields:
    def test_fields(self, users):
        assert self.client.get(url_for("import.get_fields")).status_code == Unauthorized.code
        set_logged_user(self.client, users["admin_user"])
        r = self.client.get(url_for("import.get_fields"))
        assert r.status_code == 200
        data = r.get_json()
        themes_count = BibThemes.query.count()
        schema = {
            "definitions": jsonschema_definitions,
            "type": "array",
            "items": {
                "type": "object",
                "properties": {
                    "entity": {"$ref": "#/definitions/entity"},
                    "themes": {
                        "type": "array",
                        "items": {
                            "type": "object",
                            "properties": {
                                "theme": {"$ref": "#/definitions/theme"},
                                "fields": {
                                    "type": "array",
                                    "items": {"$ref": "#/definitions/fields"},
                                    "uniqueItems": True,
                                    "minItems": 1,
                                },
                            },
                            "required": [
                                "theme",
                                "fields",
                            ],
                            "additionalProperties": False,
                        },
                        "minItems": themes_count,
                        "maxItems": themes_count,
                    },
                },
            },
        }
        validate_json(data, schema)

    def test_get_nomenclatures(self):
        resp = self.client.get(url_for("import.get_nomenclatures"))

        assert resp.status_code == 200
        assert all(
            set(nomenclature.keys()) == {"nomenclature_type", "nomenclatures"}
            for nomenclature in resp.json.values()
        )
