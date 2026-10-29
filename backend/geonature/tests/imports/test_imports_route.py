from pathlib import Path

from geonature.core.gn_synthese.imports.actions import SyntheseImportActions
from geonature.core.imports.actions import ImportActions
from gn_module_occhab.imports.actions import OcchabImportActions
import pytest
from sqlalchemy import select
from flask import current_app, url_for
from werkzeug.exceptions import Unauthorized, Forbidden
from jsonschema import validate as validate_json

from geonature.utils.env import db
from geonature.tests.utils import set_logged_user

from geonature.core.imports.models import Destination, TImports

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


@pytest.mark.usefixtures("client_class", "celery_eager")
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

    def test_order_import_foreign(self, users, imports_all):
        set_logged_user(self.client, users["user"])
        response = self.client.get(url_for("import.get_import_list") + "?sort=destination.code")
        assert response.status_code == 200, response.data
        imports = response.get_json()["imports"]
        for a, b in zip(imports[:1], imports[1:]):
            assert (a["destination"] is None) or (
                a["destination"]["code"] <= b["destination"]["code"]
            )

    def test_update_import(self, users, imports_all):
        set_logged_user(self.client, users["user"])
        imprt = imports_all["own_import"]["SYNTHESE"]
        r = self.client.put(
            url_for(
                "import.update_import",
                **{"import_id": imprt.id_import, "destination": imprt.destination.code},
            ),
            data={"id_import": imprt.id_import, "detected_encoding": "utf-8"},
        )
        assert r.status_code == 200, r.data
        assert r.json["detected_encoding"] == "utf-8"

    def test_observation_mapping_enabled(self, users, imports_all, monkeypatch):
        set_logged_user(self.client, users["user"])
        monkeypatch.setitem(current_app.config["IMPORT"], "ALLOW_USER_MAPPING", True)
        assert ImportActions.is_observer_mapping_enabled() is True
        assert SyntheseImportActions.is_observer_mapping_enabled() is True
        monkeypatch.setitem(current_app.config["IMPORT"], "ALLOW_USER_MAPPING", False)
        assert ImportActions.is_observer_mapping_enabled() is False
        assert SyntheseImportActions.is_observer_mapping_enabled() is False

        monkeypatch.setitem(current_app.config["IMPORT"], "ALLOW_USER_MAPPING", True)
        monkeypatch.setitem(current_app.config["OCCHAB"], "OBSERVER_AS_TXT", True)
        assert OcchabImportActions.is_observer_mapping_enabled() is False
        monkeypatch.setitem(current_app.config["OCCHAB"], "OBSERVER_AS_TXT", False)
        assert OcchabImportActions.is_observer_mapping_enabled() is True

        assert (
            self.client.get(
                url_for("import.is_observer_mapping_enabled", destination="synthese")
            ).json["allowed"]
            is True
        )
        monkeypatch.setitem(current_app.config["OCCHAB"], "OBSERVER_AS_TXT", True)
        assert (
            self.client.get(
                url_for("import.is_observer_mapping_enabled", destination="occhab")
            ).json["allowed"]
            is False
        )
        monkeypatch.setitem(current_app.config["OCCHAB"], "OBSERVER_AS_TXT", False)
        assert (
            self.client.get(
                url_for("import.is_observer_mapping_enabled", destination="occhab")
            ).json["allowed"]
            is True
        )


@pytest.mark.usefixtures("client_class", "temporary_transaction")
class TestImportDestinationsRoute:
    def test_list_destinations_unauthenticated(self):
        r = self.client.get(url_for("import.list_all_destinations"))
        assert r.status_code == Unauthorized.code, r.data
        r = self.client.get(url_for("import.list_all_destinations", action_code="C"))
        assert r.status_code == Unauthorized.code, r.data

    def test_list_all_destinations(self, users, all_modules_destination):
        set_logged_user(self.client, users["noright_user"])
        r = self.client.get(url_for("import.list_all_destinations"))
        assert r.status_code == 200, r.data
        codes = {d["code"] for d in r.get_json()}
        expected = {d.code for d in all_modules_destination.values()}
        assert expected <= codes

    @pytest.mark.parametrize("user_key", ["noright_user", "user", "admin_user"])
    def test_list_destinations_with_action_code(self, users, user_key):
        user = users[user_key]
        set_logged_user(self.client, user)
        r = self.client.get(url_for("import.list_all_destinations", action_code="C"))
        assert r.status_code == 200, r.data
        codes = {d["code"] for d in r.get_json()}
        all_dest = db.session.scalars(select(Destination)).all()
        expected = {d.code for d in all_dest if d.active and d.has_instance_permission(user, "C")}
        assert codes == expected
        if user_key == "noright_user":
            assert codes == set()
        if user_key == "admin_user":
            assert codes  # admin can create imports in at least one destination

    def test_list_destinations_module_code_filter(self, users, all_modules_destination):
        set_logged_user(self.client, users["noright_user"])
        for module_code, destination in all_modules_destination.items():
            r = self.client.get(url_for("import.list_all_destinations", module_code=module_code))
            assert r.status_code == 200, r.data
            assert [d["code"] for d in r.get_json()] == [destination.code]

    def test_list_destinations_unknown_module_code(self, users):
        set_logged_user(self.client, users["admin_user"])
        r = self.client.get(url_for("import.list_all_destinations", module_code="UNKNOWN_MODULE"))
        assert r.status_code == 200, r.data
        assert r.get_json() == []

    @pytest.mark.parametrize("user_key", ["noright_user", "admin_user"])
    def test_list_destinations_action_code_and_module_code(
        self, users, all_modules_destination, user_key
    ):
        set_logged_user(self.client, users[user_key])
        for module_code, destination in all_modules_destination.items():
            r = self.client.get(
                url_for("import.list_all_destinations", action_code="C", module_code=module_code)
            )
            assert r.status_code == 200, r.data
            codes = [d["code"] for d in r.get_json()]
            if destination.has_instance_permission(users[user_key], "C"):
                assert codes == [destination.code]
            else:
                assert codes == []
        r = self.client.get(
            url_for("import.list_all_destinations", action_code="C", module_code="UNKNOWN_MODULE")
        )
        assert r.get_json() == []

    def test_get_destination_unauthenticated(self, all_modules_destination):
        destination = next(iter(all_modules_destination.values()))
        r = self.client.get(url_for("import.get_destination", destinationCode=destination.code))
        assert r.status_code == Unauthorized.code, r.data

    def test_get_destination(self, users, all_modules_destination):
        set_logged_user(self.client, users["noright_user"])
        for module_code, destination in all_modules_destination.items():
            r = self.client.get(url_for("import.get_destination", destinationCode=destination.code))
            assert r.status_code == 200, r.data
            data = r.get_json()
            assert data["module"]["module_code"] == module_code
            assert data["code"] == destination.code

    def test_get_destination_unknown(self, users):
        set_logged_user(self.client, users["user"])
        r = self.client.get(url_for("import.get_destination", destinationCode="unknown"))
        assert r.status_code == 200, r.data
        assert r.get_json() == {}
