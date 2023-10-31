from flask import url_for
import pytest

from apptax.taxonomie.models import Taxref
from geonature.core.gn_monitoring.models import TIndividuals
from geonature.utils.env import db
from pypnusershub.tests.utils import set_logged_user_cookie

from .fixtures import *

CD_NOM = 212


@pytest.fixture
def individuals(users):
    taxon = Taxref.query.filter_by(cd_nom=CD_NOM).one()
    user = users["self_user"]
    individuals = []
    for name in ["Test1", "Test2"]:
        individuals.append(TIndividuals(individual_name=name, cd_nom=taxon.cd_nom, digitiser=user))

    with db.session.begin_nested():
        db.session.add_all(individuals)

    return individuals


@pytest.mark.usefixtures("client_class", "temporary_transaction")
class TestMonitoring:
    def test_get_individuals(self, users, individuals):
        set_logged_user_cookie(self.client, users["self_user"])

        # Post with only required attributes
        response = self.client.get(url_for("gn_monitoring.get_individuals"))

        json_resp = response.json
        expected_individuals_uuid = {individual.uuid_individual for individual in individuals}
        individuals_uuid_from_response = {
            individual["uuid_individual"] for individual in json_resp
        }

        assert expected_individuals_uuid.issubset(individuals_uuid_from_response)

    def test_get_individuals_with_id_module(self, users, individuals, module):
        set_logged_user_cookie(self.client, users["self_user"])

        # Add individual to module X
        with db.session.begin_nested():
            individuals[0].modules = [module]

        response = self.client.get(
            url_for("gn_monitoring.get_individuals"), query_string={"id_module": module.id_module}
        )
        resp_json = response.json
        not_expected_individual_uuid = {individuals[1].uuid_individual}
        expected_individual_uuid = {individuals[0].uuid_individual}
        actual_individual_uuid = {individual["uuid_individual"] for individual in resp_json}

        assert actual_individual_uuid.isdisjoint(not_expected_individual_uuid)
        assert actual_individual_uuid.issubset(expected_individual_uuid)

    def test_create_one_individual(self, users):
        set_logged_user_cookie(self.client, users["self_user"])
        individual_name = "Test_Post"
        individual = {"individual_name": individual_name, "cd_nom": CD_NOM}

        response = self.client.post(
            url_for("gn_monitoring.create_one_individual"), json=individual
        )

        json_resp = response.json
        assert json_resp["cd_nom"] == CD_NOM
        assert json_resp["individual_name"] == individual_name
