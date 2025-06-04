import json

from flask import url_for
from werkzeug.exceptions import Unauthorized, MethodNotAllowed
import pytest

from geonature.tests.fixtures import *
from geonature.tests.test_synthese import *
from pypnusershub.tests.utils import set_logged_user


@pytest.mark.usefixtures("client_class", "temporary_transaction")
class TestGeoms:

    def test_get_observations_for_web(self, app, users, synthese_data, taxon_attribut):
        url = url_for("gn_synthese.observations.geoms")
        r = self.client.get(url)
        assert r.status_code == MethodNotAllowed.code
        r = self.client.post(url)
        assert r.status_code == Unauthorized.code
        set_logged_user(self.client, users["self_user"])
        r = self.client.post(url)
        assert r.status_code == 400
        payload = {"area_aggregation_type": "M10"}
        r = self.client.post(url, data=json.dumps(payload), content_type="application/json")
        assert r.status_code == 200
        assert r.is_json
        data = r.get_json()
        print(data)
        assert "features" in data

        expected_id_area = 658738
        expected_observation_count = 4

        matching_feature = None
        for feature in data["features"]:
            props = feature.get("properties", {})
            if (
                props.get("id_area") == expected_id_area
                and props.get("observation_count") == expected_observation_count
            ):
                matching_feature = feature
                break

        assert (
            matching_feature is not None
        ), "La feature attendue n'a pas été trouvée dans la réponse"
        payload = {"area_aggregation_type": "COM"}
        r = self.client.post(url, data=json.dumps(payload), content_type="application/json")
        data = r.get_json()
        assert "Chambéry" in [feature["properties"]["area_name"] for feature in data["features"]]
