from collections import namedtuple
from datetime import datetime

import pytest
import pandas as pd
import numpy as np
from flask import current_app

from geonature.core.gn_commons.models import TModules
from geonature.tests.fixtures import synthese_data
from shapely.geometry import Point

from geonature.core.imports.models import TImports, Destination, BibFields
from geonature.core.imports.checks.dataframe import *
from geonature.core.imports.checks.dataframe.geography import (
    check_wkt_inside_area_id,
    check_geometry_inside_l_areas,
)
from ref_geo.models import LAreas


Error = namedtuple("Error", ["error_code", "column", "invalid_rows"], defaults=([],))


@pytest.fixture()
def sample_area():
    return LAreas.query.filter(LAreas.area_name == "Bouches-du-Rhône").one()


@pytest.fixture()
def imprt():
    return TImports(
        id_import=42,
        srid="2154",
        destination=Destination.query.filter(
            Destination.module.has(TModules.module_code == "SYNTHESE")
        ).one(),
    )


def get_fields(imprt, names):
    return {
        name: BibFields.query.filter_by(destination=imprt.destination, name_field=name).one()
        for name in names
    }


def assert_errors(errors, expected):
    errors = frozenset(
        [
            Error(
                error_code=error["error_code"],
                column=error["column"],
                invalid_rows=frozenset(error["invalid_rows"].index.to_list()),
            )
            for error in errors
            if not error["invalid_rows"].empty
        ]
    )
    expected = frozenset(expected)
    assert errors == expected


@pytest.mark.usefixtures("app")
class TestChecks:
    def test_check_required_values(self, imprt):
        fields = get_fields(imprt, ["precision", "cd_nom", "nom_cite"])
        df = pd.DataFrame(
            [
                ["a", np.nan, "c"],
                [np.nan, "b", np.nan],
            ],
            columns=[field.source_column for field in fields.values()],
        )
        errors = check_required_values.__wrapped__(df, fields)
        assert_errors(
            errors,
            expected=[
                Error(error_code="MISSING_VALUE", column="cd_nom", invalid_rows=frozenset([0])),
                Error(error_code="MISSING_VALUE", column="nom_cite", invalid_rows=frozenset([1])),
            ],
        )

    def test_check_geography(self, imprt):
        fields = get_fields(
            imprt,
            [
                "the_geom_4326",
                "the_geom_local",
                "WKT",
                "longitude",
                "latitude",
                "codecommune",
                "codemaille",
                "codedepartement",
            ],
        )
        df = pd.DataFrame(
            [
                # [0] No geometry
                [None, None, None, None, None, None],
                # [1] No geometry
                [None, 2, None, None, None, None],
                # [2] No geometry
                [None, None, 3, None, None, None],
                # [3] WKT
                ["Point(600000 7000000)", None, None, None, None, None],
                # [4] XY
                [None, "600000", "7000000", None, None, None],
                # [5] Out-of-bounding-box
                ["Point(10 10)", None, None, None, None, None],
                # [6] Out-of-bounding-box
                [None, "10", "10", None, None, None],
                # [7] WKT and XY is an error
                ["Point(10 10)", "10", "10", None, None, None],
                # [8] Multiple code is an error
                [None, None, None, "42", "42", None],
                # [9] Multiple code is an error
                [None, None, None, "42", None, "42"],
                # [10] Multiple code is an error
                [None, None, None, None, "42", "42"],
                # [11] Multiple code is an error
                [None, None, None, "42", "42", "42"],
                # [12] Ok
                [None, None, None, "42", None, None],
                # [13] Ok
                [None, None, None, None, "42", None],
                # [14] Ok
                [None, None, None, None, None, "42"],
                # [15] Invalid WKT
                ["Point(a b)", None, None, None, None, None],
                # [16] Invalid XY
                [None, "a", "b", None, None, None],
                # [17] Codes are ignored if wkt
                ["Point(600000 7000000)", None, None, "42", "42", "42"],
                # [18] Codes are ignored if xy
                [None, "600000", "7000000", "42", "42", "42"],
            ],
            columns=[
                fields[n].source_field
                for n in [
                    "WKT",
                    "longitude",
                    "latitude",
                    "codecommune",
                    "codemaille",
                    "codedepartement",
                ]
            ],
        )
        errors = check_geography.__wrapped__(
            df,
            file_srid=imprt.srid,
            geom_4326_field=fields["the_geom_4326"],
            geom_local_field=fields["the_geom_local"],
            wkt_field=fields["WKT"],
            latitude_field=fields["latitude"],
            longitude_field=fields["longitude"],
            codecommune_field=fields["codecommune"],
            codemaille_field=fields["codemaille"],
            codedepartement_field=fields["codedepartement"],
        )
        assert_errors(
            errors,
            expected=[
                Error(
                    error_code="NO-GEOM",
                    column="Champs géométriques",
                    invalid_rows=frozenset([0, 1, 2]),
                ),
                Error(error_code="GEOMETRY_OUT_OF_BOX", column="WKT", invalid_rows=frozenset([5])),
                Error(
                    error_code="GEOMETRY_OUT_OF_BOX",
                    column="longitude",
                    invalid_rows=frozenset([6]),
                ),
                Error(
                    error_code="MULTIPLE_ATTACHMENT_TYPE_CODE",
                    column="Champs géométriques",
                    invalid_rows=frozenset([7]),
                ),
                Error(
                    error_code="MULTIPLE_CODE_ATTACHMENT",
                    column="Champs géométriques",
                    invalid_rows=frozenset([8, 9, 10, 11]),
                ),
                Error(error_code="INVALID_WKT", column="WKT", invalid_rows=frozenset([15])),
                Error(
                    error_code="INVALID_GEOMETRY", column="longitude", invalid_rows=frozenset([16])
                ),
            ],
        )

    def test_check_types(self, imprt):
        entity = imprt.destination.entities[0]
        uuid = "82ff094c-c3b3-11eb-9804-bfdc95e73f38"
        fields = get_fields(
            imprt,
            [
                "datetime_min",
                "datetime_max",
                "meta_v_taxref",
                "digital_proof",
                "id_digitiser",
                "unique_id_sinp",
            ],
        )
        df = pd.DataFrame(
            [
                ["2020-01-01", "2020-01-02", "taxref", "proof", "42", uuid],  # OK
                ["2020-01-01", "AAAAAAAAAA", "taxref", "proof", "42", uuid],  # KO: invalid date
                ["2020-01-01", "2020-01-02", "taxref", "proof", "AA", uuid],  # KO: invalid integer
                ["2020-01-01", "2020-01-02", "taxref", "proof", "42", "AA"],  # KO: invalid uuid
                ["2020-01-01", "2020-01-02", "A" * 80, "proof", "42", uuid],  # KO: invalid length
            ],
            columns=[field.source_column for field in fields.values()],
        )
        errors = list(check_types.__wrapped__(entity, df, fields))
        assert_errors(
            errors,
            expected=[
                Error(
                    error_code="INVALID_DATE", column="datetime_max", invalid_rows=frozenset([1])
                ),
                Error(
                    error_code="INVALID_INTEGER",
                    column="id_digitiser",
                    invalid_rows=frozenset([2]),
                ),
                Error(
                    error_code="INVALID_UUID", column="unique_id_sinp", invalid_rows=frozenset([3])
                ),
                Error(
                    error_code="INVALID_CHAR_LENGTH",
                    column="meta_v_taxref",
                    invalid_rows=frozenset([4]),
                ),
            ],
        )

    def test_concat_dates(self, imprt):
        entity = imprt.destination.entities[0]
        fields = get_fields(
            imprt,
            [
                "datetime_min",
                "datetime_max",
                "date_min",
                "date_max",
                "hour_min",
                "hour_max",
                "hour_max",
            ],
        )
        df = pd.DataFrame(
            [
                ["2020-01-01", "12:00:00", "2020-01-02", "14:00:00"],
                ["2020-01-01", None, "2020-01-02", "14:00:00"],
                ["2020-01-01", "12:00:00", None, "14:00:00"],
                ["2020-01-01", "12:00:00", "2020-01-01", None],
                ["2020-01-01", "12:00:00", "2020-01-02", None],
                ["2020-01-01", "12:00:00", None, None],
                ["2020-01-01", None, "2020-01-02", None],
                ["2020-01-01", None, None, "14:00:00"],
                ["2020-01-01", None, None, None],
                [None, "12:00:00", "2020-01-02", "14:00:00"],
                ["bogus", "12:00:00", "2020-01-02", "14:00:00"],
            ],
            columns=[
                fields[n].source_field for n in ["date_min", "hour_min", "date_max", "hour_max"]
            ],
        )
        concat_dates(df, *fields.values())
        errors = list(check_required_values.__wrapped__(df, fields))
        assert_errors(
            errors,
            expected=[
                Error(error_code="MISSING_VALUE", column="date_min", invalid_rows=frozenset([9])),
            ],
        )
        errors = list(check_types.__wrapped__(entity, df, fields))
        assert_errors(
            errors,
            expected=[
                Error(
                    error_code="INVALID_DATE", column="datetime_min", invalid_rows=frozenset([10])
                ),
            ],
        )
        pd.testing.assert_frame_equal(
            df.loc[:, [fields["datetime_min"].dest_field, fields["datetime_max"].dest_field]],
            pd.DataFrame(
                [
                    [datetime(2020, 1, 1, 12), datetime(2020, 1, 2, 14)],
                    [datetime(2020, 1, 1, 0), datetime(2020, 1, 2, 14)],
                    [datetime(2020, 1, 1, 12), datetime(2020, 1, 1, 14)],
                    [datetime(2020, 1, 1, 12), datetime(2020, 1, 1, 12)],
                    [datetime(2020, 1, 1, 12), datetime(2020, 1, 2, 0)],
                    [datetime(2020, 1, 1, 12), datetime(2020, 1, 1, 12)],
                    [datetime(2020, 1, 1, 0), datetime(2020, 1, 2, 0)],
                    [datetime(2020, 1, 1, 0), datetime(2020, 1, 1, 14)],
                    [datetime(2020, 1, 1, 0), datetime(2020, 1, 1, 0)],
                    [pd.NaT, datetime(2020, 1, 2, 14)],
                    [pd.NaT, datetime(2020, 1, 2, 14)],
                ],
                columns=[fields[name].dest_field for name in ("datetime_min", "datetime_max")],
            ),
        )

    def test_dates_parsing(self, imprt):
        entity = imprt.destination.entities[0]
        fields = get_fields(imprt, ["date_min", "hour_min", "datetime_min", "datetime_max"])
        df = pd.DataFrame(
            [
                ["2020-01-05", None],
                ["2020/01/05", None],
                ["2020-1-05", None],
                ["2020/01/5", None],
                ["05-01-2020", None],
                ["05/01/2020", None],
                ["05-1-2020", None],
                ["5/01/2020", None],
                ["2020.01.05", None],
                ["05.01.2020", None],
                ["0027-01-20", None],
                ["2020-01-05", "13"],
                ["2020-01-05", "13:12"],
                ["2020-01-05", "13:12:05"],
                ["2020-01-05", "13h"],
                ["2020-01-05", "13h12"],
                ["2020-01-05", "13h12m"],
                ["2020-01-05", "13h12m05s"],
            ],
            columns=[fields["date_min"].source_field, fields["hour_min"].source_field],
        )
        concat_dates(
            df,
            datetime_min_field=fields["datetime_min"],
            datetime_max_field=fields["datetime_max"],
            date_min_field=fields["date_min"],
            hour_min_field=fields["hour_min"],
        )
        errors = list(check_types.__wrapped__(entity, df, fields))
        assert_errors(errors, expected=[])
        pd.testing.assert_frame_equal(
            df.loc[:, [fields["datetime_min"].dest_field]],
            pd.DataFrame(
                [
                    [datetime(2020, 1, 5, 0)],
                    [datetime(2020, 1, 5, 0)],
                    [datetime(2020, 1, 5, 0)],
                    [datetime(2020, 1, 5, 0)],
                    [datetime(2020, 1, 5, 0)],
                    [datetime(2020, 1, 5, 0)],
                    [datetime(2020, 1, 5, 0)],
                    [datetime(2020, 1, 5, 0)],
                    [datetime(2020, 1, 5, 0)],
                    [datetime(2020, 1, 5, 0)],
                    [datetime(27, 1, 20, 0)],  # no date_min_too_low error as checked at sql level
                    [datetime(2020, 1, 5, 13)],
                    [datetime(2020, 1, 5, 13, 12)],
                    [datetime(2020, 1, 5, 13, 12, 5)],
                    [datetime(2020, 1, 5, 13)],
                    [datetime(2020, 1, 5, 13, 12)],
                    [datetime(2020, 1, 5, 13, 12)],
                    [datetime(2020, 1, 5, 13, 12, 5)],
                ],
                columns=[fields["datetime_min"].dest_field],
            ),
        )

    def test_check_counts(self, imprt):
        default_value = current_app.config["IMPORT"]["DEFAULT_COUNT_VALUE"]
        fields = get_fields(imprt, ["count_min", "count_max"])
        count_min_field = fields["count_min"]
        count_max_field = fields["count_max"]

        df = pd.DataFrame(
            [
                [None, None],
                [1, None],
                [None, 2],
                [1, 2],
                [2, 1],
                [20, 5],
            ],
            columns=[field.dest_field for field in fields.values()],
        )
        errors = list(
            check_counts.__wrapped__(
                df, count_min_field, count_max_field, default_count=default_value
            )
        )
        assert_errors(
            errors,
            expected=[
                Error(
                    error_code="COUNT_MIN_SUP_COUNT_MAX",
                    column="count_min",
                    invalid_rows=frozenset([4, 5]),
                ),
            ],
        )
        pd.testing.assert_frame_equal(
            df.loc[:, [field.dest_field for field in fields.values()]],
            pd.DataFrame(
                [
                    [default_value, default_value],
                    [1, 1],
                    [default_value, 2],
                    [1, 2],
                    [2, 1],
                    [20, 5],
                ],
                columns=[field.dest_field for field in fields.values()],
                dtype=float,
            ),
        )
        df = pd.DataFrame(
            [
                [None],
                [2],
            ],
            columns=[count_min_field.dest_field],
        )
        errors = list(
            check_counts.__wrapped__(
                df, count_min_field, count_max_field, default_count=default_value
            )
        )
        assert_errors(errors, [])
        pd.testing.assert_frame_equal(
            df.loc[:, [count_min_field.dest_field, count_max_field.dest_field]],
            pd.DataFrame(
                [
                    [default_value, default_value],
                    [2, 2],
                ],
                columns=[
                    count_min_field.dest_field,
                    count_max_field.dest_field,
                ],
                dtype=float,
            ),
        )

        df = pd.DataFrame(
            [
                [None],
                [2],
            ],
            columns=[count_max_field.dest_field],
        )
        errors = list(
            check_counts.__wrapped__(
                df, count_min_field, count_max_field, default_count=default_value
            )
        )
        assert_errors(errors, [])
        pd.testing.assert_frame_equal(
            df.loc[:, [count_min_field.dest_field, count_max_field.dest_field]],
            pd.DataFrame(
                [
                    [default_value, default_value],
                    [2, 2],
                ],
                columns=[
                    count_min_field.dest_field,
                    count_max_field.dest_field,
                ],
                dtype=float,
            ),
        )

        df = pd.DataFrame([[], []])
        errors = list(
            check_counts.__wrapped__(
                df, count_min_field, count_max_field, default_count=default_value
            )
        )
        assert_errors(errors, [])
        pd.testing.assert_frame_equal(
            df.loc[:, [count_min_field.dest_field, count_max_field.dest_field]],
            pd.DataFrame(
                [
                    [default_value, default_value],
                    [default_value, default_value],
                ],
                columns=[
                    count_min_field.dest_field,
                    count_max_field.dest_field,
                ],
            ),
        )

    def test_check_wkt_inside_area_id(self, imprt, sample_area):
        wkt = "POINT(900000 6250000)"

        check = check_wkt_inside_area_id(id_area=sample_area.id_area, wkt=wkt, wkt_srid=imprt.srid)

        assert check

    def test_check_wkt_inside_area_id_outside(self, imprt, sample_area):
        wkt = "Point(6000000 700000)"

        check = check_wkt_inside_area_id(id_area=sample_area.id_area, wkt=wkt, wkt_srid=imprt.srid)

        assert not check

    def test_check_geometry_inside_l_areas(self, imprt, sample_area):
        point = Point(900000, 6250000)

        check = check_geometry_inside_l_areas(
            id_area=sample_area.id_area, geometry=point, geom_srid=imprt.srid
        )

        assert check

    def test_check_geometry_inside_l_areas_outside(self, imprt, sample_area):
        point = Point(6000000, 700000)

        check = check_geometry_inside_l_areas(
            id_area=sample_area.id_area, geometry=point, geom_srid=imprt.srid
        )

        assert not check
