from pathlib import Path

import pytest
from flask import url_for
from werkzeug.exceptions import Unauthorized, Forbidden
from jsonschema import validate as validate_json

from geonature.utils.env import db
from geonature.tests.utils import set_logged_user

from geonature.core.imports.models import TImports

from .jsonschema_definitions import jsonschema_definitions


tests_path = Path(__file__).parent


@pytest.fixture(scope="function")
def imports_all(all_modules_destination, users):
    def create_import(authors=[]):
        all_destinations = {}
        with db.session.begin_nested():
            for module_code, destination in all_modules_destination.items():
                all_destinations[module_code] = TImports(destination=destination, authors=authors)
            db.session.add_all(all_destinations.values())
        return all_destinations

    return {
        "own_import": create_import(authors=[users["user"]]),
        "associate_import": create_import(authors=[users["associate_user"]]),
        "stranger_import": create_import(authors=[users["stranger_user"]]),
        "orphan_import": create_import(),
    }


@pytest.mark.usefixtures("client_class", "temporary_transaction", "celery_eager")
class TestImportsRoute:
    def test_list_imports(self, imports_all, all_modules_destination, users):
        r = self.client.get(url_for("import.get_import_list"))
        assert r.status_code == Unauthorized.code, r.data
        set_logged_user(self.client, users["noright_user"])
        r = self.client.get(url_for("import.get_import_list"))
        assert r.status_code == Forbidden.code, r.data
        set_logged_user(self.client, users["user"])
        r = self.client.get(url_for("import.get_import_list"))
        assert r.status_code == 200, r.data
        json_data = r.get_json()
        validate_json(
            json_data["imports"],
            {
                "definitions": jsonschema_definitions,
                "type": "array",
                "items": {"$ref": "#/definitions/import"},
            },
        )

        ids_destination = [
            module_dest.id_destination for module_dest in all_modules_destination.values()
        ]

        assert all(imprt["id_destination"] in ids_destination for imprt in json_data["imports"])
