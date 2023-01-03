import pytest
import json
import itertools

from flask import url_for, current_app
from sqlalchemy import func
from werkzeug.exceptions import Forbidden, BadRequest, Unauthorized
from jsonschema import validate as validate_json
from geoalchemy2.shape import to_shape
from geojson import Point

from geonature.utils.env import db
from geonature.core.gn_meta.models import TDatasets
from geonature.core.gn_synthese.models import Synthese, TSources

from pypnusershub.tests.utils import logged_user_headers, set_logged_user_cookie
from ref_geo.models import BibAreasTypes, LAreas
from apptax.tests.fixtures import noms_example, attribut_example

from .fixtures import *
from .utils import jsonschema_definitions


@pytest.fixture()
def unexisted_id():
    return db.session.query(func.max(TDatasets.id_dataset)).scalar() + 1


@pytest.fixture()
def source():
    source = TSources(name_source="test source")
    with db.session.begin_nested():
        db.session.add(source)
    return source


@pytest.fixture()
def unexisted_id_source():
    return db.session.query(func.max(TSources.id_source)).scalar() + 1


@pytest.fixture()
def bbox_geom(synthese_data):
    """used to check bbox"""
    return Point(geometry=to_shape(synthese_data[0].the_geom_4326))


@pytest.fixture()
def taxon_attribut(noms_example, attribut_example, synthese_data):
    """
    Require "taxonomie_taxons_example" and "taxonomie_attributes_example" alembic branches.
    """
    from apptax.taxonomie.models import BibAttributs, BibNoms, CorTaxonAttribut

    nom = BibNoms.query.filter_by(cd_ref=209902).one()
    attribut = BibAttributs.query.filter_by(nom_attribut=attribut_example.nom_attribut).one()
    with db.session.begin_nested():
        c = CorTaxonAttribut(bib_nom=nom, bib_attribut=attribut, valeur_attribut="eau")
        db.session.add(c)
    return c


synthese_properties = {
    "type": "object",
    "properties": {
        "id": {"type": "number"},
        "cd_nom": {"type": "number"},
        "count_min_max": {"type": "string"},
        "dataset_name": {"type": "string"},
        "date_min": {"type": "string"},
        "entity_source_pk_value": {
            "oneOf": [
                {"type": "null"},
                {"type": "string"},
            ],
        },
        "lb_nom": {"type": "string"},
        "nom_vern_or_lb_nom": {"type": "string"},
        "unique_id_sinp": {
            "type": "string",
            "pattern": "^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$",
        },
        "observers": {
            "oneOf": [
                {"type": "null"},
                {"type": "string"},
            ],
        },
        "url_source": {
            "oneOf": [
                {"type": "null"},
                {"type": "string"},
            ],
        },
    },
    "required": [  # obligatoire pour le fonctionement du front
        "id",
        "cd_nom",
        "url_source",
        "entity_source_pk_value",
    ],
    "additionalProperties": False,
}


@pytest.mark.usefixtures("client_class", "temporary_transaction")
class TestSynthese:
    def test_synthese_scope_filtering(self, app, users, synthese_data):
        all_ids = {s.id_synthese for s in synthese_data}
        sq = Synthese.query.with_entities(Synthese.id_synthese).filter(
            Synthese.id_synthese.in_(all_ids)
        )
        with app.test_request_context(headers=logged_user_headers(users["user"])):
            app.preprocess_request()
            assert sq.filter_by_scope(0).all() == []

    def test_list_sources(self, source):
        response = self.client.get(url_for("gn_synthese.get_sources"))
        assert response.status_code == 200
        data = response.get_json()
        assert len(data) > 0

    def test_get_defaut_nomenclatures(self):
        response = self.client.get(url_for("gn_synthese.getDefaultsNomenclatures"))
        assert response.status_code == 200

    def test_get_observations_for_web(self, users, synthese_data, taxon_attribut):
        url = url_for("gn_synthese.get_observations_for_web")
        schema = {
            "definitions": jsonschema_definitions,
            "$ref": "#/definitions/featurecollection",
            "$defs": {"props": synthese_properties},
        }

        r = self.client.get(url)
        assert r.status_code == Unauthorized.code

        set_logged_user_cookie(self.client, users["self_user"])

        r = self.client.get(url)
        assert r.status_code == 200
        validate_json(instance=r.json, schema=schema)

        # test on synonymy and taxref attrs
        query_string = {
            "cd_ref": taxon_attribut.bib_nom.cd_ref,
            "taxhub_attribut_{}".format(
                taxon_attribut.bib_attribut.id_attribut
            ): taxon_attribut.valeur_attribut,
        }
        r = self.client.get(url, query_string=query_string)
        assert r.status_code == 200
        validate_json(instance=r.json, schema=schema)
        assert len(r.json["features"]) == 1
        assert r.json["features"][0]["properties"]["cd_nom"] == taxon_attribut.bib_nom.cd_nom

        # test geometry filters
        com_type = BibAreasTypes.query.filter_by(type_code="COM").one()
        vesdun = LAreas.query.filter_by(area_type=com_type, area_name="Vesdun").one()
        query_string = {
            "geoIntersection": """
            POLYGON((2.313844516928274 46.62891246017805,2.654420688803274 46.62891246017805,2.654420688803274 46.415359531851166,2.313844516928274 46.415359531851166,2.313844516928274 46.62891246017805))
            """,
            f"area_{com_type.id_type}": vesdun.id_area,
        }
        r = self.client.get(url, query_string=query_string)
        assert r.status_code == 200
        validate_json(instance=r.json, schema=schema)
        assert len(r.json["features"]) >= 2

        # test geometry filter with circle radius
        query_string = {
            "geoIntersection": "POINT ({} {})".format(
                current_app.config["MAPCONFIG"]["CENTER"][1] + 0.01,
                current_app.config["MAPCONFIG"]["CENTER"][0] - 0.10,
            ),
            "radius": "20000",  # 20km
        }
        r = self.client.get(url, query_string=query_string)
        assert r.status_code == 200
        validate_json(instance=r.json, schema=schema)
        assert len(r.json["features"]) >= 2

        # test organisms and multiple same arg in query string
        id_organisme = users["self_user"].id_organisme
        r = self.client.get(f"{url}?id_organism={id_organisme}&id_organism=2")
        assert r.status_code == 200
        validate_json(instance=r.json, schema=schema)
        assert len(r.json["features"]) >= 2

        # test status lr
        query_string = {"regulations_protection_status": ["REGLLUTTE"]}
        r = self.client.get(url, query_string=query_string)
        assert r.status_code == 200
        # test status znieff
        query_string = {"znief_protection_status": True}
        r = self.client.get(url, query_string=query_string)
        assert r.status_code == 200
        # test status protection
        query_string = {"protections_protection_status": ["PN"]}
        r = self.client.get(url, query_string=query_string)
        assert r.status_code == 200
        # test LR
        query_string = {"worldwide_red_lists": ["LC"]}
        r = self.client.get(url, query_string=query_string)
        assert r.status_code == 200
        query_string = {"european_red_lists": ["LC"]}
        r = self.client.get(url, query_string=query_string)
        assert r.status_code == 200
        query_string = {"national_red_lists": ["LC"]}
        r = self.client.get(url, query_string=query_string)
        assert r.status_code == 200
        query_string = {"regional_red_lists": ["LC"]}
        r = self.client.get(url, query_string=query_string)
        assert r.status_code == 200

    def test_get_synthese_data_cruved(self, app, users, synthese_data, datasets):
        set_logged_user_cookie(self.client, users["self_user"])

        response = self.client.get(
            url_for("gn_synthese.get_observations_for_web"), query_string={"limit": 100}
        )
        data = response.get_json()

        features = data["features"]
        assert len(features) > 0
        assert all(
            feat["properties"]["lb_nom"] in [synt.nom_cite for synt in synthese_data]
            for feat in features
        )
        assert response.status_code == 200

    def test_filter_cor_observers(self, users, synthese_data):
        """
        Test avec un cruved R2 qui join sur cor_synthese_observers
        """
        set_logged_user_cookie(self.client, users["self_user"])

        response = self.client.get(url_for("gn_synthese.get_observations_for_web"))
        data = response.get_json()

        # le résultat doit être supérieur ou égal à 2
        assert len(data["features"]) != 0
        # le requete doit etre OK marlgré la geom NULL
        assert response.status_code == 200

    def test_export(self, users):
        set_logged_user_cookie(self.client, users["self_user"])

        # csv
        response = self.client.post(
            url_for("gn_synthese.export_observations_web"),
            data=[1, 2, 3],
            query_string={"export_format": "csv"},
        )

        assert response.status_code == 200

        response = self.client.post(
            url_for("gn_synthese.export_observations_web"),
            data=[1, 2, 3],
            query_string={"export_format": "geojson"},
        )
        assert response.status_code == 200

        response = self.client.post(
            url_for("gn_synthese.export_observations_web"),
            data=[1, 2, 3],
            query_string={"export_format": "shapefile"},
        )
        assert response.status_code == 200

    def test_export_status(self, users):
        set_logged_user_cookie(self.client, users["self_user"])

        response = self.client.post(url_for("gn_synthese.export_status"))

        assert response.status_code == 200

    def test_export_metadata(self, users):
        set_logged_user_cookie(self.client, users["self_user"])

        response = self.client.get(url_for("gn_synthese.export_metadata"))

        assert response.status_code == 200

    def test_general_stat(self, users):
        set_logged_user_cookie(self.client, users["self_user"])

        response = self.client.get(url_for("gn_synthese.general_stats"))

        assert response.status_code == 200

    def test_get_one_synthese_record(self, app, users, synthese_data):
        response = self.client.get(
            url_for("gn_synthese.get_one_synthese", id_synthese=synthese_data[0].id_synthese)
        )
        assert response.status_code == 401

        set_logged_user_cookie(self.client, users["noright_user"])
        response = self.client.get(
            url_for("gn_synthese.get_one_synthese", id_synthese=synthese_data[0].id_synthese)
        )
        assert response.status_code == 403

        set_logged_user_cookie(self.client, users["admin_user"])
        not_existing = db.session.query(func.max(Synthese.id_synthese)).scalar() + 1
        response = self.client.get(
            url_for("gn_synthese.get_one_synthese", id_synthese=not_existing)
        )
        assert response.status_code == 404

        set_logged_user_cookie(self.client, users["admin_user"])
        response = self.client.get(
            url_for("gn_synthese.get_one_synthese", id_synthese=synthese_data[0].id_synthese)
        )
        assert response.status_code == 200

        set_logged_user_cookie(self.client, users["self_user"])
        response = self.client.get(
            url_for("gn_synthese.get_one_synthese", id_synthese=synthese_data[0].id_synthese)
        )
        assert response.status_code == 200

        set_logged_user_cookie(self.client, users["user"])
        response = self.client.get(
            url_for("gn_synthese.get_one_synthese", id_synthese=synthese_data[0].id_synthese)
        )
        assert response.status_code == 200

        set_logged_user_cookie(self.client, users["associate_user"])
        response = self.client.get(
            url_for("gn_synthese.get_one_synthese", id_synthese=synthese_data[0].id_synthese)
        )
        assert response.status_code == 200

        set_logged_user_cookie(self.client, users["stranger_user"])
        response = self.client.get(
            url_for("gn_synthese.get_one_synthese", id_synthese=synthese_data[0].id_synthese)
        )
        assert response.status_code == Forbidden.code

    def test_color_taxon(self, synthese_data):
        # Note: require grids 5×5!
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

    def test_taxa_distribution(self, synthese_data):
        s = synthese_data[0]

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

    def test_get_taxa_count(self, synthese_data):
        response = self.client.get(url_for("gn_synthese.get_taxa_count"))

        assert response.json >= len(set(synt.cd_nom for synt in synthese_data))

    def test_get_taxa_count_id_dataset(self, synthese_data, datasets, unexisted_id):
        id_dataset = datasets["own_dataset"].id_dataset
        url = "gn_synthese.get_taxa_count"

        response = self.client.get(url_for(url), query_string={"id_dataset": id_dataset})
        response_empty = self.client.get(url_for(url), query_string={"id_dataset": unexisted_id})

        assert response.json == len(set(synt.cd_nom for synt in synthese_data))
        assert response_empty.json == 0

    def test_get_observation_count(self, synthese_data):
        nb_observations = len(synthese_data)

        response = self.client.get(url_for("gn_synthese.get_observation_count"))

        assert response.json >= nb_observations

    def test_get_observation_count_id_dataset(self, synthese_data, datasets, unexisted_id):
        id_dataset = datasets["own_dataset"].id_dataset
        nb_observations = len(synthese_data)
        url = "gn_synthese.get_observation_count"

        response = self.client.get(url_for(url), query_string={"id_dataset": id_dataset})
        response_empty = self.client.get(url_for(url), query_string={"id_dataset": unexisted_id})

        assert response.json == nb_observations
        assert response_empty.json == 0

    def test_get_bbox(self, synthese_data):
        # In synthese, all entries are located at the same point
        geom = Point(geometry=to_shape(synthese_data[0].the_geom_4326))

        response = self.client.get(url_for("gn_synthese.get_bbox"))

        assert response.status_code == 200
        assert response.json["type"] in ["Point", "Polygon"]

    def test_get_bbox_id_dataset(self, synthese_data, datasets, unexisted_id):
        id_dataset = datasets["own_dataset"].id_dataset
        # In synthese, all entries are located at the same point
        geom = Point(geometry=to_shape(synthese_data[0].the_geom_4326))
        url = "gn_synthese.get_bbox"

        response = self.client.get(url_for(url), query_string={"id_dataset": id_dataset})
        assert response.status_code == 200
        assert response.json["type"] == "Point"
        assert response.json["coordinates"] == [
            pytest.approx(coord, 0.9) for coord in [geom.geometry.x, geom.geometry.y]
        ]

        response_empty = self.client.get(url_for(url), query_string={"id_dataset": unexisted_id})
        assert response_empty.status_code == 204
        assert response_empty.get_data(as_text=True) == ""

    def test_get_bbox_id_source(self, bbox_geom, source):
        id_source = source.id_source
        url = "gn_synthese.get_bbox"

        response = self.client.get(url_for(url), query_string={"id_source": id_source})

        assert response.status_code == 200
        assert response.json["type"] == "Point"
        assert response.json["coordinates"] == [
            pytest.approx(coord, 0.9) for coord in [bbox_geom.geometry.x, bbox_geom.geometry.y]
        ]

    def test_get_bbox_id_source_empty(self, unexisted_id_source):
        url = "gn_synthese.get_bbox"

        response = self.client.get(url_for(url), query_string={"id_source": unexisted_id_source})

        assert response.status_code == 204
        assert response.json is None

    def test_observation_count_per_column(self, synthese_data):
        column_name_dataset = "id_dataset"
        column_name_cd_nom = "cd_nom"

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
            for k, g in itertools.groupby(sorted(synthese_data, key=ds_keyfunc), key=ds_keyfunc)
        ]

        cn_keyfunc = lambda s: s.cd_nom
        partial_expected_cn_resp = [
            {
                "cd_nom": k,
                "count": len(list(g)),
            }
            for k, g in itertools.groupby(sorted(synthese_data, key=cn_keyfunc), key=cn_keyfunc)
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

    def test_get_autocomplete_taxons_synthese(self, synthese_data):
        seach_name = synthese_data[0].nom_cite

        response = self.client.get(
            url_for("gn_synthese.get_autocomplete_taxons_synthese"),
            query_string={"search_name": seach_name},
        )

        assert response.status_code == 200
        assert response.json[0]["cd_nom"] == synthese_data[0].cd_nom
