from pathlib import Path

import pytest

from flask import url_for, g
from werkzeug.datastructures import Headers

from sqlalchemy.orm import joinedload

from geonature.utils.env import db
from geonature.tests.utils import logged_user

from geonature.core.gn_commons.models import TModules

from pypnnomenclature.models import TNomenclatures, BibNomenclaturesTypes

from geonature.core.imports.models import Destination, TImports, BibFields
from geonature.tests.imports.utils import assert_import_errors


occhab = pytest.importorskip("gn_module_occhab")


test_files_path = Path(__file__).parent / "files" / "occhab"


@pytest.fixture(scope="session")
def occhab_destination():
    return Destination.query.filter(Destination.module.has(TModules.module_code == "OCCHAB")).one()


@pytest.fixture(scope="class")
def default_occhab_destination(app, default_destination, occhab_destination):
    """
    This fixture set "occhab" as default destination when not specified in call to url_for.
    """
    g.default_destination = occhab_destination
    yield
    del g.default_destination


@pytest.fixture()
def fieldmapping(occhab_destination):
    fields = BibFields.query.filter_by(destination=occhab_destination, display=True).all()
    return {field.name_field: field.name_field for field in fields}


@pytest.fixture()
def contentmapping(occhab_destination):
    """
    This content mapping matches cd_nomenclature AND mnemonique.
    """
    fields = (
        BibFields.query.filter_by(destination=occhab_destination, display=True)
        .filter(BibFields.nomenclature_type != None)
        .options(
            joinedload(BibFields.nomenclature_type).joinedload(BibNomenclaturesTypes.nomenclatures),
        )
        .all()
    )
    return {
        field.nomenclature_type.mnemonique: {
            **{
                nomenclature.mnemonique: nomenclature.cd_nomenclature
                for nomenclature in field.nomenclature_type.nomenclatures
            },
            **{
                nomenclature.cd_nomenclature: nomenclature.cd_nomenclature
                for nomenclature in field.nomenclature_type.nomenclatures
            },
        }
        for field in fields
    }


@pytest.fixture()
def uploaded_import(client, users, datasets, import_file_name):
    with open(test_files_path / import_file_name, "rb") as f:
        test_file_line_count = sum(1 for line in f) - 1  # remove headers
        f.seek(0)
        data = {
            "file": (f, import_file_name),
            "datasetId": datasets["own_dataset"].id_dataset,
        }
        with logged_user(client, users["user"]):
            r = client.post(
                url_for("import.upload_file"),
                data=data,
                headers=Headers({"Content-Type": "multipart/form-data"}),
            )
    assert r.status_code == 200, r.data
    return TImports.query.get(r.json["id_import"])


@pytest.fixture()
def decoded_import(client, uploaded_import):
    imprt = uploaded_import
    with logged_user(client, imprt.authors[0]):
        r = client.post(
            url_for("import.decode_file", import_id=imprt.id_import),
            data={"encoding": "utf-8", "format": "csv", "srid": 4326, "separator": ";"},
        )
    assert r.status_code == 200, r.data
    db.session.refresh(imprt)
    return imprt


@pytest.fixture()
def field_mapped_import(client, decoded_import, fieldmapping):
    imprt = decoded_import
    with logged_user(client, imprt.authors[0]):
        r = client.post(
            url_for("import.set_import_field_mapping", import_id=imprt.id_import),
            data=fieldmapping,
        )
    assert r.status_code == 200, r.data
    db.session.refresh(imprt)
    return imprt


@pytest.fixture()
def loaded_import(client, field_mapped_import, fieldmapping):
    imprt = field_mapped_import
    with logged_user(client, imprt.authors[0]):
        r = client.post(url_for("import.load_import", import_id=imprt.id_import))
    assert r.status_code == 200, r.data
    db.session.refresh(imprt)
    return imprt


@pytest.fixture()
def content_mapped_import(client, loaded_import, contentmapping):
    imprt = loaded_import
    with logged_user(client, imprt.authors[0]):
        r = client.post(
            url_for("import.set_import_content_mapping", import_id=imprt.id_import),
            data=contentmapping,
        )
    assert r.status_code == 200, r.data
    db.session.refresh(imprt)
    return imprt


@pytest.fixture()
def prepared_import(client, content_mapped_import):
    imprt = content_mapped_import
    with logged_user(client, imprt.authors[0]):
        r = client.post(url_for("import.prepare_import", import_id=imprt.id_import))
    assert r.status_code == 200, r.data
    db.session.refresh(imprt)
    return imprt


@pytest.fixture()
def imported_import(client, prepared_import):
    imprt = prepared_import
    with logged_user(client, imprt.authors[0]):
        r = client.post(url_for("import.import_valid_data", import_id=imprt.id_import))
    assert r.status_code == 200, r.data
    db.session.refresh(imprt)
    return imprt


@pytest.mark.usefixtures(
    "client_class", "temporary_transaction", "celery_eager", "default_occhab_destination"
)
class TestImportsOcchab:
    @pytest.mark.parametrize("import_file_name", ["valid_file.csv"])
    def test_import_valid_file(self, imported_import):
        assert_import_errors(
            imported_import,
            {
                ("DATASET_NOT_AUTHORIZED", "unique_dataset_id", frozenset({2, 3, 4, 5})),
                ("DATASET_NOT_FOUND", "unique_dataset_id", frozenset({6})),
                ("INVALID_UUID", "unique_dataset_id", frozenset({7})),
                ("NO-GEOM", "Champs géométriques", frozenset({8})),
                ("MISSING_VALUE", "date_min", frozenset({7, 8})),
                ("ORPHAN_ROW", "id_station", frozenset({10})),
            },
        )
