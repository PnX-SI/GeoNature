from io import StringIO
import csv
import datetime
import itertools
from collections import Counter

import pytest
from flask import url_for, current_app
import sqlalchemy as sa
import pandas as pd
from sqlalchemy import func, select
from werkzeug.exceptions import Forbidden, BadRequest, Unauthorized
from jsonschema import validate as validate_json
from geoalchemy2.shape import to_shape, from_shape
from shapely.testing import assert_geometries_equal
from shapely.geometry import Point
from marshmallow import EXCLUDE, fields, Schema
from marshmallow_geojson import FeatureSchema, GeoJSONSchema


from geonature.utils.env import db
from geonature.utils.config import config
from geonature.core.gn_permissions.tools import get_permissions
from geonature.core.gn_synthese.utils.blurring import split_blurring_precise_permissions
from geonature.core.gn_synthese.schemas import SyntheseSchema
from geonature.core.gn_synthese.utils.query_select_sqla import remove_accents
from geonature.core.sensitivity.models import cor_sensitivity_area_type
from geonature.core.gn_meta.models import TDatasets
from geonature.core.gn_synthese.models import Synthese, TSources, VSyntheseForWebApp
from geonature.core.gn_synthese.synthese_config import MANDATORY_COLUMNS

from geonature.core.gn_synthese.schemas import SyntheseSchema
from geonature.core.gn_permissions.models import PermAction, Permission
from geonature.core.gn_commons.models.base import TModules

from apptax.taxonomie.models import Taxref
from ref_geo.models import BibAreasTypes, LAreas
from apptax.tests.fixtures import noms_example, attribut_example
from pypnusershub.tests.utils import logged_user_headers, set_logged_user

from utils_flask_sqla_geo.schema import GeoModelConverter, GeoAlchemyAutoSchema

from .fixtures import *
from .fixtures import create_synthese, create_module, synthese_with_protected_status


@pytest.fixture()
def unexisted_id():
    return (
        db.session.execute(select(func.max(TDatasets.id_dataset)).select_from(TDatasets)).scalar()
        + 1
    )


@pytest.fixture()
def source():
    source = TSources(name_source="test source")
    with db.session.begin_nested():
        db.session.add(source)
    return source


@pytest.fixture()
def unexisted_id_source(source):
    return (
        db.session.execute(select(func.max(TSources.id_source)).select_from(TSources)).scalar_one()
        + 1
    )


@pytest.fixture()
def taxon_attribut(noms_example, attribut_example, synthese_data):
    """
    Require "taxonomie_taxons_example" and "taxonomie_attributes_example" alembic branches.
    """
    from apptax.taxonomie.models import BibAttributs, BibNoms, CorTaxonAttribut

    nom = db.session.scalars(select(BibNoms).filter_by(cd_ref=209902)).one()
    attribut = db.session.scalars(
        select(BibAttributs).filter_by(nom_attribut=attribut_example.nom_attribut)
    ).one()
    with db.session.begin_nested():
        c = CorTaxonAttribut(bib_nom=nom, bib_attribut=attribut, valeur_attribut="eau")
        db.session.add(c)
    return c


@pytest.fixture()
def synthese_for_observers(source, datasets):
    """
    Seems redondant with synthese_data fixture, but synthese data
    insert in cor_observers_synthese and run a trigger which override the observers_txt field
    """
    now = datetime.datetime.now()
    taxon = db.session.scalars(select(Taxref)).first()
    point = Point(5.486786, 42.832182)
    geom = from_shape(point, srid=4326)
    with db.session.begin_nested():
        for obs in ["Vincent", "Camille", "Camille, Xavier"]:
            db.session.add(
                Synthese(
                    id_source=source.id_source,
                    nom_cite=taxon.lb_nom,
                    cd_nom=taxon.cd_nom,
                    dataset=datasets["own_dataset"],
                    date_min=now,
                    date_max=now,
                    observers=obs,
                    the_geom_4326=geom,
                    the_geom_point=geom,
                    the_geom_local=func.st_transform(geom, 2154),
                )
            )


# TODO : move and use those schemas in routes one day !
class CustomRequiredConverter(GeoModelConverter):
    """Custom converter to add kwargs required for mandatory and asked fields in get_observations_for_web view
    Use to validate response in test"""

    def _add_column_kwargs(self, kwargs, column):
        super()._add_column_kwargs(kwargs, column)
        default_cols = map(
            lambda col: col["prop"],
            config["SYNTHESE"]["LIST_COLUMNS_FRONTEND"]
            + config["SYNTHESE"]["ADDITIONAL_COLUMNS_FRONTEND"],
        )
        required_cols = list(default_cols) + MANDATORY_COLUMNS
        kwargs["required"] = column.name in required_cols


class VSyntheseForWebAppSchema(GeoAlchemyAutoSchema):
    """
    Schema for serialization/deserialization of VSyntheseForWebApp class
    """

    count_min_max = fields.Str()
    nom_vern_or_lb_nom = fields.Str()

    class Meta:
        model = VSyntheseForWebApp
        model_converter = CustomRequiredConverter


# utility classes for VSyntheseForWebAppSchema validation
class UngroupedFeatureSchema(FeatureSchema):
    properties = fields.Nested(
        VSyntheseForWebAppSchema,
        required=True,
    )


class GroupedFeatureSchema(FeatureSchema):
    class NestedObs(Schema):
        observations = fields.List(
            fields.Nested(VSyntheseForWebAppSchema, required=True), required=True
        )

    properties = fields.Nested(NestedObs, required=True)


class UngroupedGeoJSONSchema(GeoJSONSchema):
    feature_schema = UngroupedFeatureSchema


class GroupedGeoJSONSchema(GeoJSONSchema):
    feature_schema = GroupedFeatureSchema


@pytest.mark.usefixtures("client_class", "temporary_transaction")
class TestSynthese:
    def test_required_fields_and_format(self, app, users):
        # Test required fields base on VSyntheseForWebAppSchema surrounded by a custom converter : CustomRequiredConverter
        # also test geojson serialization (grouped by geometry and not)
        app.config["SYNTHESE"]["LIST_COLUMNS_FRONTEND"] += [
            {"prop": "altitude_min", "name": "Altitude min"},
            {"prop": "count_min_max", "name": "Dénombrement"},
            {"prop": "nom_vern_or_lb_nom", "name": "Taxon"},
        ]

        app.config["SYNTHESE"]["ADDITIONAL_COLUMNS_FRONTEND"] += [
            {"prop": "lb_nom", "name": "Nom scientifique"}
        ]
        url_ungrouped = url_for("gn_synthese.get_observations_for_web")
        set_logged_user(self.client, users["admin_user"])
        resp = self.client.get(url_ungrouped)
        for f in resp.json["features"]:
            UngroupedGeoJSONSchema().load(f)

        url_grouped = url_for("gn_synthese.get_observations_for_web", format="grouped_geom")
        resp = self.client.get(url_grouped)
        for f in resp.json["features"]:
            GroupedGeoJSONSchema().load(f)

    def test_synthese_scope_filtering(self, app, users, synthese_data):
        all_ids = {s.id_synthese for s in synthese_data.values()}
        sq = (
            select(Synthese)
            .with_only_columns(Synthese.id_synthese)
            .where(Synthese.id_synthese.in_(all_ids))
        )
        with app.test_request_context(headers=logged_user_headers(users["user"])):
            app.preprocess_request()
            assert db.session.scalars(Synthese.filter_by_scope(0, query=sq)).all() == []

    def test_list_sources(self, source, users):
        set_logged_user(self.client, users["self_user"])
        response = self.client.get(url_for("gn_synthese.get_sources"))
        assert response.status_code == 200
        data = response.get_json()
        assert len(data) > 0

    def test_get_defaut_nomenclatures(self, users):
        set_logged_user(self.client, users["self_user"])
        response = self.client.get(url_for("gn_synthese.getDefaultsNomenclatures"))
        assert response.status_code == 200

    def test_get_observations_for_web(self, app, users, synthese_data, taxon_attribut):
        url = url_for("gn_synthese.get_observations_for_web")
        r = self.client.get(url)
        assert r.status_code == Unauthorized.code

        set_logged_user(self.client, users["self_user"])

        r = self.client.get(url)
        assert r.status_code == 200

        r = self.client.get(url)
        assert r.status_code == 200

        # Add cd_nom column
        app.config["SYNTHESE"]["LIST_COLUMNS_FRONTEND"] += [
            {
                "prop": "cd_nom",
                "name": "Cdnom",
            }
        ]
        # schema["properties"]["observations"]["items"]["required"] =
        # test on synonymy and taxref attrs
        filters = {
            "cd_ref": [taxon_attribut.bib_nom.cd_ref],
            "taxhub_attribut_{}".format(taxon_attribut.bib_attribut.id_attribut): [
                taxon_attribut.valeur_attribut
            ],
        }
        r = self.client.post(url, json=filters)
        assert r.status_code == 200
        assert len(r.json["features"]) > 0
        for feature in r.json["features"]:
            assert feature["properties"]["cd_nom"] == taxon_attribut.bib_nom.cd_nom

        # test intersection filters
        filters = {
            "geoIntersection": {
                "type": "Feature",
                "geometry": {
                    "type": "Polygon",
                    "coordinates": [
                        [
                            [5.852731, 45.7775],
                            [5.852731, 44.820481],
                            [7.029224, 44.820481],
                            [7.029224, 45.7775],
                            [5.852731, 45.7775],
                        ],
                    ],
                },
                "properties": {},
            },
        }
        r = self.client.post(url, json=filters)
        assert r.status_code == 200
        assert {synthese_data[k].id_synthese for k in ["p1_af1", "p1_af2"]}.issubset(
            {f["properties"]["id_synthese"] for f in r.json["features"]}
        )
        assert {synthese_data[k].id_synthese for k in ["p2_af1", "p2_af2"]}.isdisjoint(
            {f["properties"]["id_synthese"] for f in r.json["features"]}
        )

        # test geometry filter with circle radius
        filters = {
            "geoIntersection": {
                "type": "Feature",
                "geometry": {
                    "type": "Point",
                    "coordinates": [5.92, 45.56],
                },
                "properties": {
                    "radius": "20000",  # 20km
                },
            },
        }
        r = self.client.post(url, json=filters)
        assert r.status_code == 200
        assert {synthese_data[k].id_synthese for k in ["p1_af1", "p1_af2"]}.issubset(
            {f["properties"]["id_synthese"] for f in r.json["features"]}
        )
        assert {synthese_data[k].id_synthese for k in ["p2_af1", "p2_af2"]}.isdisjoint(
            {f["properties"]["id_synthese"] for f in r.json["features"]}
        )

        # test ref geo area filter
        com_type = db.session.execute(select(BibAreasTypes).filter_by(type_code="COM")).scalar_one()
        chambery = db.session.execute(
            select(LAreas).filter_by(area_type=com_type, area_name="Chambéry")
        ).scalar_one()
        filters = {f"area_{com_type.id_type}": [chambery.id_area]}
        r = self.client.post(url, json=filters)
        assert r.status_code == 200
        assert {synthese_data[k].id_synthese for k in ["p1_af1", "p1_af2"]}.issubset(
            {f["properties"]["id_synthese"] for f in r.json["features"]}
        )
        assert {synthese_data[k].id_synthese for k in ["p2_af1", "p2_af2"]}.isdisjoint(
            {f["properties"]["id_synthese"] for f in r.json["features"]}
        )

        # test organism
        filters = {
            "id_organism": [users["self_user"].id_organisme],
        }
        r = self.client.post(url, json=filters)
        assert r.status_code == 200
        assert len(r.json["features"]) >= 2  # FIXME

        # test status lr
        filters = {"regulations_protection_status": ["REGLLUTTE"]}
        r = self.client.get(url, json=filters)
        assert r.status_code == 200
        # test status znieff
        filters = {"znief_protection_status": True}
        r = self.client.get(url, json=filters)
        assert r.status_code == 200
        # test status protection
        filters = {"protections_protection_status": ["PN"]}
        r = self.client.get(url, json=filters)
        assert r.status_code == 200
        # test status protection and znieff
        filters = {"protections_protection_status": ["PN"], "znief_protection_status": True}
        r = self.client.get(url, json=filters)
        assert r.status_code == 200
        # test LR
        filters = {"worldwide_red_lists": ["LC"]}
        r = self.client.get(url, json=filters)
        assert r.status_code == 200
        filters = {"european_red_lists": ["LC"]}
        r = self.client.get(url, json=filters)
        assert r.status_code == 200
        filters = {"national_red_lists": ["LC"]}
        r = self.client.get(url, json=filters)
        assert r.status_code == 200
        filters = {"regional_red_lists": ["LC"]}
        r = self.client.get(url, json=filters)
        assert r.status_code == 200

    def test_get_observations_for_web_filter_comment(self, users, synthese_data, taxon_attribut):
        set_logged_user(self.client, users["self_user"])

        # Post a comment
        url = "gn_synthese.create_report"
        synthese = synthese_data["obs1"]
        id_synthese = synthese.id_synthese
        data = {"item": id_synthese, "content": "comment 4", "type": "discussion"}
        resp = self.client.post(url_for(url), data=data)
        assert resp.status_code == 204

        # Filter synthese to at least have this comment
        url = url_for("gn_synthese.get_observations_for_web")
        filters = {"has_comment": True}
        r = self.client.get(url, json=filters)

        assert id_synthese in (
            feature["properties"]["id_synthese"] for feature in r.json["features"]
        )

    def test_get_observations_for_web_filter_id_source(self, users, synthese_data, source):
        set_logged_user(self.client, users["self_user"])
        id_source = source.id_source

        url = url_for("gn_synthese.get_observations_for_web")
        filters = {"id_source": [id_source]}
        r = self.client.get(url, json=filters)

        expected_data = {
            synthese.id_synthese
            for synthese in synthese_data.values()
            if synthese.id_source == id_source
        }
        response_data = {feature["properties"]["id_synthese"] for feature in r.json["features"]}
        assert expected_data.issubset(response_data)

    @pytest.mark.parametrize(
        "module_label_to_filter,expected_length",
        [(["MODULE_TEST_1"], 2), (["MODULE_TEST_2"], 4), (["MODULE_TEST_1", "MODULE_TEST_2"], 6)],
    )
    def test_get_observations_for_web_filter_source_by_id_module(
        self,
        users,
        synthese_data,
        sources_modules,
        modules,
        module_label_to_filter,
        expected_length,
    ):
        set_logged_user(self.client, users["self_user"])

        id_modules_selected = []
        for module in modules:
            for module_to_filt in module_label_to_filter:
                if module.module_code == module_to_filt:
                    id_modules_selected.append(module.id_module)

        url = url_for("gn_synthese.get_observations_for_web")
        filters = {"id_module": id_modules_selected}
        r = self.client.get(url, json=filters)

        expected_data = {
            synthese.id_synthese
            for synthese in synthese_data.values()
            if synthese.id_module in id_modules_selected
        }
        response_data = {feature["properties"]["id_synthese"] for feature in r.json["features"]}
        assert expected_data.issubset(response_data)
        assert len(response_data) == expected_length

    @pytest.mark.parametrize(
        "observer_input,expect_observations",
        [("Vincent", True), ("Camillé", True), ("Camille,Elie", True), ("Jane Doe", False)],
    )
    def test_get_observations_for_web_filter_observers(
        self, users, synthese_for_observers, observer_input, expect_observations
    ):
        set_logged_user(self.client, users["admin_user"])

        filters = {"observers": observer_input}
        r = self.client.get(url_for("gn_synthese.get_observations_for_web"), json=filters)
        if expect_observations:
            for feature in r.json["features"]:
                assert any(
                    [
                        remove_accents(observer).lower()
                        in remove_accents(feature["properties"]["observers"]).lower()
                        for observer in observer_input.split(",")
                    ]
                ), feature["properties"]["observers"]
        else:
            assert r.json["features"] == []

    def test_get_synthese_data_cruved(self, app, users, synthese_data, datasets):
        set_logged_user(self.client, users["self_user"])

        response = self.client.get(
            url_for("gn_synthese.get_observations_for_web"), query_string={"limit": 100}
        )
        data = response.get_json()
        features = data["features"]
        assert len(features) > 0

        for feat in features:
            assert feat["properties"]["id_synthese"] in [
                synt.id_synthese for synt in synthese_data.values()
            ]
        assert response.status_code == 200

    def test_get_synthese_data_aggregate(self, users, datasets, synthese_data):
        # Test geometry aggregation
        set_logged_user(self.client, users["admin_user"])
        response = self.client.post(
            url_for("gn_synthese.get_observations_for_web"),
            query_string={
                "format": "grouped_geom",
            },
            json={
                "id_dataset": [synthese_data["p1_af1"].id_dataset],
            },
        )
        assert response.status_code == 200, response.text
        data = response.get_json()
        features = data["features"]
        # There must be one feature with one obs and one feature with two obs
        assert len(features) == 2
        assert Counter([len(f["properties"]["observations"]) for f in features]) == Counter([1, 2])

    def test_get_synthese_data_aggregate_by_areas(self, users, datasets, synthese_data):
        # Test geometry aggregation
        set_logged_user(self.client, users["admin_user"])
        response = self.client.get(
            url_for("gn_synthese.get_observations_for_web"),
            query_string={
                "format": "grouped_geom_by_areas",
            },
            json={
                "id_dataset": [synthese_data["p1_af1"].id_dataset],
            },
        )
        assert response.status_code == 200, response.text
        data = response.get_json()
        features = data["features"]
        # There must be one feature with one obs and one feature with two obs
        assert len(features) == 2
        assert Counter([len(f["properties"]["observations"]) for f in features]) == Counter([1, 2])

    def test_filter_cor_observers(self, users, synthese_data):
        """
        Test avec un cruved R2 qui join sur cor_synthese_observers
        """
        set_logged_user(self.client, users["self_user"])

        response = self.client.get(url_for("gn_synthese.get_observations_for_web"))
        data = response.get_json()

        # le résultat doit être supérieur ou égal à 2
        assert len(data["features"]) != 0
        # le requete doit etre OK marlgré la geom NULL
        assert response.status_code == 200

    @pytest.mark.parametrize(
        "group_inpn",
        [
            ("group2_inpn"),
            ("group3_inpn"),
        ],
    )
    def test_get_observations_for_web_filter_group_inpn(self, users, synthese_data, group_inpn):
        obs = synthese_data["obs1"]
        taxref_from_cd_nom = Taxref.query.filter_by(cd_nom=obs.cd_nom).one()
        group_from_taxref = getattr(taxref_from_cd_nom, group_inpn)
        filter_name = "taxonomie_" + group_inpn

        set_logged_user(self.client, users["self_user"])
        response = self.client.get(
            url_for("gn_synthese.get_observations_for_web"),
            json={
                filter_name: [group_from_taxref],
            },
        )
        response_json = response.json
        assert obs.id_synthese in {
            synthese["properties"]["id_synthese"] for synthese in response_json["features"]
        }

    def test_export(self, users):
        set_logged_user(self.client, users["self_user"])

        # csv
        response = self.client.post(
            url_for("gn_synthese.export_observations_web"),
            json=[1, 2, 3],
            query_string={"export_format": "csv"},
        )

        assert response.status_code == 200

        response = self.client.post(
            url_for("gn_synthese.export_observations_web"),
            json=[1, 2, 3],
            query_string={"export_format": "geojson"},
        )
        assert response.status_code == 200

        response = self.client.post(
            url_for("gn_synthese.export_observations_web"),
            json=[1, 2, 3],
            query_string={"export_format": "shapefile"},
        )
        assert response.status_code == 200

    def test_export_observations(self, users, synthese_data, synthese_sensitive_data, modules):
        data_synthese = synthese_data.values()
        data_synthese_sensitive = synthese_sensitive_data.values()
        list_id_synthese = [obs_data_synthese.id_synthese for obs_data_synthese in data_synthese]
        list_id_synthese.extend(
            [obs_data_synthese.id_synthese for obs_data_synthese in data_synthese_sensitive]
        )

        expected_columns_exports = [
            '"id_synthese"',
            '"date_debut"',
            '"date_fin"',
            '"heure_debut"',
            '"heure_fin"',
            '"cd_nom"',
            '"cd_ref"',
            '"nom_valide"',
            '"nom_vernaculaire"',
            '"nom_cite"',
            '"regne"',
            '"group1_inpn"',
            '"group2_inpn"',
            '"group3_inpn"',
            '"classe"',
            '"ordre"',
            '"famille"',
            '"rang_taxo"',
            '"nombre_min"',
            '"nombre_max"',
            '"alti_min"',
            '"alti_max"',
            '"prof_min"',
            '"prof_max"',
            '"observateurs"',
            '"determinateur"',
            '"communes"',
            '"geometrie_wkt_4326"',
            '"x_centroid_4326"',
            '"y_centroid_4326"',
            '"nom_lieu"',
            '"comment_releve"',
            '"comment_occurrence"',
            '"validateur"',
            '"niveau_validation"',
            '"date_validation"',
            '"comment_validation"',
            '"preuve_numerique_url"',
            '"preuve_non_numerique"',
            '"jdd_nom"',
            '"jdd_uuid"',
            '"jdd_id"',
            '"ca_nom"',
            '"ca_uuid"',
            '"ca_id"',
            '"cd_habref"',
            '"cd_habitat"',
            '"nom_habitat"',
            '"precision_geographique"',
            '"nature_objet_geo"',
            '"type_regroupement"',
            '"methode_regroupement"',
            '"technique_observation"',
            '"biologique_statut"',
            '"etat_biologique"',
            '"biogeographique_statut"',
            '"naturalite"',
            '"preuve_existante"',
            '"niveau_precision_diffusion"',
            '"stade_vie"',
            '"sexe"',
            '"objet_denombrement"',
            '"type_denombrement"',
            '"niveau_sensibilite"',
            '"statut_observation"',
            '"floutage_dee"',
            '"statut_source"',
            '"type_info_geo"',
            '"methode_determination"',
            '"comportement"',
            '"reference_biblio"',
            '"id_origine"',
            '"uuid_perm_sinp"',
            '"uuid_perm_grp_sinp"',
            '"date_creation"',
            '"date_modification"',
            '"champs_additionnels"',
        ]

        def assert_export_results(user, expected_id_synthese_list):
            set_logged_user(self.client, user)
            response = self.client.post(
                url_for("gn_synthese.export_observations_web"),
                json=list_id_synthese,
                query_string={"export_format": "csv"},
            )
            assert response.status_code == 200

            rows_data_response = response.data.decode("utf-8").split("\r\n")[0:-1]
            row_header = rows_data_response[0]
            rows_synthese_data_response = rows_data_response[1:]

            assert row_header.split(";") == expected_columns_exports

            expected_response_data_synthese = [
                obs_data_synthese
                for obs_data_synthese in data_synthese
                if obs_data_synthese.id_synthese in expected_id_synthese_list
            ]
            expected_response_data_synthese.extend(
                [
                    obs_data_synthese
                    for obs_data_synthese in data_synthese_sensitive
                    if obs_data_synthese.id_synthese in expected_id_synthese_list
                ]
            )
            nb_expected_synthese_data = len(expected_response_data_synthese)
            assert len(rows_synthese_data_response) >= nb_expected_synthese_data
            list_id_synthese_data_response = [
                row.split(";")[0] for row in rows_synthese_data_response
            ]
            assert set(
                f'"{expected_id_synthese}"' for expected_id_synthese in expected_id_synthese_list
            ).issubset(set(list_id_synthese_data_response))
            # Some checks on the data of the response : cd_nom, comment_occurrence (comment_description in synthese)
            for expected_obs_data_synthese in expected_response_data_synthese:
                id_synthese_expected_obs_data_synthese = expected_obs_data_synthese.id_synthese
                row_response_obs_data_synthese = [
                    row
                    for row in rows_synthese_data_response
                    if row.split(";")[0] == f'"{id_synthese_expected_obs_data_synthese}"'
                ][0]
                # Check cd_nom
                expected_cd_nom = expected_obs_data_synthese.cd_nom
                index_cd_nom_response = expected_columns_exports.index('"cd_nom"')
                response_cd_nom = row_response_obs_data_synthese.split(";")[index_cd_nom_response]
                assert response_cd_nom == f'"{expected_cd_nom}"'
                # Check comment_occurrence
                expected_comment_occurrence = expected_obs_data_synthese.comment_description
                index_comment_occurrence_response = expected_columns_exports.index(
                    '"comment_occurrence"'
                )
                response_comment_occurrence = row_response_obs_data_synthese.split(";")[
                    index_comment_occurrence_response
                ]
                assert response_comment_occurrence == f'"{expected_comment_occurrence}"'

        ## "self_user" : scope 1 and include sensitive data
        user = users["self_user"]
        expected_id_synthese_list = [
            synthese_data[name_obs].id_synthese
            for name_obs in [
                "obs1",
                "obs2",
                "obs3",
                "p1_af1",
                "p1_af1_2",
                "p1_af2",
                "p2_af2",
                "p2_af1",
                "p3_af3",
            ]
        ]
        expected_id_synthese_list.extend(
            [
                synthese_sensitive_data[name_obs].id_synthese
                for name_obs in [
                    "obs_sensitive",
                    "obs_not_sensitive",
                    "obs_sensitive_2",
                ]
            ]
        )
        assert_export_results(user, expected_id_synthese_list)

        ## "associate_user_2_exclude_sensitive" : scope 2 and exclude sensitive data
        user = users["associate_user_2_exclude_sensitive"]
        expected_id_synthese_list = [synthese_data[name_obs].id_synthese for name_obs in ["obs1"]]
        expected_id_synthese_list.extend(
            [synthese_sensitive_data[name_obs].id_synthese for name_obs in ["obs_not_sensitive"]]
        )
        assert_export_results(user, expected_id_synthese_list)

    def test_export_taxons(self, users, synthese_data, synthese_sensitive_data):
        data_synthese = synthese_data.values()
        data_synthese_sensitive = synthese_sensitive_data.values()
        list_id_synthese = [obs_data_synthese.id_synthese for obs_data_synthese in data_synthese]
        list_id_synthese.extend(
            [obs_data_synthese.id_synthese for obs_data_synthese in data_synthese_sensitive]
        )

        expected_columns_exports = [
            '"nom_valide"',
            '"cd_ref"',
            '"nom_vern"',
            '"group1_inpn"',
            '"group2_inpn"',
            '"group3_inpn"',
            '"regne"',
            '"phylum"',
            '"classe"',
            '"ordre"',
            '"famille"',
            '"id_rang"',
            '"nb_obs"',
            '"date_min"',
            '"date_max"',
        ]
        index_colummn_cd_ref = expected_columns_exports.index('"cd_ref"')

        def assert_export_taxons_results(user, set_expected_cd_ref):
            set_logged_user(self.client, user)

            response = self.client.post(
                url_for("gn_synthese.export_taxon_web"),
                json=list_id_synthese,
            )

            assert response.status_code == 200

            rows_data_response = response.data.decode("utf-8").split("\r\n")[0:-1]
            row_header = rows_data_response[0]
            rows_taxons_data_response = rows_data_response[1:]
            assert row_header.split(";") == expected_columns_exports

            nb_expected_cd_noms = len(set_expected_cd_ref)

            assert len(rows_taxons_data_response) >= nb_expected_cd_noms

            set_cd_ref_data_response = set(
                row.split(";")[index_colummn_cd_ref] for row in rows_taxons_data_response
            )

            assert set(f'"{expected_cd_ref}"' for expected_cd_ref in set_expected_cd_ref).issubset(
                set_cd_ref_data_response
            )

        ## "self_user" : scope 1 and include sensitive data
        user = users["self_user"]
        set_expected_cd_ref = set(
            db.session.scalars(
                select(Taxref).where(Taxref.cd_nom == synthese_data[name_obs].cd_nom)
            )
            .one()
            .cd_ref
            for name_obs in [
                "obs1",
                "obs2",
                "obs3",
                "p1_af1",
                "p1_af1_2",
                "p1_af2",
                "p2_af2",
                "p2_af1",
                "p3_af3",
            ]
        )
        set_expected_cd_ref.update(
            set(
                db.session.scalars(
                    select(Taxref).where(Taxref.cd_nom == synthese_sensitive_data[name_obs].cd_nom)
                )
                .one()
                .cd_ref
                for name_obs in [
                    "obs_sensitive",
                    "obs_not_sensitive",
                    "obs_sensitive_2",
                ]
            )
        )
        assert_export_taxons_results(user, set_expected_cd_ref)

        ## "associate_user_2_exclude_sensitive" : scope 2 and exclude sensitive data
        user = users["associate_user_2_exclude_sensitive"]
        set_expected_cd_ref = set(
            db.session.scalars(
                select(Taxref).where(Taxref.cd_nom == synthese_data[name_obs].cd_nom)
            )
            .one()
            .cd_ref
            for name_obs in ["obs1"]
        )
        set_expected_cd_ref.add(
            db.session.scalars(
                select(Taxref).where(
                    Taxref.cd_nom == synthese_sensitive_data["obs_not_sensitive"].cd_nom
                )
            )
            .one()
            .cd_ref
        )
        assert_export_taxons_results(user, set_expected_cd_ref)

    def test_export_status(self, users, synthese_sensitive_data, synthese_with_protected_status):
        expected_columns_exports = [
            '"nom_complet"',
            '"nom_vern"',
            '"cd_nom"',
            '"cd_ref"',
            '"type_regroupement"',
            '"type"',
            '"territoire_application"',
            '"intitule_doc"',
            '"code_statut"',
            '"intitule_statut"',
            '"remarque"',
            '"url_doc"',
        ]
        index_column_cd_nom = expected_columns_exports.index('"cd_nom"')

        def assert_export_status_results(user, set_expected_cd_ref):
            set_logged_user(self.client, user)

            response = self.client.post(
                url_for("gn_synthese.export_status"),
            )

            assert response.status_code == 200
            # -1 because last line is empty
            rows_data_response = response.data.decode("utf-8").split("\r\n")[0:-1]

            row_header = rows_data_response[0]
            rows_taxons_data_response = rows_data_response[1:]

            assert row_header.split(";") == expected_columns_exports

            nb_expected_cd_ref = len(set_expected_cd_ref)
            set_cd_ref_data_response = set(
                row.split(";")[index_column_cd_nom] for row in rows_taxons_data_response
            )

            nb_cd_ref_response = len(set_cd_ref_data_response)

            assert nb_cd_ref_response >= nb_expected_cd_ref

            assert set(f'"{expected_cd_ref}"' for expected_cd_ref in set_expected_cd_ref).issubset(
                set_cd_ref_data_response
            )

        user = users["user"]
        set_expected_cd_ref = set(
            db.session.scalars(
                select(Taxref.cd_ref).where(
                    Taxref.cd_nom.in_([el.cd_nom for el in synthese_with_protected_status])
                )
            ).all()
        )
        assert_export_status_results(user, set_expected_cd_ref)

        ## "self_user" : scope 1 and include sensitive data
        user = users["self_user"]
        set_expected_cd_ref = set(
            db.session.scalars(
                select(Taxref.cd_ref).where(
                    Taxref.cd_nom == synthese_sensitive_data[name_obs].cd_nom
                )
            ).one()
            for name_obs in [
                "obs_sensitive",
                "obs_not_sensitive",
                "obs_sensitive_2",
            ]
        )
        assert_export_status_results(user, set_expected_cd_ref)

        ## "associate_user_2_exclude_sensitive" : scope 2 and exclude sensitive data blurred
        user = users["associate_user_2_exclude_sensitive"]
        set_expected_cd_ref = set(
            db.session.scalars(
                select(Taxref.cd_ref).where(
                    Taxref.cd_nom == synthese_sensitive_data[name_obs].cd_nom
                )
            ).one()
            for name_obs in ["obs_not_sensitive"]
        )
        assert_export_status_results(user, set_expected_cd_ref)

    def test_export_metadata(self, users, synthese_data, synthese_sensitive_data):
        data_synthese = synthese_data.values()
        data_synthese_sensitive = synthese_sensitive_data.values()
        list_id_synthese = [obs_data_synthese.id_synthese for obs_data_synthese in data_synthese]
        list_id_synthese.extend(
            [obs_data_synthese.id_synthese for obs_data_synthese in data_synthese_sensitive]
        )

        expected_columns_exports = [
            '"jeu_donnees"',
            '"jdd_id"',
            '"jdd_uuid"',
            '"cadre_acquisition"',
            '"ca_uuid"',
            '"acteurs"',
            '"nombre_total_obs"',
        ]
        index_column_jdd_id = expected_columns_exports.index('"jdd_id"')

        # TODO: assert that some data is excluded from the response
        def assert_export_metadata_results(user, dict_expected_datasets):
            set_logged_user(self.client, user)

            response = self.client.post(
                url_for("gn_synthese.export_metadata"),
            )

            assert response.status_code == 200

            rows_data_response = response.data.decode("utf-8").split("\r\n")[0:-1]
            row_header = rows_data_response[0]
            rows_datasets_data_response = rows_data_response[1:]

            assert row_header.split(";") == expected_columns_exports

            nb_expected_datasets = len(dict_expected_datasets)
            set_id_datasets_data_response = set(
                row.split(";")[index_column_jdd_id] for row in rows_datasets_data_response
            )
            nb_datasets_response = len(set_id_datasets_data_response)

            assert nb_datasets_response >= nb_expected_datasets

            set_expected_id_datasets = set(dict_expected_datasets.keys())
            assert set(
                f'"{expected_id_dataset}"' for expected_id_dataset in set_expected_id_datasets
            ).issubset(set_id_datasets_data_response)

            for expected_id_dataset, expected_nb_obs in dict_expected_datasets.items():
                row_dataset_data_response = [
                    row
                    for row in rows_datasets_data_response
                    if row.split(";")[index_column_jdd_id] == f'"{expected_id_dataset}"'
                ][0]
                nb_obs_response = row_dataset_data_response.split(";")[-1]
                assert nb_obs_response >= f'"{expected_nb_obs}"'

        ## "self_user" : scope 1 and include sensitive data
        user = users["self_user"]
        # Create a dict (id_dataset, nb_obs) for the expected data
        dict_expected_datasets = {}
        expected_data_synthese = [
            obs_synthese
            for name_obs, obs_synthese in synthese_data.items()
            if name_obs
            in [
                "obs1",
                "obs2",
                "obs3",
                "p1_af1",
                "p1_af1_2",
                "p1_af2",
                "p2_af2",
                "p2_af1",
                "p3_af3",
            ]
        ]
        for obs_data_synthese in expected_data_synthese:
            id_dataset = obs_data_synthese.id_dataset
            if id_dataset in dict_expected_datasets:
                dict_expected_datasets[id_dataset] += 1
            else:
                dict_expected_datasets[id_dataset] = 1
        expected_data_synthese = [
            obs_synthese
            for name_obs, obs_synthese in synthese_sensitive_data.items()
            if name_obs
            in [
                "obs_sensitive",
                "obs_not_sensitive",
                "obs_sensitive_2",
            ]
        ]
        for obs_data_synthese in expected_data_synthese:
            id_dataset = obs_data_synthese.id_dataset
            if id_dataset in dict_expected_datasets:
                dict_expected_datasets[id_dataset] += 1
            else:
                dict_expected_datasets[id_dataset] = 1
        assert_export_metadata_results(user, dict_expected_datasets)

        ## "associate_user_2_exclude_sensitive" : scope 2 and exclude sensitive data
        user = users["associate_user_2_exclude_sensitive"]
        # Create a dict (id_dataset, nb_obs) for the expected data
        dict_expected_datasets = {}
        expected_data_synthese = [
            obs_synthese for name_obs, obs_synthese in synthese_data.items() if name_obs in ["obs1"]
        ]
        for obs_data_synthese in expected_data_synthese:
            id_dataset = obs_data_synthese.id_dataset
            if id_dataset in dict_expected_datasets:
                dict_expected_datasets[id_dataset] += 1
            else:
                dict_expected_datasets[id_dataset] = 1
        expected_data_synthese = [
            obs_synthese
            for name_obs, obs_synthese in synthese_sensitive_data.items()
            if name_obs
            in [
                "obs_not_sensitive",
            ]
        ]
        for obs_data_synthese in expected_data_synthese:
            id_dataset = obs_data_synthese.id_dataset
            if id_dataset in dict_expected_datasets:
                dict_expected_datasets[id_dataset] += 1
            else:
                dict_expected_datasets[id_dataset] = 1
        # TODO: s'assurer qu'on ne récupère pas le dataset "associate_2_dataset_sensitive", car ne contient que des données sensibles, bien que l'utilisateur ait le scope nécessaire par ailleurs (scope 2, et ce dataset lui est associé)
        assert_export_metadata_results(user, dict_expected_datasets)

    def test_general_stat(self, users):
        set_logged_user(self.client, users["self_user"])

        response = self.client.get(url_for("gn_synthese.general_stats"))

        assert response.status_code == 200

    def test_get_one_synthese_record(self, app, users, synthese_data):
        response = self.client.get(
            url_for("gn_synthese.get_one_synthese", id_synthese=synthese_data["obs1"].id_synthese)
        )
        assert response.status_code == 401

        set_logged_user(self.client, users["noright_user"])
        response = self.client.get(
            url_for("gn_synthese.get_one_synthese", id_synthese=synthese_data["obs1"].id_synthese)
        )
        assert response.status_code == 403

        set_logged_user(self.client, users["admin_user"])
        not_existing = (
            db.session.execute(
                select(func.max(Synthese.id_synthese)).select_from(Synthese)
            ).scalar_one()
            + 1
        )
        response = self.client.get(
            url_for("gn_synthese.get_one_synthese", id_synthese=not_existing)
        )
        assert response.status_code == 404

        set_logged_user(self.client, users["admin_user"])
        response = self.client.get(
            url_for("gn_synthese.get_one_synthese", id_synthese=synthese_data["obs1"].id_synthese)
        )
        assert response.status_code == 200

        set_logged_user(self.client, users["self_user"])
        response = self.client.get(
            url_for("gn_synthese.get_one_synthese", id_synthese=synthese_data["obs1"].id_synthese)
        )
        assert response.status_code == 200

        set_logged_user(self.client, users["user"])
        response = self.client.get(
            url_for("gn_synthese.get_one_synthese", id_synthese=synthese_data["obs1"].id_synthese)
        )
        assert response.status_code == 200

        set_logged_user(self.client, users["associate_user"])
        response = self.client.get(
            url_for("gn_synthese.get_one_synthese", id_synthese=synthese_data["obs1"].id_synthese)
        )
        assert response.status_code == 200

        set_logged_user(self.client, users["stranger_user"])
        response = self.client.get(
            url_for("gn_synthese.get_one_synthese", id_synthese=synthese_data["obs1"].id_synthese)
        )
        assert response.status_code == Forbidden.code

    def test_color_taxon(self, synthese_data, users):
        # Note: require grids 5×5!
        set_logged_user(self.client, users["self_user"])
        response = self.client.get(url_for("gn_synthese.get_color_taxon"))
        assert response.status_code == 200

        data = response.get_json()
        validate_json(
            instance=data,
            schema={
                "type": "array",
                "minItems": 1,
                "items": {
                    "type": "object",
                    "properties": {
                        "cd_nom": {
                            "type": "integer",
                        },
                        "id_area": {
                            "type": "integer",
                        },
                        "color": {
                            "type": "string",
                        },
                        "nb_obs": {
                            "type": "integer",
                        },
                        "last_date": {
                            "type": "string",
                        },
                    },
                    "minProperties": 5,
                    "additionalProperties": False,
                },
            },
        )

    def test_taxa_distribution(self, users, synthese_data):
        s = synthese_data["p1_af1"]

        response = self.client.get(url_for("gn_synthese.get_taxa_distribution"))
        assert response.status_code == Unauthorized.code

        set_logged_user(self.client, users["self_user"])
        response = self.client.get(url_for("gn_synthese.get_taxa_distribution"))
        assert response.status_code == 200
        assert len(response.json)

        response = self.client.get(
            url_for("gn_synthese.get_taxa_distribution"),
            query_string={"taxa_rank": "not existing"},
        )
        assert response.status_code == BadRequest.code

        response = self.client.get(
            url_for("gn_synthese.get_taxa_distribution"),
            query_string={"taxa_rank": "phylum"},
        )
        assert response.status_code == 200
        assert len(response.json)

        response = self.client.get(
            url_for("gn_synthese.get_taxa_distribution"),
            query_string={"id_dataset": s.id_dataset},
        )
        assert response.status_code == 200
        assert len(response.json)

        response = self.client.get(
            url_for("gn_synthese.get_taxa_distribution"),
            query_string={"id_af": s.dataset.id_acquisition_framework},
        )
        assert response.status_code == 200
        assert len(response.json)

    def test_get_taxa_count(self, synthese_data, users):
        set_logged_user(self.client, users["self_user"])

        response = self.client.get(url_for("gn_synthese.get_taxa_count"))

        assert response.json >= len(set(synt.cd_nom for synt in synthese_data.values()))

    def test_get_taxa_count_id_dataset(self, synthese_data, users, datasets, unexisted_id):
        id_dataset = datasets["own_dataset"].id_dataset
        url = "gn_synthese.get_taxa_count"
        set_logged_user(self.client, users["self_user"])

        response = self.client.get(url_for(url), query_string={"id_dataset": id_dataset})
        response_empty = self.client.get(url_for(url), query_string={"id_dataset": unexisted_id})

        assert response.json == len(set(synt.cd_nom for synt in synthese_data.values()))
        assert response_empty.json == 0

    def test_get_observation_count(self, synthese_data, users):
        nb_observations = len(synthese_data)
        set_logged_user(self.client, users["admin_user"])

        response = self.client.get(url_for("gn_synthese.get_observation_count"))

        assert response.json >= nb_observations

    def test_get_observation_count_id_dataset(self, synthese_data, users, datasets, unexisted_id):
        id_dataset = datasets["own_dataset"].id_dataset
        nb_observations = len([s for s in synthese_data.values() if s.id_dataset == id_dataset])
        url = "gn_synthese.get_observation_count"
        set_logged_user(self.client, users["self_user"])

        response = self.client.get(url_for(url), query_string={"id_dataset": id_dataset})
        response_empty = self.client.get(url_for(url), query_string={"id_dataset": unexisted_id})

        assert response.json == nb_observations
        assert response_empty.json == 0

    def test_get_bbox(self, synthese_data, users):
        set_logged_user(self.client, users["self_user"])

        response = self.client.get(url_for("gn_synthese.get_bbox"))

        assert response.status_code == 200
        assert response.json["type"] in ["Point", "Polygon"]

    def test_get_bbox_id_dataset(self, synthese_data, users, datasets, unexisted_id):
        id_dataset = datasets["own_dataset"].id_dataset
        url = "gn_synthese.get_bbox"
        set_logged_user(self.client, users["self_user"])

        response = self.client.get(url_for(url), query_string={"id_dataset": id_dataset})
        assert response.status_code == 200
        assert response.json["type"] == "Polygon"

        response_empty = self.client.get(url_for(url), query_string={"id_dataset": unexisted_id})
        assert response_empty.status_code == 204
        assert response_empty.get_data(as_text=True) == ""

    def test_get_bbox_id_source(self, synthese_data, users, source):
        id_source = source.id_source
        url = "gn_synthese.get_bbox"
        set_logged_user(self.client, users["self_user"])

        response = self.client.get(url_for(url), query_string={"id_source": id_source})

        assert response.status_code == 200
        assert response.json["type"] == "Polygon"

    def test_get_bbox_id_source_empty(self, users, unexisted_id_source):
        url = "gn_synthese.get_bbox"
        set_logged_user(self.client, users["self_user"])

        response = self.client.get(url_for(url), query_string={"id_source": unexisted_id_source})

        assert response.status_code == 204
        assert response.json is None

    def test_observation_count_per_column(self, users, synthese_data):
        column_name_dataset = "id_dataset"
        column_name_cd_nom = "cd_nom"
        set_logged_user(self.client, users["self_user"])

        response_dataset = self.client.get(
            url_for("gn_synthese.observation_count_per_column", column=column_name_dataset)
        )
        response_cd_nom = self.client.get(
            url_for("gn_synthese.observation_count_per_column", column=column_name_cd_nom)
        )

        ds_keyfunc = lambda s: s.id_dataset
        partial_expected_ds_resp = [
            {
                "id_dataset": k,
                "count": len(list(g)),
            }
            for k, g in itertools.groupby(
                sorted(synthese_data.values(), key=ds_keyfunc), key=ds_keyfunc
            )
        ]

        cn_keyfunc = lambda s: s.cd_nom
        partial_expected_cn_resp = [
            {
                "cd_nom": k,
                "count": len(list(g)),
            }
            for k, g in itertools.groupby(
                sorted(synthese_data.values(), key=cn_keyfunc), key=cn_keyfunc
            )
        ]

        resp_json = response_dataset.json
        assert resp_json
        for test_dataset in partial_expected_ds_resp:
            assert test_dataset["id_dataset"] in [item["id_dataset"] for item in resp_json]
            for item in resp_json:
                if item["id_dataset"] == test_dataset["id_dataset"]:
                    assert item["count"] == test_dataset["count"]

        resp_json = response_cd_nom.json
        assert resp_json
        for test_cd_nom in partial_expected_cn_resp:
            assert test_cd_nom["cd_nom"] in [item["cd_nom"] for item in resp_json]
            for item in resp_json:
                if item["cd_nom"] == test_cd_nom["cd_nom"]:
                    assert item["count"] >= test_cd_nom["count"]

    def test_get_autocomplete_taxons_synthese(self, synthese_data, users):
        seach_name = synthese_data["obs1"].nom_cite

        set_logged_user(self.client, users["self_user"])

        response = self.client.get(
            url_for("gn_synthese.get_autocomplete_taxons_synthese"),
            query_string={"search_name": seach_name},
        )

        assert response.status_code == 200
        assert response.json[0]["cd_nom"] == synthese_data["obs1"].cd_nom


@pytest.fixture(scope="class")
def synthese_module():
    return TModules.query.filter_by(module_code="SYNTHESE").one()


@pytest.fixture()
def synthese_read_permissions(synthese_module):
    def _synthese_read_permissions(role, scope_value, action="R", **kwargs):
        action = PermAction.query.filter_by(code_action=action).one()
        perm = Permission(
            role=role,
            action=action,
            module=synthese_module,
            scope_value=scope_value,
            **kwargs,
        )
        with db.session.begin_nested():
            db.session.add(perm)
        return perm

    return _synthese_read_permissions


@pytest.fixture()
def synthese_export_permissions(synthese_module):
    def _synthese_export_permissions(role, scope_value, action="E", **kwargs):
        action = PermAction.query.filter_by(code_action=action).one()
        perm = Permission(
            role=role,
            action=action,
            module=synthese_module,
            scope_value=scope_value,
            **kwargs,
        )
        with db.session.begin_nested():
            db.session.add(perm)
        return perm

    return _synthese_export_permissions


@pytest.fixture()
def exclude_sensitive_observations(monkeypatch):
    monkeypatch.setitem(current_app.config["SYNTHESE"], "BLUR_SENSITIVE_OBSERVATIONS", False)


@pytest.fixture()
def blur_sensitive_observations(monkeypatch):
    monkeypatch.setitem(current_app.config["SYNTHESE"], "BLUR_SENSITIVE_OBSERVATIONS", True)


def get_one_synthese_reponse_from_id(response: dict, id_synthese: int):
    return [
        synthese
        for synthese in response["features"]
        if synthese["properties"]["id_synthese"] == id_synthese
    ][0]


def assert_precise_synthese(geojson, obs):
    synthese = SyntheseSchema(
        as_geojson=True, only=["id_synthese"], instance=Synthese(), unknown=EXCLUDE
    ).load(geojson)

    assert_geometries_equal(
        to_shape(synthese.the_geom_4326), to_shape(obs.the_geom_4326), tolerance=1e-5
    )


def assert_blurred_synthese(geojson, obs):
    synthese = SyntheseSchema(
        as_geojson=True, only=["id_synthese"], instance=Synthese(), unknown=EXCLUDE
    ).load(geojson)

    sensitive_area = db.session.execute(
        sa.select(LAreas)
        .join(LAreas.synthese_obs)
        .join(LAreas.area_type)
        .join(
            cor_sensitivity_area_type,
            sa.and_(
                cor_sensitivity_area_type.c.id_area_type == BibAreasTypes.id_type,
                cor_sensitivity_area_type.c.id_nomenclature_sensitivity
                == Synthese.id_nomenclature_sensitivity,
            ),
        )
        .where(Synthese.id_synthese == obs.id_synthese)
    ).scalar_one()

    assert_geometries_equal(
        to_shape(synthese.the_geom_4326), to_shape(sensitive_area.geom_4326), tolerance=1e-5
    )


@pytest.mark.usefixtures("client_class", "temporary_transaction")
class TestSyntheseBlurring:
    def test_split_blurring_precise_permissions(
        self, app, users, synthese_module, synthese_read_permissions
    ):
        current_user = users["self_user"]

        blurring_perm = synthese_read_permissions(current_user, None, sensitivity_filter=True)
        precise_perm = synthese_read_permissions(current_user, 2, sensitivity_filter=False)

        with app.test_request_context(headers=logged_user_headers(current_user)):
            app.preprocess_request()
            permissions = get_permissions(
                action_code="R",
                id_role=current_user.id_role,
                module_code=synthese_module.module_code,
                object_code="ALL",
            )
        blurring_perms, precise_perms = split_blurring_precise_permissions(permissions)

        assert all(s.sensitivity_filter for s in blurring_perms)
        assert all(not s.sensitivity_filter for s in precise_perms)
        assert blurring_perm in blurring_perms
        assert precise_perm in precise_perms

    def test_get_observations_for_web_blurring(
        self,
        users,
        synthese_sensitive_data,
        source,
        synthese_read_permissions,
        blur_sensitive_observations,
    ):
        current_user = users["stranger_user"]
        # None is 3
        synthese_read_permissions(current_user, None, sensitivity_filter=True)
        synthese_read_permissions(current_user, 1, sensitivity_filter=False)

        set_logged_user(self.client, current_user)
        url = url_for("gn_synthese.get_observations_for_web")

        response_json = self.client.post(url, json={"id_source": [source.id_source]}).json

        # Check unsensitive synthese obs geometry
        unsensitive_synthese = synthese_sensitive_data["obs_not_sensitive"]
        unsensitive_synthese_from_response = get_one_synthese_reponse_from_id(
            response_json, unsensitive_synthese.id_synthese
        )

        # Need to pass through a Feature because rounding of coordinates is done
        assert_precise_synthese(
            geojson=unsensitive_synthese_from_response, obs=unsensitive_synthese
        )

        # Check sensitive synthese obs geometry
        sensitive_synthese = synthese_sensitive_data["obs_sensitive"]
        sensitive_synthese_from_response = get_one_synthese_reponse_from_id(
            response_json, sensitive_synthese.id_synthese
        )

        assert_blurred_synthese(geojson=sensitive_synthese_from_response, obs=sensitive_synthese)

    def test_get_observations_for_web_blurring_excluded(
        self,
        users,
        synthese_sensitive_data,
        source,
        synthese_read_permissions,
        exclude_sensitive_observations,
    ):
        current_user = users["stranger_user"]
        # None is 3
        synthese_read_permissions(current_user, None, sensitivity_filter=True)
        synthese_read_permissions(current_user, 1, sensitivity_filter=False)

        set_logged_user(self.client, current_user)

        url = url_for("gn_synthese.get_observations_for_web")

        response_json = self.client.post(url, json={"id_source": [source.id_source]}).json

        sensitive_synthese_ids = (
            synthese.id_synthese
            for synthese in [
                synthese_sensitive_data["obs_sensitive"],
                synthese_sensitive_data["obs_sensitive_2"],
            ]
        )

        json_synthese_ids = (
            feature["properties"]["id_synthese"] for feature in response_json["features"]
        )
        assert all(synthese_id not in json_synthese_ids for synthese_id in sensitive_synthese_ids)

    def test_get_observations_for_web_blurring_grouped_geom(
        self,
        users,
        synthese_sensitive_data,
        source,
        synthese_read_permissions,
        monkeypatch,
    ):
        # So that all burred geoms will not appear on the aggregated areas
        monkeypatch.setitem(current_app.config["SYNTHESE"], "AREA_AGGREGATION_TYPE", "M1")

        current_user = users["stranger_user"]
        set_logged_user(self.client, current_user)
        # None is 3
        synthese_read_permissions(current_user, None, sensitivity_filter=True)
        synthese_read_permissions(current_user, 1, sensitivity_filter=False)

        response = self.client.get(
            url_for("gn_synthese.get_observations_for_web"),
            query_string={
                "format": "grouped_geom_by_areas",
            },
            json={
                "id_source": [source.id_source],
            },
        )

        json_resp = response.json

        # Retrieve only sensitive synthese ids
        sensitive_synthese_ids = [
            synthese.id_synthese
            for synthese in (
                synthese_sensitive_data["obs_sensitive"],
                synthese_sensitive_data["obs_sensitive_2"],
            )
        ]

        # If an observation is blurred and the AREA_AGGREGATION_TYPE is smaller in
        # size than the blurred observation then the observation should not appear
        assert all(
            feature["geometry"] is None
            for feature in json_resp["features"]
            if all(
                observation["id_synthese"] in sensitive_synthese_ids
                for observation in feature["properties"]["observations"]
            )
        )

    def test_get_one_synthese_sensitive(
        self,
        users,
        synthese_sensitive_data,
        synthese_read_permissions,
        blur_sensitive_observations,  # So that all burred geoms will not appear on the aggregated areas
    ):
        current_user = users["stranger_user"]
        sensitive_synthese = synthese_sensitive_data["obs_sensitive"]
        # None is 3
        synthese_read_permissions(current_user, None, sensitivity_filter=True)
        synthese_read_permissions(current_user, 1, sensitivity_filter=False)

        set_logged_user(self.client, current_user)
        url = url_for("gn_synthese.get_one_synthese", id_synthese=sensitive_synthese.id_synthese)

        response_json = self.client.get(url).json

        sensitive_synthese = synthese_sensitive_data["obs_sensitive"]

        assert_blurred_synthese(geojson=response_json, obs=sensitive_synthese)

    def test_get_one_synthese_unsensitive(
        self, users, synthese_sensitive_data, synthese_read_permissions
    ):
        current_user = users["stranger_user"]
        unsensitive_synthese = synthese_sensitive_data["obs_not_sensitive"]
        # None is 3
        synthese_read_permissions(current_user, None, sensitivity_filter=True)
        synthese_read_permissions(current_user, 1, sensitivity_filter=False)

        set_logged_user(self.client, current_user)
        url = url_for("gn_synthese.get_one_synthese", id_synthese=unsensitive_synthese.id_synthese)

        response_json = self.client.get(url).json

        assert_precise_synthese(geojson=response_json, obs=unsensitive_synthese)

    def test_get_one_synthese_sensitive_excluded(
        self,
        users,
        synthese_sensitive_data,
        synthese_read_permissions,
        exclude_sensitive_observations,
    ):
        current_user = users["stranger_user"]
        sensitive_synthese = synthese_sensitive_data["obs_sensitive"]
        # None is 3
        synthese_read_permissions(current_user, None, sensitivity_filter=True)
        synthese_read_permissions(current_user, 1, sensitivity_filter=False)

        set_logged_user(self.client, current_user)
        url = url_for("gn_synthese.get_one_synthese", id_synthese=sensitive_synthese.id_synthese)

        response = self.client.get(url)

        assert response.status_code == Forbidden.code

    def test_export_observations_unsensitive(
        self, users, synthese_export_permissions, synthese_sensitive_data
    ):
        current_user = users["stranger_user"]
        # None is 3
        synthese_export_permissions(current_user, None, sensitivity_filter=True)
        synthese_export_permissions(current_user, 1, sensitivity_filter=False)

        set_logged_user(self.client, current_user)

        list_id_synthese = [synthese.id_synthese for synthese in synthese_sensitive_data.values()]

        response = self.client.post(
            url_for("gn_synthese.export_observations_web"),
            json=list_id_synthese,
            query_string={"export_format": "csv"},
        )

        assert response.status_code == 200
        file_like_obj = StringIO(response.data.decode("utf-8"))
        reader = csv.DictReader(file_like_obj, delimiter=";")
        for row in reader:
            if int(row["id_synthese"]) == synthese_sensitive_data["obs_not_sensitive"].id_synthese:
                unsensitive_response_synthese = row

        # Unsensitive
        geom_shape = to_shape(synthese_sensitive_data["obs_not_sensitive"].the_geom_4326)
        assert float(unsensitive_response_synthese["x_centroid_4326"]) == pytest.approx(
            geom_shape.x, 0.000001
        )
        assert float(unsensitive_response_synthese["y_centroid_4326"]) == pytest.approx(
            geom_shape.y, 0.000001
        )

    def test_export_observations_sensitive(
        self,
        users,
        synthese_export_permissions,
        synthese_sensitive_data,
        blur_sensitive_observations,  # So that all burred geoms will not appear on the aggregated areas
    ):
        current_user = users["stranger_user"]
        # None is 3
        synthese_export_permissions(current_user, None, sensitivity_filter=True)
        synthese_export_permissions(current_user, 1, sensitivity_filter=False)

        set_logged_user(self.client, current_user)

        list_id_synthese = [synthese.id_synthese for synthese in synthese_sensitive_data.values()]

        response = self.client.post(
            url_for("gn_synthese.export_observations_web"),
            json=list_id_synthese,
            query_string={"export_format": "geojson"},
        )

        assert response.status_code == 200
        sensitive_synthese = synthese_sensitive_data["obs_sensitive"]
        json_feature_synthese = [
            feature
            for feature in response.json["features"]
            if feature["properties"]["id_synthese"] == sensitive_synthese.id_synthese
        ][0]
        assert_blurred_synthese(geojson=json_feature_synthese, obs=sensitive_synthese)

    def test_export_observations_sensitive_excluded(
        self,
        users,
        synthese_export_permissions,
        synthese_sensitive_data,
        exclude_sensitive_observations,
    ):
        current_user = users["stranger_user"]
        # None is 3
        synthese_export_permissions(current_user, None, sensitivity_filter=True)
        synthese_export_permissions(current_user, 1, sensitivity_filter=False)

        set_logged_user(self.client, current_user)

        list_id_synthese = [
            synthese.id_synthese
            for synthese in [
                synthese_sensitive_data["obs_sensitive"],
                synthese_sensitive_data["obs_sensitive_2"],
            ]
        ]

        response = self.client.post(
            url_for("gn_synthese.export_observations_web"),
            json=list_id_synthese,
            query_string={"export_format": "geojson"},
        )

        assert response.status_code == 200
        # No feature accessible because sensitive data excluded if
        # the user has no right to see it
        assert len(response.json["features"]) == 0
