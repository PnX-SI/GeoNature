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

from geonature.tests.utils import set_logged_user, unset_logged_user

occhab = pytest.importorskip("gn_module_occhab")


from gn_module_occhab.models import Station, OccurenceHabitat


# ######################################################################################
# Fixtures -- override default values
# ######################################################################################


@pytest.fixture(scope="class")
def testfiles_folder():  # provide with a default value - should bve overriden
    return "occhab"


@pytest.fixture(scope="class")
def module_code():
    return "OCCHAB"


@pytest.fixture(scope="class")
def fieldmapping_preset_name():
    return ""


@pytest.fixture()
def autogenerate():
    return False


@pytest.fixture(scope="function")
def override_in_importfile(
    import_datasets,
    station,
    station_stranger_dataset,
    coord_station_test_file,
    habitat,
):
    return {
        "@EXISTING_STATION_UUID@": str(station.unique_id_sinp_station),
        "@STRANGER_STATION_UUID@": str(station_stranger_dataset.unique_id_sinp_station),
        "@EXISTING_HABITAT_UUID@": str(habitat.unique_id_sinp_hab),
        "@VALID_DATASET_UUID@": str(import_datasets["user"].unique_dataset_id),
        "@FORBIDDEN_DATASET_UUID@": str(import_datasets["admin"].unique_dataset_id),
        "@INACTIVE_DATASET_UUID@": str(import_datasets["user--inactive"].unique_dataset_id),
        "@DATASET_NOT_FOUND@": "03905a03-c7fa-4642-b143-5005fa805377",
        "@COORD_STATION@": to_wkt(coord_station_test_file[0]),
    }


@pytest.fixture(scope="class")
def contentmapping_preset_name():
    return None


@pytest.fixture(scope="function")
def add_in_contentmapping():
    return {}


@pytest.fixture()
def no_default_uuid(monkeypatch):
    monkeypatch.setitem(current_app.config["IMPORT"], "DEFAULT_GENERATE_MISSING_UUID", False)


# ######################################################################################
# Fixtures -- station
# ######################################################################################


@pytest.fixture(scope="function")
def coord_station_test_file():
    return Point(3.634, 44.399), 4326


@pytest.fixture(scope="function")
def coord_station():
    return Point(4.634, 43.399), 4326


@pytest.fixture(scope="function")
def station(import_datasets, coord_station):
    station = Station(
        id_dataset=import_datasets["user"].id_dataset,
        date_min=datetime.strptime("17/11/2023", "%d/%m/%Y"),
        geom_4326=from_shape(*coord_station),
    )
    with db.session.begin_nested():
        db.session.add(station)
    return station


@pytest.fixture(scope="function")
def station_stranger_dataset(import_datasets, coord_station):
    station = Station(
        id_dataset=import_datasets["admin"].id_dataset,
        date_min=datetime.strptime("17/11/2023", "%d/%m/%Y"),
        geom_4326=from_shape(*coord_station),
    )
    with db.session.begin_nested():
        db.session.add(station)
    return station


# ######################################################################################
# Fixtures -- habitat
# ######################################################################################


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


# ######################################################################################
# TestImportsOcchab
# ######################################################################################


@pytest.mark.usefixtures(
    "client_class",
    "temporary_transaction",
    "celery_eager",
    "import_destination",
    "default_import_destination",
    "module_code",
    "fieldmapping_preset_name",
    "testfiles_folder",
    "contentmapping_preset_name",
)
class TestImportsOcchab:

    def test_import_valid_file(self, datasets, imported_import):
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

    @pytest.mark.parametrize("import_file_name", ["valid_file.csv"])
    def test_preview_data(self, client, prepared_import):
        valid_numbers = {
            "station_valid": 7,
            "station_invalid": 8,
            "habitat_valid": 11,
            "habitat_invalid": 23,
        }
        imprt = prepared_import
        with logged_user(client, imprt.authors[0]):
            response = client.get(url_for("import.preview_valid_data", import_id=imprt.id_import))
        assert response.status_code == 200
        data = response.json

        index_data_station = 0 if data["entities"][0]["entity"]["code"] == "station" else 1
        data_station = data["entities"][index_data_station]
        data_habitat = data["entities"][0 if index_data_station == 1 else 1]

        assert data_station["n_valid_data"] == valid_numbers["station_valid"]
        assert data_station["n_invalid_data"] == valid_numbers["station_invalid"]

        assert data_habitat["n_valid_data"] == valid_numbers["habitat_valid"]
        assert data_habitat["n_invalid_data"] == valid_numbers["habitat_invalid"]
