import pytest
import json

from flask import url_for, current_app
from sqlalchemy import func
from werkzeug.exceptions import Forbidden, BadRequest
from jsonschema import validate as validate_json
from geoalchemy2.shape import to_shape
from geojson import Point

from geonature.utils.env import db
from geonature.core.gn_meta.models import TDatasets
from geonature.core.gn_synthese.models import Synthese, TSources

from .fixtures import *
from .utils import logged_user_headers, set_logged_user_cookie


@pytest.fixture()
def unexisted_id():
    return db.session.query(func.max(TDatasets.id_dataset)).scalar() + 1


@pytest.fixture()
def source():
    source = TSources(name_source="test source")
    with db.session.begin_nested():
        db.session.add(source)
    return source


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

    @pytest.mark.skip()  # FIXME
    def test_get_synthese_data(self, users, taxon_attribut):
        set_logged_user_cookie(self.client, users["self_user"])

        # test on synonymy and taxref attrs
        s = synthese_data[0]
        query_string = {
            "cd_ref": taxon_attribut.bib_nom.cd_ref,
            "taxhub_attribut_{}".format(
                taxon_attribut.bib_attribut.id_attribut
            ): taxon_attribut.valeur_attribut,
            "taxonomy_group2_inpn": "Insectes",
            "taxonomy_id_hab": s.habitat.cd_hab,
        }
        response = self.client.get(
            url_for("gn_synthese.get_observations_for_web"), query_string=query_string
        )
        assert response.status_code == 200
        data = response.get_json()
        assert len(data["data"]["features"]) == 1
        # clés obligatoire pour le fonctionnement du front
        assert "cd_nom" in data["data"]["features"][0]["properties"]
        assert "id" in data["data"]["features"][0]["properties"]
        assert "url_source" in data["data"]["features"][0]["properties"]
        assert "entity_source_pk_value" in data["data"]["features"][0]["properties"]
        assert data["data"]["features"][0]["properties"]["cd_nom"] == s.cd_nom

        # test geometry filters
        key_municipality = "area_" + str(current_app.config["BDD"]["id_area_type_municipality"])
        query_string = {
            "geoIntersection": """
                POLYGON ((5.580368041992188 43.42100882994726, 5.580368041992188 45.30580259943578, 8.12919616699219 45.30580259943578, 8.12919616699219 43.42100882994726, 5.580368041992188 43.42100882994726))
                """,
            key_municipality: 28290,
        }
        response = self.client.get(
            url_for("gn_synthese.get_observations_for_web"), query_string=query_string
        )
        data = response.get_json()
        assert len(data["data"]) >= 2

        # test geometry filter with circle radius
        query_string = {
            "geoIntersection": "POINT (6.121788024902345 45.06794388950998)",
            "radius": "83883.94104436478",
        }

        response = self.client.get(
            url_for("gn_synthese.get_observations_for_web"), query_string=query_string
        )
        data = response.get_json()
        assert len(data["data"]) >= 2

        # test organisms and multiple same arg in query string

        response = self.client.get("/synthese/for_web?id_organism=1&id_organism=2")
        data = response.get_json()
        assert len(data["data"]) >= 2

    def test_get_synthese_data_cruved(self, app, users, synthese_data, datasets):
        set_logged_user_cookie(self.client, users["self_user"])

        response = self.client.get(
            url_for("gn_synthese.get_observations_for_web"), query_string={"limit": 100}
        )
        data = response.get_json()

        features = data["data"]["features"]
        assert len(data["data"]["features"]) > 0
        lb_noms = [lb_nom for lb_nom in features[0]["properties"]["lb_nom"]]
        assert all(lb_nom in [synt.nom_cite for synt in synthese_data] for lb_nom in lb_noms)
        assert response.status_code == 200

    def test_filter_cor_observers(self, users, synthese_data):
        """
        Test avec un cruved R2 qui join sur cor_synthese_observers
        """
        set_logged_user_cookie(self.client, users["self_user"])

        response = self.client.get(url_for("gn_synthese.get_observations_for_web"))
        data = response.get_json()

        # le résultat doit être supérieur ou égal à 2
        assert len(data["data"]["features"]) != 0
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

    def test_observation_count_per_column(self, synthese_data):
        column_name_dataset = "id_dataset"
        column_name_cd_nom = "cd_nom"

        response_dataset = self.client.get(
            url_for("gn_synthese.observation_count_per_column", column=column_name_dataset)
        )
        response_cd_nom = self.client.get(
            url_for("gn_synthese.observation_count_per_column", column=column_name_cd_nom)
        )

        datasets_count = {}
        for synt in synthese_data:
            if synt.id_dataset not in datasets_count:
                datasets_count[synt.id_dataset] = {"count": 1, "id_dataset": synt.id_dataset}
            else:
                datasets_count[synt.id_dataset]["count"] += 1

        cd_nom_count = {}
        for synt in synthese_data:
            if synt.cd_nom not in cd_nom_count:
                cd_nom_count[synt.cd_nom] = {"count": 1, "cd_nom": synt.cd_nom}
            else:
                cd_nom_count[synt.cd_nom]["count"] += 1

        resp_json = response_dataset.json
        assert resp_json
        for test_dataset in datasets_count.values():
            assert test_dataset["id_dataset"] in [item["id_dataset"] for item in resp_json]
            for item in resp_json:
                if item["id_dataset"] == test_dataset["id_dataset"]:
                    assert item["count"] == test_dataset["count"]

        resp_json = response_cd_nom.json
        assert resp_json
        for test_cd_nom in cd_nom_count.values():
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
