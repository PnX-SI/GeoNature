import json

from flask import url_for
from werkzeug.exceptions import Unauthorized, MethodNotAllowed
import pytest

from geonature.tests.fixtures import *
from geonature.tests.test_synthese import *
from pypnusershub.tests.utils import set_logged_user


@pytest.mark.usefixtures("client_class", "temporary_transaction")
class TestCRUDObservation:
    def test_post_observation(self, app, users, synthese_data, taxon_attribut):

        dataset = db.session.execute("SELECT id_dataset FROM gn_meta.t_datasets LIMIT 1").scalar()
        source = db.session.execute("SELECT id_source FROM gn_synthese.t_sources LIMIT 1").scalar()

        payload = {
            "id_source": source,
            "id_dataset": dataset,
            "date_min": "01/01/2025",
            "count_min": 1,
            "cd_nom": 61714,
            "the_geom_local": "POINT (741982.7346855227 6247916.649546455)",
            "observers": "toto",
        }

        url = url_for("gn_synthese.observations.new")

        r = self.client.get(url)
        assert r.status_code == MethodNotAllowed.code

        r = self.client.put(url, data=json.dumps(payload), content_type="application/json")
        assert r.status_code == MethodNotAllowed.code

        r = self.client.post(url, data=json.dumps(payload), content_type="application/json")
        assert r.status_code == Unauthorized.code

        set_logged_user(self.client, users["self_user"])

        r = self.client.post(url)
        assert r.status_code == 415

        r = self.client.post(url, data=json.dumps(payload), content_type="application/json")
        assert r.status_code == 201
        assert r.is_json

        data = r.get_json()
        assert "id_synthese" in data, "L'id_synthese du nouvel objet n'est pas renvoyé."

        data = r.get_json()
        id_synthese = data["id_synthese"]

        url_RUD = url_for("gn_synthese.observations.observation____", id_synthese=id_synthese)
        r = self.client.get(url_RUD)
        assert r.status_code == 200
        assert r.is_json

        r = self.client.put(url_RUD)
        assert r.status_code == 415

        payload = {"observers": "tata"}

        r = self.client.put(url_RUD, data=json.dumps(payload), content_type="application/json")
        assert r.status_code == 204

        observation_item = db.session.get(Synthese, id_synthese)
        assert (
            observation_item.observers == "tata"
        ), "La modification PUT n'a pas été effectuée comme prévue"

        r = self.client.delete(url_RUD)
        assert r.status_code == 204

        observation_item = db.session.get(Synthese, id_synthese)
        assert observation_item is None, "L'objet visé n'a pas été supprimé comme prévu"
