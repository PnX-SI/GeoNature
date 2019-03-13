import json
import pytest
from flask import url_for, session, Response, request
from .bootstrap_test import app, releve_data, post_json, json_of_response, get_token
from cookies import Cookie

from pypnusershub.db.tools import InsufficientRightsError


@pytest.mark.usefixtures("client_class")
class TestApiModulePrOcctax:
    """
        Test de l'api du module pr_occtax
    """

    mimetype = "application/json"
    headers = {"Content-Type": mimetype, "Accept": mimetype}

    def test_get_releves(self):
        token = get_token(self.client)
        self.client.set_cookie("/", "token", token)
        response = self.client.get(url_for("pr_occtax.getReleves"))

        assert response.status_code == 200

    def test_insert_update_delete_releves(self, releve_data):
        token = get_token(self.client)
        self.client.set_cookie("/", "token", token)

        response = post_json(
            self.client, url_for("pr_occtax.insertOrUpdateOneReleve"), releve_data
        )

        assert response.status_code == 200

        update_data = json_of_response(response)
        update_data["properties"].pop("digitiser")
        update_data["properties"]["comment"] = "Super MODIIFF"
        update_data["properties"]["observers"] = [1]

        update_data["properties"]["observers"] = [1]

        # insert with to new occurrences
        for i in range(2):
            # put an ID = None to reproduce the MERGE bug
            temp = update_data["properties"]["t_occurrences_occtax"][0]
            temp["id_occurrence_occtax"] = None
            for count in temp["cor_counting_occtax"]:
                count["id_occurrence_occtax"] = None

            update_data["properties"]["t_occurrences_occtax"].append(temp)

        response = post_json(
            self.client, url_for("pr_occtax.insertOrUpdateOneReleve"), update_data
        )

        assert response.status_code == 200

        resp_data_update = json_of_response(response)

        assert resp_data_update["properties"]["comment"] == "Super MODIIFF"

        # get the releve
        response = self.client.get(
            url_for(
                "pr_occtax.getOneReleve",
                id_releve=resp_data_update["properties"]["id_releve_occtax"],
            )
        )
        resp_data_update = json_of_response(response)

        assert "releve" in resp_data_update
        # check that the 3 occurrences are heres
        assert (
            len(resp_data_update["releve"]["properties"]["t_occurrences_occtax"]) == 3
        )
        response = self.client.delete(
            url_for(
                "pr_occtax.deleteOneReleve",
                id_releve=resp_data_update["releve"]["properties"]["id_releve_occtax"],
            )
        )

        assert response.status_code == 200

    def test_get_export_sinp(self):
        token = get_token(self.client)
        self.client.set_cookie("/", "token", token)

        response = self.client.get(url_for("pr_occtax.export"))

        assert response.status_code == 200

    def test_export_sinp_multiformat(self):
        # User agent est digitiser que d'un seul relevé avec 2 counting
        token = get_token(self.client, login="agent", password="admin")

        base_query_string = {
            "id_dataset": 1,
            "cd_nom": 67111,
            "date_up": "2017-05-11",
            "date_low": "2009-05-01",
        }
        # CSV
        csv_query_string = base_query_string.copy()
        csv_query_string["format"] = "csv"
        response = self.client.get(
            url_for("pr_occtax.export"), query_string=csv_query_string
        )

        assert response.status_code == 200

        # geojson
        geojson_query_string = base_query_string.copy()
        geojson_query_string["format"] = "geojson"
        response = self.client.get(
            url_for("pr_occtax.export"), query_string=geojson_query_string
        )
        assert response.status_code == 200
        data = json_of_response(response)
        assert len(data["features"]) == 2
        # shapefile
        shape_query_string = base_query_string.copy()
        shape_query_string["format"] = "shapefile"
        response = self.client.get(
            url_for("pr_occtax.export"), query_string=shape_query_string
        )
        assert response.status_code == 200

    # ## Test des droits ####
    def test_get_and_delete_releve(self):
        """
            user admin is observer of releve 1
        """
        token = get_token(self.client)
        self.client.set_cookie("/", "token", token)

        response = self.client.get(url_for("pr_occtax.getOneReleve", id_releve=1))
        assert response.status_code == 200

    def test_user_cannot_delete_releve(self):
        """
            user agent is not observer, digitiser
            or in cor_dataset_actor
        """
        token = get_token(self.client, login="agent", password="admin")
        self.client.set_cookie("/", "token", token)

        with pytest.raises(InsufficientRightsError):
            response = self.client.get(
                url_for("pr_occtax.deleteOneReleve", id_releve=1)
            )
