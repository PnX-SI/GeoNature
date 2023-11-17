import datetime
import itertools
import json
from collections import Counter

import pytest
from apptax.taxonomie.models import Taxref
from apptax.tests.fixtures import attribut_example, noms_example
from flask import current_app, url_for
from geoalchemy2.shape import from_shape, to_shape
from geonature.core.gn_meta.models import TDatasets
from geonature.core.gn_synthese.models import Synthese, TSources, VSyntheseForWebApp
from geonature.utils.env import db
from jsonschema import validate as validate_json
from pypnnomenclature.models import BibNomenclaturesTypes, TNomenclatures
from pypnusershub.db.models import User
from pypnusershub.tests.utils import logged_user_headers, set_logged_user
from ref_geo.models import BibAreasTypes, LAreas
from shapely.geometry import Point
from sqlalchemy import func, select
from werkzeug.exceptions import BadRequest, Forbidden, Unauthorized

from .fixtures import *
from .fixtures import create_module, create_synthese
from .utils import jsonschema_definitions


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
def unexisted_id_source():
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


synthese_properties = {
    "type": "object",
    "properties": {
        "observations": {
            "type": "array",
            "items": {
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
                # "additionalProperties": False,
            },
        },
    },
}


@pytest.mark.usefixtures("client_class", "temporary_transaction")
class TestSynthese:
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
        schema = {
            "definitions": jsonschema_definitions,
            "$ref": "#/definitions/featurecollection",
            "$defs": {"props": synthese_properties},
        }

        r = self.client.get(url)
        assert r.status_code == Unauthorized.code

        set_logged_user(self.client, users["self_user"])

        r = self.client.get(url)
        assert r.status_code == 200
        validate_json(instance=r.json, schema=schema)

        # Add cd_nom column
        app.config["SYNTHESE"]["LIST_COLUMNS_FRONTEND"] += [
            {
                "prop": "cd_nom",
                "name": "Cdnom",
            }
        ]
        # test on synonymy and taxref attrs
        filters = {
            "cd_ref": [taxon_attribut.bib_nom.cd_ref],
            "taxhub_attribut_{}".format(taxon_attribut.bib_attribut.id_attribut): [
                taxon_attribut.valeur_attribut
            ],
        }
        r = self.client.post(url, json=filters)
        assert r.status_code == 200
        validate_json(instance=r.json, schema=schema)
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
        validate_json(instance=r.json, schema=schema)
        assert {synthese_data[k].id_synthese for k in ["p1_af1", "p1_af2"]}.issubset(
            {f["properties"]["id"] for f in r.json["features"]}
        )
        assert {synthese_data[k].id_synthese for k in ["p2_af1", "p2_af2"]}.isdisjoint(
            {f["properties"]["id"] for f in r.json["features"]}
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
        validate_json(instance=r.json, schema=schema)
        assert {synthese_data[k].id_synthese for k in ["p1_af1", "p1_af2"]}.issubset(
            {f["properties"]["id"] for f in r.json["features"]}
        )
        assert {synthese_data[k].id_synthese for k in ["p2_af1", "p2_af2"]}.isdisjoint(
            {f["properties"]["id"] for f in r.json["features"]}
        )

        # test ref geo area filter
        com_type = db.session.execute(
            select(BibAreasTypes).filter_by(type_code="COM")
        ).scalar_one()
        chambery = db.session.execute(
            select(LAreas).filter_by(area_type=com_type, area_name="Chambéry")
        ).scalar_one()
        filters = {f"area_{com_type.id_type}": [chambery.id_area]}
        r = self.client.post(url, json=filters)
        assert r.status_code == 200
        validate_json(instance=r.json, schema=schema)
        assert {synthese_data[k].id_synthese for k in ["p1_af1", "p1_af2"]}.issubset(
            {f["properties"]["id"] for f in r.json["features"]}
        )
        assert {synthese_data[k].id_synthese for k in ["p2_af1", "p2_af2"]}.isdisjoint(
            {f["properties"]["id"] for f in r.json["features"]}
        )

        # test organism
        filters = {
            "id_organism": [users["self_user"].id_organisme],
        }
        r = self.client.post(url, json=filters)
        assert r.status_code == 200
        validate_json(instance=r.json, schema=schema)
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

        assert id_synthese in (feature["properties"]["id"] for feature in r.json["features"])

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
        response_data = {feature["properties"]["id"] for feature in r.json["features"]}
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
        response_data = {feature["properties"]["id"] for feature in r.json["features"]}
        assert expected_data.issubset(response_data)
        assert len(response_data) == expected_length

    @pytest.mark.parametrize(
        "observer_input,expected_length_synthese",
        [("Vincent", 1), ("Camillé", 2), ("Camille, Elie", 2), ("Jane Doe", 0)],
    )
    def test_get_observations_for_web_filter_observers(
        self, users, synthese_for_observers, observer_input, expected_length_synthese
    ):
        set_logged_user(self.client, users["admin_user"])

        filters = {"observers": observer_input}
        r = self.client.get(url_for("gn_synthese.get_observations_for_web"), json=filters)
        assert len(r.json["features"]) == expected_length_synthese

    def test_get_synthese_data_cruved(self, app, users, synthese_data, datasets):
        set_logged_user(self.client, users["self_user"])

        response = self.client.get(
            url_for("gn_synthese.get_observations_for_web"), query_string={"limit": 100}
        )
        data = response.get_json()
        features = data["features"]
        assert len(features) > 0

        for feat in features:
            assert feat["properties"]["id"] in [
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
        "additionnal_column",
        [("altitude_min"), ("count_min_max"), ("nom_vern_or_lb_nom")],
    )
    def test_get_observations_for_web_param_column_frontend(
        self, app, users, synthese_data, additionnal_column
    ):
        """
        Test de renseigner le paramètre LIST_COLUMNS_FRONTEND pour renvoyer uniquement
        les colonnes souhaitées
        """
        app.config["SYNTHESE"]["LIST_COLUMNS_FRONTEND"] = [
            {
                "prop": additionnal_column,
                "name": "My label",
            }
        ]

        set_logged_user_cookie(self.client, users["self_user"])

        response = self.client.get(url_for("gn_synthese.get_observations_for_web"))
        data = response.get_json()

        expected_columns = {"id", "url_source", additionnal_column}

        assert all(
            set(feature["properties"].keys()) == expected_columns for feature in data["features"]
        )

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
                    "obs_sensitive_protected",
                    "obs_protected_not_sensitive",
                    "obs_sensitive_protected_2",
                ]
            ]
        )
        assert_export_results(user, expected_id_synthese_list)

        ## "associate_user_2_exclude_sensitive" : scope 2 and exclude sensitive data
        user = users["associate_user_2_exclude_sensitive"]
        expected_id_synthese_list = [synthese_data[name_obs].id_synthese for name_obs in ["obs1"]]
        expected_id_synthese_list.extend(
            [
                synthese_sensitive_data[name_obs].id_synthese
                for name_obs in ["obs_protected_not_sensitive"]
            ]
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
                    "obs_sensitive_protected",
                    "obs_protected_not_sensitive",
                    "obs_sensitive_protected_2",
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
                    Taxref.cd_nom == synthese_sensitive_data["obs_protected_not_sensitive"].cd_nom
                )
            )
            .one()
            .cd_ref
        )
        assert_export_taxons_results(user, set_expected_cd_ref)

    def test_export_status(self, users, synthese_data, synthese_sensitive_data):
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

        ## "self_user" : scope 1 and include sensitive data
        user = users["self_user"]
        set_expected_cd_ref = set(
            db.session.scalars(
                select(Taxref).where(Taxref.cd_nom == synthese_sensitive_data[name_obs].cd_nom)
            )
            .one()
            .cd_ref
            for name_obs in [
                "obs_sensitive_protected",
                "obs_protected_not_sensitive",
                "obs_sensitive_protected_2",
            ]
        )
        assert_export_status_results(user, set_expected_cd_ref)

        ## "associate_user_2_exclude_sensitive" : scope 2 and exclude sensitive data
        user = users["associate_user_2_exclude_sensitive"]
        set_expected_cd_ref = set(
            db.session.scalars(
                select(Taxref).where(Taxref.cd_nom == synthese_sensitive_data[name_obs].cd_nom)
            )
            .one()
            .cd_ref
            for name_obs in ["obs_protected_not_sensitive"]
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
                "obs_sensitive_protected",
                "obs_protected_not_sensitive",
                "obs_sensitive_protected_2",
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
            obs_synthese
            for name_obs, obs_synthese in synthese_data.items()
            if name_obs in ["obs1"]
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
                "obs_protected_not_sensitive",
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
