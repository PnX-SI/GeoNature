from io import StringIO
from pathlib import Path
from functools import partial
from operator import or_
from functools import reduce
import csv

import pytest
from flask import g, url_for, current_app
from werkzeug.datastructures import Headers
from werkzeug.exceptions import Unauthorized, Forbidden, BadRequest
from jsonschema import validate as validate_json
from sqlalchemy import func
from sqlalchemy.sql.expression import select

from apptax.taxonomie.models import BibListes, CorNomListe, BibNoms
from geonature.utils.env import db
from geonature.tests.utils import set_logged_user, unset_logged_user
from geonature.core.gn_permissions.tools import (
    get_scopes_by_action as _get_scopes_by_action,
)
from geonature.core.gn_permissions.models import PermAction, Permission, PermObject
from geonature.core.gn_commons.models import TModules
from geonature.core.gn_meta.models import TDatasets
from geonature.core.gn_synthese.models import Synthese, TSources
from geonature.tests.fixtures import synthese_data, celery_eager

from pypnusershub.db.models import User, Organisme
from pypnnomenclature.models import TNomenclatures, BibNomenclaturesTypes
from ref_geo.tests.test_ref_geo import has_french_dem
from ref_geo.models import LAreas

from geonature.core.imports.models import (
    TImports,
    FieldMapping,
    ContentMapping,
    BibFields,
)
from geonature.core.imports.utils import insert_import_data_in_transient_table

from .jsonschema_definitions import jsonschema_definitions
from .utils import assert_import_errors


tests_path = Path(__file__).parent

valid_file_expected_errors = {
    ("DUPLICATE_ENTITY_SOURCE_PK", "id_synthese", frozenset([4, 5])),
    ("COUNT_MIN_SUP_COUNT_MAX", "nombre_min", frozenset([6])),
}
valid_file_invalid_rows = reduce(or_, [rows for _, _, rows in valid_file_expected_errors])
valid_file_line_count = 6
valid_file_column_count = 76
valid_file_taxa_count = 2


@pytest.fixture(scope="class")
def g_permissions():
    """
    Fixture to initialize flask g variable
    Mandatory if we want to run this test file standalone
    """
    g._permissions_by_user = {}
    g._permissions = {}


@pytest.fixture()
def sample_area():
    return LAreas.query.filter(LAreas.area_name == "Bouches-du-Rhône").one()


@pytest.fixture(scope="function")
def imports(synthese_destination, users):
    def create_import(authors=[]):
        with db.session.begin_nested():
            imprt = TImports(destination=synthese_destination, authors=authors)
            db.session.add(imprt)
        return imprt

    return {
        "own_import": create_import(authors=[users["user"]]),
        "associate_import": create_import(authors=[users["associate_user"]]),
        "stranger_import": create_import(authors=[users["stranger_user"]]),
        "orphan_import": create_import(),
    }


@pytest.fixture()
def small_batch(monkeypatch):
    monkeypatch.setitem(current_app.config["IMPORT"], "DATAFRAME_BATCH_SIZE", 3)


@pytest.fixture()
def no_default_nomenclatures(monkeypatch):
    monkeypatch.setitem(
        current_app.config["IMPORT"], "FILL_MISSING_NOMENCLATURE_WITH_DEFAULT_VALUE", False
    )


@pytest.fixture()
def area_restriction(monkeypatch, sample_area):
    monkeypatch.setitem(current_app.config["IMPORT"], "ID_AREA_RESTRICTION", sample_area.id_area)


@pytest.fixture()
def import_file_name():
    return "valid_file.csv"


@pytest.fixture()
def autogenerate():
    return True


@pytest.fixture()
def import_dataset(datasets, import_file_name):
    ds = datasets["own_dataset"]
    if import_file_name == "nomenclatures_file.csv":
        previous_data_origin = ds.nomenclature_data_origin
        ds.nomenclature_data_origin = TNomenclatures.query.filter(
            TNomenclatures.nomenclature_type.has(
                BibNomenclaturesTypes.mnemonique == "DS_PUBLIQUE"
            ),
            TNomenclatures.mnemonique == "Privée",
        ).one()
    yield ds
    if import_file_name == "nomenclatures_file.csv":
        ds.nomenclature_data_origin = previous_data_origin


@pytest.fixture()
def new_import(synthese_destination, users, import_dataset):
    with db.session.begin_nested():
        imprt = TImports(
            destination=synthese_destination,
            authors=[users["user"]],
            id_dataset=import_dataset.id_dataset,
        )
        db.session.add(imprt)
    return imprt


@pytest.fixture()
def uploaded_import(new_import, import_file_name):
    with db.session.begin_nested():
        with open(tests_path / "files" / "synthese" / import_file_name, "rb") as f:
            new_import.source_file = f.read()
            new_import.full_file_name = "valid_file.csv"
    return new_import


@pytest.fixture()
def decoded_import(client, uploaded_import):
    set_logged_user(client, uploaded_import.authors[0])
    r = client.post(
        url_for(
            "import.decode_file",
            import_id=uploaded_import.id_import,
        ),
        data={
            "encoding": "utf-8",
            "format": "csv",
            "srid": 4326,
            "separator": ";",
        },
    )
    assert r.status_code == 200, r.data
    unset_logged_user(client)
    db.session.refresh(uploaded_import)
    return uploaded_import


@pytest.fixture()
def fieldmapping(import_file_name, autogenerate):
    if import_file_name == "valid_file.csv":
        return FieldMapping.query.filter_by(label="Synthese GeoNature").one().values
    else:
        return {
            f.name_field: autogenerate
            if f.autogenerated
            else ([f.name_field, "additional_data2"] if f.multi else f.name_field)
            for f in BibFields.query.filter_by(display=True)
        }


@pytest.fixture()
def field_mapped_import(client, decoded_import, fieldmapping):
    with db.session.begin_nested():
        decoded_import.fieldmapping = fieldmapping
    return decoded_import


@pytest.fixture()
def loaded_import(client, field_mapped_import):
    with db.session.begin_nested():
        field_mapped_import.source_count = insert_import_data_in_transient_table(
            field_mapped_import
        )
        field_mapped_import.loaded = True
    return field_mapped_import


@pytest.fixture()
def content_mapped_import(client, import_file_name, loaded_import):
    with db.session.begin_nested():
        loaded_import.contentmapping = (
            ContentMapping.query.filter_by(label="Nomenclatures SINP (labels)").one().values
        )
        if import_file_name == "empty_nomenclatures_file.csv":
            loaded_import.contentmapping["STADE_VIE"].update(
                {
                    "": "17",  # Alevin
                }
            )
    return loaded_import


@pytest.fixture()
def prepared_import(client, content_mapped_import, small_batch):
    set_logged_user(client, content_mapped_import.authors[0])
    r = client.post(url_for("import.prepare_import", import_id=content_mapped_import.id_import))
    assert r.status_code == 200, r.data
    unset_logged_user(client)
    db.session.refresh(content_mapped_import)
    return content_mapped_import


@pytest.fixture()
def imported_import(client, prepared_import):
    set_logged_user(client, prepared_import.authors[0])
    r = client.post(url_for("import.import_valid_data", import_id=prepared_import.id_import))
    assert r.status_code == 200, r.data
    unset_logged_user(client)
    db.session.refresh(prepared_import)
    return prepared_import


@pytest.fixture()
def sample_taxhub_list():
    cd_nom = 67111
    with db.session.begin_nested():
        id_list_not_exist = (db.session.query(func.max(BibListes.id_liste)).scalar() or 0) + 1
        bibTaxon = db.session.query(BibNoms).filter(BibNoms.cd_nom == cd_nom).first()
        if bibTaxon is None:
            bibTaxon = BibNoms(cd_nom=cd_nom, cd_ref=cd_nom)
            db.session.add(bibTaxon)
        taxa_list = BibListes(
            id_liste=id_list_not_exist, nom_liste="test", code_liste="test", picto=""
        )
        db.session.add(taxa_list)
    with db.session.begin_nested():
        db.session.add(CorNomListe(id_nom=bibTaxon.id_nom, id_liste=taxa_list.id_liste))
    return taxa_list


@pytest.fixture()
def change_id_list_conf(monkeypatch, sample_taxhub_list):
    monkeypatch.setitem(
        current_app.config["IMPORT"], "ID_LIST_TAXA_RESTRICTION", sample_taxhub_list.id_liste
    )


@pytest.mark.usefixtures(
    "client_class", "temporary_transaction", "celery_eager", "default_synthese_destination"
)
class TestImportsSynthese:
    def test_import_permissions(self, g_permissions, synthese_destination):
        with db.session.begin_nested():
            organisme = Organisme(nom_organisme="test_import")
            db.session.add(organisme)
            group = User(groupe=True)
            db.session.add(group)
            user = User(groupe=False)
            db.session.add(user)
            other_user = User(groupe=False)
            other_user.organisme = organisme
            db.session.add(other_user)
            user.groups.append(group)
            imprt = TImports(destination=synthese_destination)
            db.session.add(imprt)

        get_scopes_by_action = partial(
            _get_scopes_by_action,
            module_code="IMPORT",
            object_code="IMPORT",
        )
        assert get_scopes_by_action(user.id_role) == {action: 0 for action in "CRUVED"}

        update_action = PermAction.query.filter(PermAction.code_action == "U").one()
        import_module = TModules.query.filter(TModules.module_code == "IMPORT").one()
        import_object = PermObject.query.filter_by(code_object="IMPORT").one()

        # Add permission for it-self
        with db.session.begin_nested():
            permission = Permission(
                role=user,
                action=update_action,
                scope_value=1,
                module=import_module,
                object=import_object,
            )
            db.session.add(permission)
        # clean cache
        g._permissions = {}
        g._permissions_by_user = {}
        scope = get_scopes_by_action(user.id_role)["U"]
        assert scope == 1
        assert imprt.has_instance_permission(scope, user=user) is False
        imprt.authors.append(user)
        assert imprt.has_instance_permission(scope, user=user) is True

        # Change permission to organism filter
        permission.scope_value = 2
        db.session.commit()
        scope = get_scopes_by_action(user.id_role)["U"]
        assert scope == 2
        # right as we still are author:
        assert imprt.has_instance_permission(scope, user=user) is True
        imprt.authors.remove(user)
        assert imprt.has_instance_permission(scope, user=user) is False
        imprt.authors.append(other_user)
        db.session.commit()
        # we are not in the same organism than other_user:
        assert imprt.has_instance_permission(scope, user=user) is False
        organisme.members.append(user)
        db.session.commit()
        scope = get_scopes_by_action(user.id_role)["U"]
        assert imprt.has_instance_permission(scope, user=user) is True

        permission.scope_value = None
        imprt.authors.remove(other_user)
        db.session.commit()
        scope = get_scopes_by_action(user.id_role)["U"]
        assert scope == 3
        assert imprt.has_instance_permission(scope, user=user) is True

    def test_list_imports(self, imports, users):
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
        imports_ids = {imprt["id_import"] for imprt in json_data["imports"]}
        expected_imports_ids = {
            imports[imprt].id_import for imprt in ["own_import", "associate_import"]
        }
        assert imports_ids == expected_imports_ids

    def test_search_import(self, users, imports, uploaded_import):
        set_logged_user(self.client, users["user"])
        r = self.client.get(url_for("import.get_import_list") + "?search=valid_file")
        assert r.status_code == 200, r.data
        json_data = r.get_json()
        assert json_data["count"] == 1

    def test_order_import(self, users, imports, uploaded_import):
        set_logged_user(self.client, users["user"])
        r_des = self.client.get(url_for("import.get_import_list") + "?sort=id_import")
        assert r_des.status_code == 200, r_des.data
        r_asc = self.client.get(url_for("import.get_import_list") + "?sort=id_import&sort_dir=asc")
        assert r_asc.status_code == 200, r_asc.data
        import_ids_des = [imprt["id_import"] for imprt in r_des.get_json()["imports"]]
        import_ids_asc = [imprt["id_import"] for imprt in r_asc.get_json()["imports"]]
        assert import_ids_des == import_ids_asc[-1::-1]

    def test_order_import_foreign(self, users, imports, uploaded_import):
        set_logged_user(self.client, users["user"])
        response = self.client.get(
            url_for("import.get_import_list") + "?sort=dataset.dataset_name"
        )
        assert response.status_code == 200, response.data
        imports = response.get_json()["imports"]
        for a, b in zip(imports[:1], imports[1:]):
            assert (a["dataset"] is None) or (
                a["dataset"]["dataset_name"] <= b["dataset"]["dataset_name"]
            )

    def test_get_import(self, users, imports):
        def get(import_name):
            return self.client.get(
                url_for("import.get_one_import", import_id=imports[import_name].id_import)
            )

        assert get("own_import").status_code == Unauthorized.code

        set_logged_user(self.client, users["noright_user"])
        assert get("own_import").status_code == Forbidden.code

        set_logged_user(self.client, users["user"])
        assert get("stranger_import").status_code == Forbidden.code

        set_logged_user(self.client, users["self_user"])
        assert get("associate_import").status_code == Forbidden.code

        set_logged_user(self.client, users["user"])
        assert get("associate_import").status_code == 200
        r = get("own_import")
        assert r.status_code == 200, r.data
        assert r.json["id_import"] == imports["own_import"].id_import

    def test_delete_import(self, users, imported_import):
        imprt = imported_import
        transient_table = imprt.destination.get_transient_table()
        r = self.client.delete(url_for("import.delete_import", import_id=imprt.id_import))
        assert r.status_code == Unauthorized.code, r.data
        set_logged_user(self.client, users["admin_user"])
        r = self.client.delete(url_for("import.delete_import", import_id=imprt.id_import))
        assert r.status_code == 200, r.data
        # TODO: check data from synthese, and import tables are also removed
        r = self.client.delete(url_for("import.delete_import", import_id=imprt.id_import))
        assert r.status_code == 404, r.data
        transient_rows_count = db.session.execute(
            select([func.count()])
            .select_from(transient_table)
            .where(transient_table.c.id_import == imprt.id_import)
        ).scalar()
        assert transient_rows_count == 0

    def test_import_upload(self, users, datasets):
        with open(tests_path / "files" / "synthese" / "simple_file.csv", "rb") as f:
            data = {
                "file": (f, "simple_file.csv"),
                "datasetId": datasets["own_dataset"].id_dataset,
            }
            r = self.client.post(
                url_for("import.upload_file"),
                data=data,
                headers=Headers({"Content-Type": "multipart/form-data"}),
            )
            assert r.status_code == Unauthorized.code, r.data

        set_logged_user(self.client, users["noright_user"])
        with open(tests_path / "files" / "synthese" / "simple_file.csv", "rb") as f:
            data = {
                "file": (f, "simple_file.csv"),
                "datasetId": datasets["own_dataset"].id_dataset,
            }
            r = self.client.post(
                url_for("import.upload_file"),
                data=data,
                headers=Headers({"Content-Type": "multipart/form-data"}),
            )
            assert r.status_code == Forbidden.code, r.data
            assert "has no permissions to C in IMPORT" in r.json["description"]

        set_logged_user(self.client, users["user"])

        unexisting_id = db.session.query(func.max(TDatasets.id_dataset)).scalar() + 1
        with open(tests_path / "files" / "synthese" / "simple_file.csv", "rb") as f:
            data = {
                "file": (f, "simple_file.csv"),
                "datasetId": unexisting_id,
            }
            r = self.client.post(
                url_for("import.upload_file"),
                data=data,
                headers=Headers({"Content-Type": "multipart/form-data"}),
            )
            assert r.status_code == BadRequest.code, r.data
            assert r.json["description"] == f"Dataset '{unexisting_id}' does not exist."

        with open(tests_path / "files" / "synthese" / "simple_file.csv", "rb") as f:
            data = {
                "file": (f, "simple_file.csv"),
                "datasetId": datasets["stranger_dataset"].id_dataset,
            }
            r = self.client.post(
                url_for("import.upload_file"),
                data=data,
                headers=Headers({"Content-Type": "multipart/form-data"}),
            )
            assert r.status_code == Forbidden.code, r.data
            assert "jeu de données" in r.json["description"]  # this is a DS issue

        with open(tests_path / "files" / "synthese" / "simple_file.csv", "rb") as f:
            data = {
                "file": (f, "simple_file.csv"),
                "datasetId": datasets["own_dataset"].id_dataset,
            }
            r = self.client.post(
                url_for("import.upload_file"),
                data=data,
                headers=Headers({"Content-Type": "multipart/form-data"}),
            )
            assert r.status_code == 200, r.data

        imprt = db.session.get(TImports, r.json["id_import"])
        assert imprt.source_file is not None
        assert imprt.full_file_name == "simple_file.csv"

    def test_import_error(self, users, datasets):
        set_logged_user(self.client, users["user"])
        with open(tests_path / "files" / "synthese" / "empty.csv", "rb") as f:
            data = {
                "file": (f, "empty.csv"),
                "datasetId": datasets["own_dataset"].id_dataset,
            }
            r = self.client.post(
                url_for("import.upload_file"),
                data=data,
                headers=Headers({"Content-Type": "multipart/form-data"}),
            )
            assert r.status_code == 400, r.data
            assert r.json["description"] == "Impossible to upload empty files"
        with open(tests_path / "files" / "synthese" / "starts_with_empty_line.csv", "rb") as f:
            data = {
                "file": (f, "starts_with_empty_line.csv"),
                "datasetId": datasets["own_dataset"].id_dataset,
            }
            r = self.client.post(
                url_for("import.upload_file"),
                data=data,
                headers=Headers({"Content-Type": "multipart/form-data"}),
            )
            assert r.status_code == 400, r.data
            assert r.json["description"] == "File must start with columns"

    def test_import_upload_after_preparation(self, prepared_import):
        imprt = prepared_import
        # TODO: check old table does not exist
        # old_file_name = decoded_import.full_file_name
        set_logged_user(self.client, imprt.authors[0])
        with open(tests_path / "files" / "synthese" / "utf8_file.csv", "rb") as f:
            data = {
                "file": (f, "utf8_file.csv"),
                "datasetId": imprt.id_dataset,
            }
            r = self.client.put(
                url_for("import.upload_file", import_id=imprt.id_import),
                data=data,
                headers=Headers({"Content-Type": "multipart/form-data"}),
            )
            assert r.status_code == 200, r.data
        db.session.refresh(imprt)
        assert imprt.source_file is not None
        assert imprt.source_count == None
        assert imprt.loaded == False
        assert imprt.processed == False
        assert imprt.full_file_name == "utf8_file.csv"
        assert imprt.columns == None
        assert len(imprt.errors) == 0

    def test_import_decode(self, users, new_import):
        imprt = new_import
        data = {
            "encoding": "utf-16",
            "format": "csv",
            "srid": 2154,
            "separator": ";",
        }

        r = self.client.post(url_for("import.decode_file", import_id=imprt.id_import), data=data)
        assert r.status_code == Unauthorized.code, r.data

        set_logged_user(self.client, users["noright_user"])
        r = self.client.post(url_for("import.decode_file", import_id=imprt.id_import), data=data)
        assert r.status_code == Forbidden.code, r.data

        set_logged_user(self.client, users["user"])
        r = self.client.post(url_for("import.decode_file", import_id=imprt.id_import), data=data)
        assert r.status_code == BadRequest.code, r.data
        assert "first upload" in r.json["description"]

        imprt.full_file_name = "import.csv"
        imprt.detected_encoding = "utf-8"

        with open(tests_path / "files" / "synthese" / "utf8_file.csv", "rb") as f:
            imprt.source_file = f.read()
        db.session.flush()
        r = self.client.post(url_for("import.decode_file", import_id=imprt.id_import), data=data)
        assert r.status_code == BadRequest.code, r.data

        data["encoding"] = "utf-8"

        with open(tests_path / "files" / "synthese" / "duplicate_column_names.csv", "rb") as f:
            imprt.source_file = f.read()
        db.session.flush()
        r = self.client.post(url_for("import.decode_file", import_id=imprt.id_import), data=data)
        assert r.status_code == BadRequest.code, r.data
        assert "Duplicates column names" in r.json["description"]

        # with open(tests_path / "files" / "synthese" / "wrong_line_length.csv", "rb") as f:
        #    imprt.source_file = f.read()
        # r = self.client.post(
        #    url_for("import.decode_file", import_id=imprt.id_import), data=data
        # )
        # assert r.status_code == BadRequest.code, r.data
        # assert "Expected" in r.json["description"]

        wrong_separator_data = data.copy()
        wrong_separator_data["separator"] = "sep"
        r = self.client.post(
            url_for("import.decode_file", import_id=imprt.id_import),
            data=wrong_separator_data,
        )
        assert r.status_code == BadRequest.code, r.data

        with open(tests_path / "files" / "synthese" / "utf8_file.csv", "rb") as f:
            imprt.source_file = f.read()
        r = self.client.post(url_for("import.decode_file", import_id=imprt.id_import), data=data)
        assert r.status_code == 200, r.data

    def test_import_decode_after_preparation(self, users, prepared_import):
        imprt = prepared_import
        data = {
            "encoding": "utf-8",
            "format": "csv",
            "srid": 4326,
            "separator": ";",
        }
        set_logged_user(self.client, users["user"])
        r = self.client.post(url_for("import.decode_file", import_id=imprt.id_import), data=data)
        assert r.status_code == 200, r.data
        db.session.refresh(imprt)
        assert len(imprt.errors) == 0

    def test_import_preparation(self, users, content_mapped_import):
        imprt = content_mapped_import
        r = self.client.post(url_for("import.prepare_import", import_id=imprt.id_import))
        assert r.status_code == Unauthorized.code, r.data

        set_logged_user(self.client, users["stranger_user"])
        r = self.client.post(url_for("import.prepare_import", import_id=imprt.id_import))
        assert r.status_code == Forbidden.code, r.data

        set_logged_user(self.client, users["user"])
        r = self.client.post(url_for("import.prepare_import", import_id=imprt.id_import))
        assert r.status_code == 200, r.data
        assert frozenset(imprt.erroneous_rows) == valid_file_invalid_rows

    def test_import_columns(self, users, decoded_import):
        imprt = decoded_import

        r = self.client.get(url_for("import.get_import_columns_name", import_id=imprt.id_import))
        assert r.status_code == Unauthorized.code, r.data

        set_logged_user(self.client, users["stranger_user"])
        r = self.client.get(url_for("import.get_import_columns_name", import_id=imprt.id_import))
        assert r.status_code == Forbidden.code, r.data

        set_logged_user(self.client, users["user"])
        r = self.client.get(url_for("import.get_import_columns_name", import_id=imprt.id_import))
        assert r.status_code == 200, r.data
        assert "cd_nom" in r.json

    def test_import_loading(self, users, field_mapped_import):
        imprt = field_mapped_import
        transient_table = imprt.destination.get_transient_table()
        set_logged_user(self.client, users["user"])
        r = self.client.post(url_for("import.load_import", import_id=imprt.id_import))
        assert r.status_code == 200, r.data
        assert r.json["source_count"] == valid_file_line_count
        assert r.json["loaded"] == True
        transient_rows_count = db.session.execute(
            select([func.count()])
            .select_from(transient_table)
            .where(transient_table.c.id_import == imprt.id_import)
        ).scalar()
        assert transient_rows_count == r.json["source_count"]

    def test_import_values(self, users, loaded_import):
        imprt = loaded_import

        r = self.client.get(url_for("import.get_import_values", import_id=imprt.id_import))
        assert r.status_code == Unauthorized.code, r.data

        set_logged_user(self.client, users["stranger_user"])
        r = self.client.get(url_for("import.get_import_values", import_id=imprt.id_import))
        assert r.status_code == Forbidden.code, r.data

        set_logged_user(self.client, users["user"])
        r = self.client.get(url_for("import.get_import_values", import_id=imprt.id_import))
        assert r.status_code == 200, r.data
        schema = {
            "definitions": jsonschema_definitions,
            "type": "object",
            "patternProperties": {
                "^.*$": {  # keys are synthesis fields
                    "type": "object",
                    "properties": {
                        "nomenclature_type": {"$ref": "#/definitions/nomenclature_type"},
                        "nomenclatures": {  # list of acceptable nomenclatures for this field
                            "type": "array",
                            "items": {"$ref": "#/definitions/nomenclature"},
                            "minItems": 1,
                        },
                        "values": {  # available user values in uploaded file for this field
                            "type": "array",
                            "items": {
                                "type": [
                                    "string",
                                    "null",
                                ],
                            },
                        },
                    },
                    "required": [
                        "nomenclature_type",
                        "nomenclatures",
                        "values",
                    ],
                },
            },
        }
        validate_json(r.json, schema)

    def test_import_preview(self, users, prepared_import):
        imprt = prepared_import

        r = self.client.get(url_for("import.preview_valid_data", import_id=imprt.id_import))
        assert r.status_code == Unauthorized.code, r.data

        set_logged_user(self.client, users["stranger_user"])
        r = self.client.get(url_for("import.preview_valid_data", import_id=imprt.id_import))
        assert r.status_code == Forbidden.code, r.data

        set_logged_user(self.client, users["user"])
        r = self.client.get(url_for("import.preview_valid_data", import_id=imprt.id_import))
        assert r.status_code == 200, r.data
        assert r.json["entities"][0]["n_valid_data"] == imprt.source_count - len(
            valid_file_invalid_rows
        )
        assert r.json["entities"][0]["n_invalid_data"] == len(valid_file_invalid_rows)

    def test_import_invalid_rows(self, users, prepared_import):
        imprt = prepared_import
        r = self.client.get(
            url_for("import.get_import_invalid_rows_as_csv", import_id=imprt.id_import)
        )
        assert r.status_code == Unauthorized.code, r.data

        set_logged_user(self.client, users["stranger_user"])
        r = self.client.get(
            url_for("import.get_import_invalid_rows_as_csv", import_id=imprt.id_import)
        )
        assert r.status_code == Forbidden.code, r.data

        set_logged_user(self.client, users["user"])
        r = self.client.get(
            url_for("import.get_import_invalid_rows_as_csv", import_id=imprt.id_import)
        )
        assert r.status_code == 200, r.data
        csvfile = StringIO(r.data.decode("utf-8"))
        invalid_rows = reduce(or_, [rows for _, _, rows in valid_file_expected_errors])
        assert len(csvfile.readlines()) == 1 + len(invalid_rows)  # 1 = header

    def test_import_errors(self, users, prepared_import):
        imprt = prepared_import

        r = self.client.get(url_for("import.get_import_errors", import_id=imprt.id_import))
        assert r.status_code == Unauthorized.code, r.data

        set_logged_user(self.client, users["stranger_user"])
        r = self.client.get(url_for("import.get_import_errors", import_id=imprt.id_import))
        assert r.status_code == Forbidden.code, r.data

        set_logged_user(self.client, users["user"])
        r = self.client.get(url_for("import.get_import_errors", import_id=imprt.id_import))
        assert r.status_code == 200, r.data
        invalid_rows = reduce(
            or_, [rows for _, _, rows in valid_file_expected_errors]
        )  # TODO check?
        assert_import_errors(imprt, valid_file_expected_errors)
        validate_json(
            r.json,
            {
                "definitions": jsonschema_definitions,
                "type": "array",
                "items": {
                    "$ref": "#/definitions/error",
                },
            },
        )
        assert len(r.json) == len(valid_file_expected_errors)

    def test_import_valid_file(self, users, datasets):
        set_logged_user(self.client, users["user"])

        # Upload step
        test_file_name = "valid_file.csv"
        with open(tests_path / "files" / "synthese" / test_file_name, "rb") as f:
            test_file_line_count = sum(1 for line in f) - 1  # remove headers
            f.seek(0)
            data = {
                "file": (f, test_file_name),
                "datasetId": datasets["own_dataset"].id_dataset,
            }
            r = self.client.post(
                url_for("import.upload_file"),
                data=data,
                headers=Headers({"Content-Type": "multipart/form-data"}),
            )
        assert r.status_code == 200, r.data
        imprt_json = r.get_json()
        imprt = db.session.get(TImports, imprt_json["id_import"])
        assert len(imprt.authors) == 1
        assert imprt_json["date_create_import"]
        assert imprt_json["date_update_import"]
        assert imprt_json["detected_encoding"] == "utf-8"
        assert imprt_json["detected_format"] == "csv"
        assert imprt_json["detected_separator"] == ";"
        assert imprt_json["full_file_name"] == test_file_name
        assert imprt_json["id_dataset"] == datasets["own_dataset"].id_dataset

        # Decode step
        data = {
            "encoding": "utf-8",
            "format": "csv",
            "srid": 4326,
            "separator": ";",
        }
        r = self.client.post(url_for("import.decode_file", import_id=imprt.id_import), data=data)
        assert r.status_code == 200, r.data
        validate_json(
            r.json,
            {"definitions": jsonschema_definitions, "$ref": "#/definitions/import"},
        )
        assert imprt.date_update_import
        assert imprt.encoding == "utf-8"
        assert imprt.format_source_file == "csv"
        assert imprt.separator == ";"
        assert imprt.srid == 4326
        assert imprt.columns
        assert len(imprt.columns) == valid_file_column_count
        transient_table = imprt.destination.get_transient_table()
        transient_rows_count = db.session.execute(
            select([func.count()])
            .select_from(transient_table)
            .where(transient_table.c.id_import == imprt.id_import)
        ).scalar()
        assert transient_rows_count == 0

        # Field mapping step
        fieldmapping = FieldMapping.query.filter_by(label="Synthese GeoNature").one()
        r = self.client.post(
            url_for("import.set_import_field_mapping", import_id=imprt.id_import),
            data=fieldmapping.values,
        )
        assert r.status_code == 200, r.data
        validate_json(
            r.json,
            {"definitions": jsonschema_definitions, "$ref": "#/definitions/import"},
        )
        assert r.json["fieldmapping"] == fieldmapping.values

        # Loading step
        r = self.client.post(url_for("import.load_import", import_id=imprt.id_import))
        assert r.status_code == 200, r.data
        assert r.json["source_count"] == valid_file_line_count
        assert imprt.source_count == valid_file_line_count
        assert imprt.loaded == True
        transient_rows_count = db.session.execute(
            select([func.count()])
            .select_from(transient_table)
            .where(transient_table.c.id_import == imprt.id_import)
        ).scalar()
        assert transient_rows_count == test_file_line_count

        # Content mapping step
        contentmapping = ContentMapping.query.filter_by(label="Nomenclatures SINP (labels)").one()
        r = self.client.post(
            url_for("import.set_import_content_mapping", import_id=imprt.id_import),
            data=contentmapping.values,
        )
        assert r.status_code == 200, r.data
        data = r.get_json()
        validate_json(
            data,
            {"definitions": jsonschema_definitions, "$ref": "#/definitions/import"},
        )
        assert data["contentmapping"] == contentmapping.values

        # Prepare data before import
        r = self.client.post(url_for("import.prepare_import", import_id=imprt.id_import))
        assert r.status_code == 200, r.data
        validate_json(
            r.json,
            {"definitions": jsonschema_definitions, "$ref": "#/definitions/import"},
        )
        assert_import_errors(imprt, valid_file_expected_errors)

        # Get errors
        r = self.client.get(url_for("import.get_import_errors", import_id=imprt.id_import))
        assert r.status_code == 200, r.data
        assert len(r.json) == len(valid_file_expected_errors)

        # Get valid data (preview)
        r = self.client.get(url_for("import.preview_valid_data", import_id=imprt.id_import))
        assert r.status_code == 200, r.data
        assert r.json["entities"][0]["n_valid_data"] == imprt.source_count - len(
            valid_file_invalid_rows
        )
        assert r.json["entities"][0]["n_invalid_data"] == len(valid_file_invalid_rows)

        # Get invalid data
        # The with block forcefully close the request context, which may stay open due
        # to the usage of stream_with_context in this route.
        with self.client.get(
            url_for("import.get_import_invalid_rows_as_csv", import_id=imprt.id_import)
        ) as r:
            assert r.status_code == 200, r.data

        # Import step
        r = self.client.post(url_for("import.import_valid_data", import_id=imprt.id_import))
        assert r.status_code == 200, r.data
        data = r.get_json()
        validate_json(
            data,
            {"definitions": jsonschema_definitions, "$ref": "#/definitions/import"},
        )
        transient_rows_count = db.session.execute(
            select([func.count()])
            .select_from(transient_table)
            .where(transient_table.c.id_import == imprt.id_import)
        ).scalar()
        assert transient_rows_count == 0
        assert valid_file_line_count - len(valid_file_invalid_rows) == imprt.import_count
        assert valid_file_taxa_count == imprt.statistics["taxa_count"]
        source = TSources.query.filter_by(name_source=f"Import(id={imprt.id_import})").one()
        assert Synthese.query.filter_by(source=source).count() == imprt.import_count

        # Delete step
        r = self.client.delete(url_for("import.delete_import", import_id=imprt.id_import))
        assert r.status_code == 200, r.data

    @pytest.mark.parametrize("import_file_name", ["geom_file.csv"])
    @pytest.mark.parametrize("autogenerate", [False])
    def test_import_geometry_file(self, area_restriction, prepared_import):
        assert_import_errors(
            prepared_import,
            {
                ("INVALID_ATTACHMENT_CODE", "codecommune", frozenset([3])),
                ("INVALID_ATTACHMENT_CODE", "codedepartement", frozenset([5])),
                ("INVALID_ATTACHMENT_CODE", "codemaille", frozenset([7])),
                ("MULTIPLE_CODE_ATTACHMENT", "Champs géométriques", frozenset([8])),
                (
                    "MULTIPLE_ATTACHMENT_TYPE_CODE",
                    "Champs géométriques",
                    frozenset([11, 15]),
                ),
                ("NO-GEOM", "Champs géométriques", frozenset([16])),
                ("INVALID_GEOMETRY", "WKT", frozenset([17])),
                ("GEOMETRY_OUTSIDE", "Champs géométriques", frozenset([18, 19])),
            },
        )

    @pytest.mark.parametrize("import_file_name", ["cd_file.csv"])
    def test_import_cd_file(self, change_id_list_conf, prepared_import):
        assert_import_errors(
            prepared_import,
            {
                ("MISSING_VALUE", "cd_nom", frozenset([2, 5, 6])),
                ("CD_NOM_NOT_FOUND", "cd_nom", frozenset([3, 7, 9, 11])),
                ("CD_HAB_NOT_FOUND", "cd_hab", frozenset([5, 7, 8])),
                ("INVALID_INTEGER", "cd_nom", frozenset([12])),
                ("INVALID_INTEGER", "cd_hab", frozenset([13])),
            },
        )

    @pytest.mark.parametrize("import_file_name", ["source_pk_file.csv"])
    def test_import_source_pk_file(self, prepared_import):
        assert_import_errors(
            prepared_import,
            {
                (
                    "DUPLICATE_ENTITY_SOURCE_PK",
                    "entity_source_pk_value",
                    frozenset([5, 6]),
                ),
            },
        )

    @pytest.mark.parametrize("import_file_name", ["altitude_file.csv"])
    def test_import_altitude_file(self, prepared_import):
        french_dem = has_french_dem()
        if french_dem:
            alti_min_sup_alti_max = frozenset([4, 6, 9])
        else:
            alti_min_sup_alti_max = frozenset([9])
        assert_import_errors(
            prepared_import,
            {
                ("ALTI_MIN_SUP_ALTI_MAX", "altitude_min", alti_min_sup_alti_max),
                ("INVALID_INTEGER", "altitude_min", frozenset([10, 12])),
                ("INVALID_INTEGER", "altitude_max", frozenset([11, 12])),
            },
        )
        if has_french_dem():
            transient_table = prepared_import.destination.get_transient_table()
            altitudes = db.session.execute(
                select([transient_table.c.altitude_min, transient_table.c.altitude_max])
                .where(transient_table.c.id_import == prepared_import.id_import)
                .order_by(transient_table.c.line_no)
            ).fetchall()
            expected_altitudes = [
                (1389, 1389),
                (10, 1389),
                (5000, 1389),
                (1389, 5000),
                (1389, 10),
                (10, 10),
                (10, 20),
                (20, 10),
                (None, None),
                (None, None),
                (None, None),
            ]
            assert altitudes == expected_altitudes

    @pytest.mark.parametrize("import_file_name", ["uuid_file.csv"])
    def test_import_uuid_file(self, synthese_data, prepared_import):
        assert_import_errors(
            prepared_import,
            {
                ("DUPLICATE_UUID", "unique_id_sinp", frozenset([3, 4])),
                ("EXISTING_UUID", "unique_id_sinp", frozenset([5])),
                ("INVALID_UUID", "unique_id_sinp", frozenset([6])),
            },
        )
        transient_table = prepared_import.destination.get_transient_table()
        unique_id_sinp = db.session.execute(
            select([transient_table.c.unique_id_sinp])
            .where(transient_table.c.id_import == prepared_import.id_import)
            .where(transient_table.c.line_no == 7)
        ).scalar()
        assert unique_id_sinp != None

    @pytest.mark.parametrize("import_file_name", ["dates.csv"])
    def test_import_dates_file(self, prepared_import):
        assert_import_errors(
            prepared_import,
            {
                ("DATE_MIN_SUP_DATE_MAX", "date_min", frozenset({4, 10})),
                ("DATE_MIN_TOO_HIGH", "date_min", frozenset({3, 4})),
                ("DATE_MAX_TOO_HIGH", "date_max", frozenset({5})),
                ("MISSING_VALUE", "date_min", frozenset({12})),
                ("INVALID_DATE", "date_min", frozenset({13})),
                ("DATE_MIN_TOO_LOW", "date_min", frozenset({14, 15})),
                ("DATE_MAX_TOO_LOW", "date_max", frozenset({15})),
                ("INVALID_DATE", "meta_validation_date", frozenset({17})),
            },
        )

    @pytest.mark.parametrize("import_file_name", ["digital_proof.csv"])
    def test_import_digital_proofs_file(self, prepared_import):
        assert_import_errors(
            prepared_import,
            {
                ("INVALID_URL_PROOF", "digital_proof", frozenset({3, 5, 6})),
                (
                    "INVALID_EXISTING_PROOF_VALUE",
                    "id_nomenclature_exist_proof",
                    frozenset({9, 10, 12, 14, 16}),
                ),
            },
        )

    @pytest.mark.parametrize("import_file_name", ["depth.csv"])
    def test_import_depth_file(self, prepared_import):
        assert_import_errors(
            prepared_import,
            {
                ("DEPTH_MIN_SUP_ALTI_MAX", "depth_min", frozenset({7})),
            },
        )

    @pytest.mark.parametrize("import_file_name", ["nomenclatures_file.csv"])
    def test_import_nomenclatures_file(self, prepared_import):
        assert_import_errors(
            prepared_import,
            {
                ("INVALID_NOMENCLATURE", "id_nomenclature_exist_proof", frozenset({3})),
                (
                    "INVALID_EXISTING_PROOF_VALUE",
                    "id_nomenclature_exist_proof",
                    frozenset({5, 6, 7, 8}),
                ),
                (
                    "CONDITIONAL_MANDATORY_FIELD_ERROR",
                    "id_nomenclature_source_status",
                    frozenset({13}),
                ),
            },
        )

    @pytest.mark.parametrize("import_file_name", ["additional_data.csv"])
    def test_import_additional_data(self, imported_import):
        assert_import_errors(
            imported_import,
            set(),
        )
        source = TSources.query.filter_by(
            name_source=f"Import(id={imported_import.id_import})"
        ).one()
        obs = (
            Synthese.query.filter_by(source=source).order_by(Synthese.entity_source_pk_value).all()
        )
        assert [o.additional_data for o in obs] == [
            # json decoded, empty colums are ignored:
            {"a": "A"},
            # json are merged:
            {"a": "A", "b": "B"},
            # strings become new entries with column name as key
            {"a": "A", "additional_data2": "salut"},
            # list recognized as list:
            {"additional_data": [1, 2]},
            # integer and float are recongnized:
            {"additional_data": 3, "additional_data2": 4.2},
            # "" string (not an empty string!) is json-loaded as empty string and kept:
            {"a": "A", "additional_data2": ""},
        ]

    @pytest.mark.parametrize("import_file_name", ["empty_nomenclatures_file.csv"])
    def test_import_empty_nomenclatures_file(self, imported_import):
        assert_import_errors(
            imported_import,
            set(),
        )
        source = TSources.query.filter_by(
            name_source=f"Import(id={imported_import.id_import})"
        ).one()
        obs2 = Synthese.query.filter_by(source=source, entity_source_pk_value="2").one()
        # champs non mappé → valeur par défaut de la synthèse
        assert obs2.nomenclature_determination_method.label_default == "Non renseigné"
        # champs non mappé mais sans valeur par défaut dans la synthèse → NULL
        assert obs2.nomenclature_diffusion_level == None
        # champs mappé mais cellule vide → valeur par défaut de la synthèse
        assert obs2.nomenclature_naturalness.label_default == "Inconnu"
        obs3 = Synthese.query.filter_by(source=source, entity_source_pk_value="3").one()
        # Le champs est vide, mais on doit utiliser la valeur du mapping,
        # et ne pas l’écraser avec la valeur par défaut
        assert obs3.nomenclature_life_stage.label_default == "Alevin"

    @pytest.mark.parametrize("import_file_name", ["empty_nomenclatures_file.csv"])
    def test_import_empty_nomenclatures_file_no_default(
        self, no_default_nomenclatures, imported_import
    ):
        assert_import_errors(
            imported_import,
            {
                ("INVALID_NOMENCLATURE", "id_nomenclature_naturalness", frozenset({3})),
            },
        )
        source = TSources.query.filter_by(
            name_source=f"Import(id={imported_import.id_import})"
        ).one()
        obs3 = Synthese.query.filter_by(source=source, entity_source_pk_value="3").one()
        # champs non mappé → valeur par défaut de la synthèse
        assert obs3.nomenclature_determination_method.label_default == "Non renseigné"
        # champs non mappé mais sans valeur par défaut dans la synthèse → NULL
        assert obs3.nomenclature_diffusion_level == None
        # Le champs est vide, mais on doit utiliser la valeur du mapping,
        # et ne pas l’écraser avec la valeur par défaut
        assert obs3.nomenclature_life_stage.label_default == "Alevin"

    @pytest.mark.parametrize("import_file_name", ["multiline_comment_file.csv"])
    def test_import_multiline_comment_file(self, users, imported_import):
        assert_import_errors(
            imported_import,
            {
                ("MISSING_VALUE", "cd_nom", frozenset({2})),
                ("CD_NOM_NOT_FOUND", "cd_nom", frozenset({3})),
            },
        )

        source = TSources.query.filter_by(
            name_source=f"Import(id={imported_import.id_import})"
        ).one()
        obs = Synthese.query.filter_by(source=source).first()
        assert obs.comment_description == "Cette ligne\nest valide"

        set_logged_user(self.client, users["user"])
        r = self.client.get(
            url_for("import.get_import_invalid_rows_as_csv", import_id=imported_import.id_import)
        )
        assert r.status_code == 200, r.data
        csvfile = StringIO(r.data.decode("utf-8"))
        csvreader = csv.DictReader(csvfile, delimiter=";")
        rows = list(csvreader)
        assert rows[1]["comment_description"] == "Ligne erronée :\nCD_NOM_NOT_FOUND"

    def test_export_pdf(self, users, imports):
        user = users["user"]
        imprt = imports["own_import"]
        set_logged_user(self.client, user)

        resp = self.client.post(url_for("import.export_pdf", import_id=imprt.id_import))

        assert resp.status_code == 200
        assert resp.data
        assert resp.mimetype == "application/pdf"

    def test_export_pdf_forbidden(self, users, imports):
        user = users["stranger_user"]
        imprt = imports["own_import"]
        set_logged_user(self.client, user)

        resp = self.client.post(url_for("import.export_pdf", import_id=imprt.id_import))

        assert resp.status_code == Forbidden.code

    def test_get_import_source_file(self, users, uploaded_import):
        url = url_for("import.get_import_source_file", import_id=uploaded_import.id_import)

        resp = self.client.get(url)
        assert resp.status_code == Unauthorized.code

        set_logged_user(self.client, users["stranger_user"])
        resp = self.client.get(url)
        assert resp.status_code == Forbidden.code

        set_logged_user(self.client, users["user"])
        resp = self.client.get(url)
        assert resp.status_code == 200
        assert resp.content_length > 0
        assert "text/csv" in resp.mimetype
        assert "attachment" in resp.headers["Content-Disposition"]
        assert uploaded_import.full_file_name in resp.headers["Content-Disposition"]

    def test_get_nomenclatures(self):
        resp = self.client.get(url_for("import.get_nomenclatures"))

        assert resp.status_code == 200
        assert all(
            set(nomenclature.keys()) == {"nomenclature_type", "nomenclatures"}
            for nomenclature in resp.json.values()
        )
