from datetime import datetime
from io import BytesIO
from pathlib import Path
from typing import Tuple

from geonature.core.imports.checks.errors import ImportCodeError
import pytest

from flask import url_for, g, current_app
from shapely import to_wkt
from werkzeug.datastructures import Headers
from werkzeug.exceptions import Conflict
from geoalchemy2.shape import from_shape
from shapely.geometry import Point

import sqlalchemy as sa
from sqlalchemy.orm import joinedload

from geonature.utils.env import db
from geonature.tests.utils import logged_user

from geonature.core.gn_commons.models import TModules

from pypnnomenclature.models import TNomenclatures, BibNomenclaturesTypes

from geonature.core.imports.models import Destination, TImports, BibFields
from geonature.tests.imports.utils import assert_import_errors


occhab = pytest.importorskip("gn_module_occhab")


from gn_module_occhab.models import Station, OccurenceHabitat


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
    fields = (
        db.session.scalars(
            sa.select(BibFields).filter_by(destination=occhab_destination, display=True)
        )
        .unique()
        .all()
    )
    return {field.name_field: field.name_field for field in fields}


@pytest.fixture()
def contentmapping(occhab_destination):
    """
    This content mapping matches cd_nomenclature AND mnemonique.
    """
    fields = (
        db.session.scalars(
            sa.select(BibFields)
            .filter_by(destination=occhab_destination, display=True)
            .filter(BibFields.nomenclature_type != None)
            .options(
                joinedload(BibFields.nomenclature_type).joinedload(
                    BibNomenclaturesTypes.nomenclatures
                ),
            )
        )
        .unique()
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
def uploaded_import(
    client,
    users,
    datasets,
    station,
    station_stranger_dataset,
    habitat,
    import_file_name,
    display_unique_dataset_id,
    coord_station_test_file,
):
    with open(test_files_path / import_file_name, "rb") as f:
        test_file_line_count = sum(1 for line in f) - 1  # remove headers
        f.seek(0)
        content = f.read()
        content = content.replace(
            b"EXISTING_STATION_UUID",
            station.unique_id_sinp_station.hex.encode("ascii"),
        )
        content = content.replace(
            b"STRANGER_STATION_UUID",
            station_stranger_dataset.unique_id_sinp_station.hex.encode("ascii"),
        )
        content = content.replace(
            b"EXISTING_HABITAT_UUID",
            habitat.unique_id_sinp_hab.hex.encode("ascii"),
        )
        content = content.replace(
            b"VALID_DATASET_UUID",
            datasets["own_dataset"].unique_dataset_id.hex.encode("ascii"),
        )
        content = content.replace(
            b"FORBIDDEN_DATASET_UUID",
            datasets["orphan_dataset"].unique_dataset_id.hex.encode("ascii"),
        )
        content = content.replace(
            b"INACTIVE_DATASET_UUID",
            datasets["own_dataset_not_activated"].unique_dataset_id.hex.encode("ascii"),
        )
        content = content.replace(
            b"COORD_STATION",
            to_wkt(coord_station_test_file[0]).encode("ascii"),
        )

        f = BytesIO(content)
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
    assert imprt.processed is True
    return imprt


@pytest.fixture()
def imported_import(client, prepared_import):
    imprt = prepared_import

    with logged_user(client, imprt.authors[0]):
        r = client.post(url_for("import.import_valid_data", import_id=imprt.id_import))
    assert r.status_code == 200, r.data
    db.session.refresh(imprt)
    return imprt


@pytest.fixture(scope="function")
def coord_station_test_file():
    return Point(3.634, 44.399), 4326


@pytest.fixture(scope="function")
def coord_station():
    return Point(4.634, 43.399), 4326


@pytest.fixture(scope="function")
def station(datasets, coord_station):
    station = Station(
        id_dataset=datasets["own_dataset"].id_dataset,
        date_min=datetime.strptime("17/11/2023", "%d/%m/%Y"),
        geom_4326=from_shape(*coord_station),
    )
    with db.session.begin_nested():
        db.session.add(station)
    return station


@pytest.fixture(scope="function")
def station_stranger_dataset(datasets, coord_station):
    station = Station(
        id_dataset=datasets["stranger_dataset"].id_dataset,
        date_min=datetime.strptime("17/11/2023", "%d/%m/%Y"),
        geom_4326=from_shape(*coord_station),
    )
    with db.session.begin_nested():
        db.session.add(station)
    return station


@pytest.fixture(scope="function")
def habitat(station):
    habitat = OccurenceHabitat(
        station=station,
        nom_cite="prairie",
        cd_hab=24,
        id_nomenclature_collection_technique=sa.func.pr_occhab.get_default_nomenclature_value(
            "TECHNIQUE_COLLECT_HAB"
        ),
    )
    with db.session.begin_nested():
        db.session.add(habitat)
    return habitat


@pytest.fixture()
def no_default_uuid(monkeypatch):
    monkeypatch.setitem(current_app.config["IMPORT"], "DEFAULT_GENERATE_MISSING_UUID", False)


@pytest.mark.usefixtures(
    "client_class",
    "temporary_transaction",
    "celery_eager",
    "default_occhab_destination",
)
class TestImportsOcchab:
    @pytest.mark.parametrize("import_file_name", ["valid_file.csv"])
    def test_import_valid_file(self, imported_import):

        assert_import_errors(
            imported_import,
            {
                # Stations errors
                (
                    ImportCodeError.DATASET_NOT_FOUND,
                    "station",
                    "unique_dataset_id",
                    frozenset({5}),
                ),
                (
                    ImportCodeError.DATASET_NOT_AUTHORIZED,
                    "station",
                    "unique_dataset_id",
                    frozenset({6}),
                ),
                (
                    ImportCodeError.DATASET_NOT_AUTHORIZED,
                    "habitat",
                    "",
                    frozenset({43}),
                ),
                (
                    ImportCodeError.DATASET_NOT_ACTIVE,
                    "station",
                    "unique_dataset_id",
                    frozenset({44}),
                ),
                (
                    ImportCodeError.INVALID_UUID,
                    "station",
                    "unique_id_sinp_station",
                    frozenset({24, 25}),
                ),
                (
                    ImportCodeError.INVALID_UUID,
                    "station",
                    "unique_dataset_id",
                    frozenset({7}),
                ),
                (
                    ImportCodeError.NO_GEOM,
                    "station",
                    "Champs géométriques",
                    frozenset({8}),
                ),
                (
                    ImportCodeError.MISSING_VALUE,
                    "station",
                    "date_min",
                    frozenset({9, 25}),
                ),
                (
                    ImportCodeError.INCOHERENT_DATA,
                    "station",
                    "unique_id_sinp_station",  # colonne de regroupement
                    frozenset({16, 17, 18, 19, 29, 30, 33, 34}),
                ),
                (
                    ImportCodeError.INCOHERENT_DATA,
                    "station",
                    "id_station_source",  # colonne de regroupement
                    frozenset({22, 23, 27, 28, 31, 32}),
                ),
                (
                    ImportCodeError.SKIP_EXISTING_UUID,
                    "station",
                    "unique_id_sinp_station",
                    frozenset({38}),  # seulement 38 car 39 et 40 même entité
                ),
                # Habitats errors
                (
                    ImportCodeError.INVALID_UUID,
                    "habitat",
                    "unique_id_sinp_station",
                    frozenset({24, 26}),
                ),
                (
                    ImportCodeError.INVALID_INTEGER,
                    "habitat",
                    "cd_hab",
                    frozenset({19}),
                ),
                (
                    ImportCodeError.ERRONEOUS_PARENT_ENTITY,
                    "habitat",
                    "",
                    frozenset({5, 6, 9, 24, 44}),
                ),
                (
                    ImportCodeError.NO_PARENT_ENTITY,
                    "habitat",
                    "id_station",
                    frozenset({10, 16, 17, 18, 22, 23, 27, 28, 29, 30, 31, 32, 33, 34}),  # 19,26?
                ),
                (
                    ImportCodeError.CONDITIONAL_MANDATORY_FIELD_ERROR,
                    "habitat",
                    "id_nomenclature_collection_technique",
                    frozenset({41}),
                ),
                (
                    ImportCodeError.SKIP_EXISTING_UUID,
                    "habitat",
                    "unique_id_sinp_habitat",
                    frozenset({40}),
                ),
                # Other errors
                (
                    ImportCodeError.ORPHAN_ROW,
                    None,
                    "unique_id_sinp_station",
                    frozenset({11, 13}),
                ),
                (
                    ImportCodeError.ORPHAN_ROW,
                    None,
                    "id_station_source",
                    frozenset({12, 13}),
                ),
            },
        )
        assert imported_import.statistics == {
            "import_count": 18,
            "station_count": 7,
            "habitat_count": 11,
            "nb_line_valid": 13,
        }
        assert (
            db.session.scalar(
                sa.select(sa.func.count()).where(Station.id_import == imported_import.id_import)
            )
            == imported_import.statistics["station_count"]
        )
        assert (
            db.session.scalar(
                sa.select(sa.func.count()).where(
                    OccurenceHabitat.id_import == imported_import.id_import
                )
            )
            == imported_import.statistics["habitat_count"]
        )

    @pytest.mark.parametrize("import_file_name", ["no_default_uuid.csv"])
    def test_import_without_default_uuid(self, no_default_uuid, imported_import):
        assert_import_errors(
            imported_import,
            {
                # Stations errors
                (
                    ImportCodeError.INVALID_UUID,
                    "station",
                    "unique_id_sinp_station",
                    frozenset({24, 25}),
                ),
                (
                    ImportCodeError.MISSING_VALUE,
                    "station",
                    "unique_id_sinp_station",
                    frozenset({20, 35}),
                ),
                (
                    ImportCodeError.MISSING_VALUE,
                    "station",
                    "date_min",
                    frozenset({25}),
                ),
                (
                    ImportCodeError.INCOHERENT_DATA,
                    "station",
                    "unique_id_sinp_station",  # colonne de regroupement
                    frozenset({16, 17, 18, 19, 29, 30, 33, 34}),
                ),
                (
                    ImportCodeError.INCOHERENT_DATA,
                    "station",
                    "id_station_source",  # colonne de regroupement
                    frozenset({22, 23, 27, 28, 31, 32}),
                ),
                (
                    ImportCodeError.SKIP_EXISTING_UUID,
                    "station",
                    "unique_id_sinp_station",
                    frozenset({38}),  # seulement 38 car 39 et 40 même entité
                ),
                # Habitats errors
                (
                    ImportCodeError.MISSING_VALUE,
                    "habitat",
                    "unique_id_sinp_habitat",
                    frozenset({5}),
                ),
                (
                    ImportCodeError.INVALID_UUID,
                    "habitat",
                    "unique_id_sinp_habitat",
                    frozenset({6}),
                ),
                (
                    ImportCodeError.INVALID_UUID,
                    "habitat",
                    "unique_id_sinp_station",
                    frozenset({24, 26}),
                ),
                (
                    ImportCodeError.INVALID_INTEGER,
                    "habitat",
                    "cd_hab",
                    frozenset({19}),
                ),
                (
                    ImportCodeError.ERRONEOUS_PARENT_ENTITY,
                    "habitat",
                    "",
                    frozenset({20, 21, 24, 35}),
                ),
                (
                    ImportCodeError.MISSING_VALUE,
                    "habitat",
                    "unique_id_sinp_station",
                    frozenset({10, 20, 21, 22, 23, 32, 35, 37}),
                ),
                (
                    ImportCodeError.NO_PARENT_ENTITY,
                    "habitat",
                    "id_station",
                    frozenset({16, 17, 18, 27, 28, 29, 30, 31, 33, 34}),  # 19,26?
                ),
                (
                    ImportCodeError.SKIP_EXISTING_UUID,
                    "habitat",
                    "unique_id_sinp_habitat",
                    frozenset({40}),
                ),
                # Other errors
                (
                    ImportCodeError.ORPHAN_ROW,
                    None,
                    "unique_id_sinp_station",
                    frozenset({11, 13}),
                ),
                (
                    ImportCodeError.ORPHAN_ROW,
                    None,
                    "id_station_source",
                    frozenset({12, 13}),
                ),
            },
        )
        assert imported_import.statistics == {
            "import_count": 9,
            "station_count": 3,
            "habitat_count": 6,
            "nb_line_valid": 7,
        }
        assert (
            db.session.scalar(
                sa.select(sa.func.count()).where(Station.id_import == imported_import.id_import)
            )
            == imported_import.statistics["station_count"]
        )
        assert (
            db.session.scalar(
                sa.select(sa.func.count()).where(
                    OccurenceHabitat.id_import == imported_import.id_import
                )
            )
            == imported_import.statistics["habitat_count"]
        )

    @pytest.mark.parametrize("import_file_name", ["valid_file.csv"])
    def test_remove_import_with_manual_children(self, client, users, imported_import):
        """
        This test verifies that it is not possible to remove an import if an imported entity
        has child data that do not come from this import (e.g. imported station with manually
        added habitat in Occhab).
        """
        # We get an imported station, and manually add an habitat to it.
        station = (
            db.session.execute(
                sa.select(Station).where(Station.id_import == imported_import.id_import).limit(1)
            )
            .scalars()
            .first()
        )
        habitat = OccurenceHabitat(station=station, cd_hab=24, nom_cite="prairie")
        with db.session.begin_nested():
            db.session.add(habitat)
        with logged_user(client, imported_import.authors[0]):
            r = client.delete(url_for("import.delete_import", import_id=imported_import.id_import))
        assert r.status_code == Conflict.code, r.data
        assert str(station.id_station) in r.json["description"]
        assert str(habitat.id_habitat) in r.json["description"]

    @pytest.mark.parametrize("import_file_name", ["valid_file.csv"])
    def test_bbox_computation(
        self,
        imported_import,
        coord_station: Tuple[Point, int],
        coord_station_test_file: Tuple[Point, int],
    ):
        bbox = imported_import.destination.actions.compute_bounding_box(imported_import)

        x1, y1 = coord_station[0].x, coord_station[0].y
        x2, y2 = coord_station_test_file[0].x, coord_station_test_file[0].y
        assert bbox == {
            "type": "Polygon",
            "coordinates": [
                [
                    [x2, y1],
                    [x2, y2],
                    [x1, y2],
                    [x1, y1],
                    [x2, y1],
                ]
            ],
        }

    @pytest.mark.parametrize("import_file_name", ["valid_file.csv"])
    def test_bbox_computation_transient(
        self,
        prepared_import,
        coord_station: Tuple[Point, int],
        coord_station_test_file: Tuple[Point, int],
    ):
        bbox = prepared_import.destination.actions.compute_bounding_box(prepared_import)

        x1, y1 = coord_station[0].x, coord_station[0].y
        x2, y2 = coord_station_test_file[0].x, coord_station_test_file[0].y
        assert bbox == {
            "type": "Polygon",
            "coordinates": [
                [
                    [x2, y1],
                    [x2, y2],
                    [x1, y2],
                    [x1, y1],
                    [x2, y1],
                ]
            ],
        }
