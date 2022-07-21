from pyrsistent import v
import pytest

from flask import url_for, current_app
from jsonschema import validate
from sqlalchemy.sql import func


from .bootstrap_test import app, post_json, json_of_response, get_token

from geonature.core.users import routes as users

dataset_schema = {
    "type": "object",
    "properties": {
        "acquisition_framework": {"type": "object"},
        "cor_dataset_actor": {"type": "array"},
        "creator": {"type": "object"},
        "id_digitizer": {"type": "number"},
        "dataset_name": {"type": "string"},
        "dataset_shortname": {"type": "string"},
        "dataset_desc": {"type": "string"},
        "id_nomenclature_data_type": {"type": "integer"},
        "id_nomenclature_source_status": {"type": "integer"},
        "id_nomenclature_dataset_objectif": {"type": "integer"},
        "id_nomenclature_collecting_method": {"type": "integer"},
        "id_nomenclature_data_origin": {"type": "integer"},
        "id_nomenclature_resource_type": {"type": "integer"},
        "cor_territories": {"type": "array"},
    },
    "required": [
        "id_digitizer",
        "acquisition_framework",
        "cor_dataset_actor",
        "creator",
        "dataset_name",
        "dataset_shortname",
        "dataset_desc",
        "id_nomenclature_data_type",
        "id_nomenclature_source_status",
        "id_nomenclature_dataset_objectif",
        "id_nomenclature_collecting_method",
        "id_nomenclature_data_origin",
        "id_nomenclature_resource_type",
        "cor_territories",
    ],
}

af_schema = {
    "type": "object",
    "properties": {
        "t_datasets": {"type": "array"},
        "cor_af_actor": {"type": "array"},
        "cor_territories": {"type": "array"},
        "creator": {"type": "object"},
        "id_digitizer": {"type": "number"},
        "acquisition_framework_name": {"type": "string"},
        "acquisition_framework_desc": {"type": "string"},
        "acquisition_framework_start_date": {"type": "string"},
    },
    "required": [
        "id_digitizer",
        "t_datasets",
        "cor_af_actor",
        "creator",
        "acquisition_framework_name",
        "acquisition_framework_desc",
        "cor_territories",
        "acquisition_framework_start_date",
    ],
}


@pytest.mark.usefixtures("client_class")
class TestGnMeta:
    def test_list_datasets(self):
        """
        Api to get all datasets
        """
        # token = get_token(self.client)
        token = get_token(self.client, login="admin", password="admin")
        self.client.set_cookie("/", "token", token)

        response = self.client.get(url_for("gn_meta.get_datasets"), query_string={"depth": 1})

        # check fields for mobile
        data = json_of_response(response)
        ds = data["data"][0]
        mandatory_attr = [
            "id_dataset",
            "dataset_name",
            "dataset_desc",
            "active",
            "meta_create_date",
            "modules",
        ]
        for attr in mandatory_attr:
            assert attr in ds
        module = ds["modules"][0]
        assert "module_path" in module
        assert response.status_code == 200

        # test with depth = 0 (default param)
        response = self.client.get(
            url_for("gn_meta.get_datasets"),
        )
        assert response.status_code == 200
        data = json_of_response(response)
        ds = data["data"][0]
        assert "modules" not in ds

    def test_one_dataset(self):
        """
        API to get one dataset from id_dataset
        """
        token = get_token(self.client, login="admin", password="admin")
        self.client.set_cookie("/", "token", token)
        response = self.client.get(url_for("gn_meta.get_dataset", id_dataset=1))
        assert response.status_code == 200

    def test_dataset_cruved_2(self):
        """
        API to get datasets with CRUVED authorization
        CRUVED = 2
        """
        token = get_token(self.client, login="agent", password="admin")
        self.client.set_cookie("/", "token", token)
        response = self.client.get(url_for("gn_meta.get_datasets"))
        dataset_list = json_of_response(response)
        assert response.status_code == 200 and len(dataset_list["data"]) == 2

    def test_dataset_cruved_1(self):
        """
        API to get datasets with CRUVED authorization
        CRUVED = 1
        """
        token = get_token(self.client, login="partenaire", password="admin")
        self.client.set_cookie("/", "token", token)
        response = self.client.get(url_for("gn_meta.get_datasets"))
        dataset_list = json_of_response(response)
        assert (
            response.status_code == 200
            and len(dataset_list["data"]) == 1
            and dataset_list["data"][0]["id_dataset"] == 3
        )

    def test_post_and_update_dataset(self):
        token = get_token(self.client, login="admin", password="admin")
        self.client.set_cookie("/", "token", token)
        one_dataset = {
            "active": True,
            "bbox_east": None,
            "bbox_north": None,
            "bbox_south": None,
            "bbox_west": None,
            "cor_dataset_actor": [
                {
                    "id_cda": None,
                    "id_nomenclature_actor_role": 359,
                    "id_organism": 0,
                    "id_role": None,
                }
            ],
            "dataset_desc": "a",
            "dataset_name": "a",
            "dataset_shortname": "a",
            "id_acquisition_framework": 1,
            "id_nomenclature_collecting_method": 405,
            "id_nomenclature_data_type": 323,
            "id_nomenclature_dataset_objectif": 408,
            "id_nomenclature_resource_type": 321,
            "id_nomenclature_source_status": 73,
            # meta_dates must be ignored NEVER post !
            "meta_create_date": "lala",
            "meta_update_date": "lala",
            "keywords": None,
            "marine_domain": False,
            "terrestrial_domain": True,
            "validable": True,
            # meta_dates must be ignored NEVER post !
            "modules": [
                {"id_module": 1, "meta_create_date": "fake_date", "meta_update_date": "fake_date"}
            ],
        }
        response = post_json(self.client, url_for("gn_meta.create_dataset"), json_dict=one_dataset)
        assert response.status_code == 200
        dataset = response.get_json()
        assert len(dataset["modules"]) == 1

        validate(instance=dataset, schema=dataset_schema)

        response = self.client.get(
            url_for("gn_meta.get_dataset", id_dataset=dataset["id_dataset"])
        )
        fetched_dataset = json_of_response(response)
        # suppression du module associé
        fetched_dataset["modules"] = []

        for cor in fetched_dataset["cor_dataset_actor"]:
            cor.pop("organism")
            cor.pop("nomenclature_actor_role")
        # ajout d'un acteur
        fetched_dataset["cor_dataset_actor"].append(
            {
                "id_cda": None,
                "id_nomenclature_actor_role": 359,
                "id_organism": 1,
                "id_role": None,
            }
        )
        # modification du nom
        fetched_dataset["dataset_name"] = "new_name"
        response = post_json(
            self.client,
            url_for("gn_meta.update_dataset", id_dataset=fetched_dataset["id_dataset"]),
            json_dict=fetched_dataset,
        )
        updated_dataset = json_of_response(response)
        assert len(updated_dataset["modules"]) == 0

        assert len(updated_dataset["cor_dataset_actor"]) == 2
        assert updated_dataset["dataset_name"] == "new_name"
        assert response.status_code == 200

    def test_post_ca(self):
        token = get_token(self.client, login="admin", password="admin")
        self.client.set_cookie("/", "token", token)
        one_ca = {
            "acquisition_framework_desc": "ttt",
            "acquisition_framework_end_date": None,
            "acquisition_framework_name": "tt",
            "acquisition_framework_parent_id": None,
            "acquisition_framework_start_date": "2019-07-03",
            "cor_af_actor": [
                {
                    "id_cafa": None,
                    "id_nomenclature_actor_role": 359,
                    "id_organism": 0,
                    "id_role": None,
                }
            ],
            "cor_objectifs": [{"id_nomenclature": 515}],
            "cor_volets_sinp": [],
            "ecologic_or_geologic_target": "aaaa",
            "id_nomenclature_financing_type": 382,
            "id_nomenclature_territorial_level": 355,
            "is_parent": False,
            "keywords": "ttt",
            "target_description": None,
            "territory_desc": "aaa",
        }

        response = post_json(
            self.client, url_for("gn_meta.create_acquisition_framework"), json_dict=one_ca
        )
        af = response.get_json()

        validate(instance=af, schema=af_schema)
        assert response.status_code == 200

    def test_get_af_list(self):
        token = get_token(self.client, login="admin", password="admin")
        self.client.set_cookie("/", "token", token)
        query_string = {"nested": "true", "excluded_fields": "creator"}
        response = self.client.get(
            url_for("gn_meta.get_acquisition_frameworks_list"), query_string=query_string
        )
        assert response.status_code == 200
        afs = response.get_json()
        af = afs[0]
        assert "creator" not in af
        assert "nomenclature_financing_type" in af

    def test_get_afs(self):
        token = get_token(self.client, login="admin", password="admin")
        self.client.set_cookie("/", "token", token)
        response = self.client.get(
            url_for("gn_meta.get_acquisition_frameworks"),
        )
        assert response.status_code == 200
        afs = response.get_json()
        af = afs[0]
        # check there are NO relationship in the result
        for key, val in af.items():
            assert type(val) is not dict
            assert type(val) is not list
