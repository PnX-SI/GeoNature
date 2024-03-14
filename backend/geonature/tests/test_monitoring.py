from flask import url_for
import pytest
from werkzeug.exceptions import Forbidden
from sqlalchemy import select
from apptax.taxonomie.models import Taxref
from geonature.core.gn_monitoring.models import TIndividuals
from geonature.utils.env import db
from geonature.core.gn_permissions.models import PermAction, PermObject, Permission
from pypnusershub.tests.utils import set_logged_user_cookie

from .fixtures import *

CD_NOM = 212


@pytest.fixture
def individuals(users, module):
    taxon = Taxref.query.filter_by(cd_nom=CD_NOM).one()
    user = users["self_user"]
    individuals = []
    for name in ["Test1", "Test2"]:
        individuals.append(TIndividuals(individual_name=name, cd_nom=taxon.cd_nom, digitiser=user))

    with db.session.begin_nested():
        db.session.add_all(individuals)

    # Add individual to module X
    with db.session.begin_nested():
        individuals[0].modules = [module]

    return individuals


@pytest.fixture
def monitoring_individual_perm_object():
    individuals_object = "MONITORINGS_INDIVIDUALS"
    perm_object = db.session.scalar(
        select(PermObject).where(PermObject.code_object == individuals_object)
    )
    if perm_object is None:
        perm_object = PermObject(code_object=individuals_object)
        with db.session.begin_nested():
            db.session.add(perm_object)
    return perm_object


def set_permissions(module, role, scope_value, action="R", **kwargs):
    action = PermAction.query.filter_by(code_action=action).one()
    perm = Permission(
        role=role,
        action=action,
        module=module,
        scope_value=scope_value,
        **kwargs,
    )
    with db.session.begin_nested():
        db.session.add(perm)
    return perm


@pytest.mark.usefixtures("client_class", "temporary_transaction")
class TestMonitoring:
    def test_get_individuals_forbidden(self, users, module):
        set_logged_user_cookie(self.client, users["self_user"])

        response = self.client.get(
            url_for("gn_monitoring.get_individuals", id_module=module.id_module)
        )
        assert response.status_code == Forbidden.code

    def test_get_individuals(self, users, individuals, module, monitoring_individual_perm_object):
        set_logged_user_cookie(self.client, users["self_user"])
        set_permissions(
            module=module,
            role=users["self_user"],
            scope_value=1,
            action="R",
            object=monitoring_individual_perm_object,
        )

        response = self.client.get(
            url_for("gn_monitoring.get_individuals", id_module=module.id_module)
        )
        resp_json = response.json
        not_expected_individual_uuid = {individuals[1].uuid_individual}
        expected_individual_uuid = {individuals[0].uuid_individual}
        actual_individual_uuid = {individual["uuid_individual"] for individual in resp_json}

        assert actual_individual_uuid.isdisjoint(not_expected_individual_uuid)
        assert actual_individual_uuid.issubset(expected_individual_uuid)

    def test_get_individuals_no_rights(
        self, users, individuals, module, monitoring_individual_perm_object
    ):
        user = users["noright_user"]
        set_logged_user_cookie(self.client, user)

        response = self.client.get(
            url_for("gn_monitoring.get_individuals", id_module=module.id_module)
        )

        assert response.status_code == Forbidden.code
        expected_msg = f"User {user.id_role} has no permissions to R in {module.module_code} on {monitoring_individual_perm_object.code_object}"
        assert response.json["description"] == expected_msg

    def test_get_individuals_rights_organism(
        self, users, individuals, module, monitoring_individual_perm_object
    ):
        set_logged_user_cookie(self.client, users["self_user"])
        set_permissions(
            module=module,
            role=users["self_user"],
            scope_value=2,
            action="R",
            object=monitoring_individual_perm_object,
        )

        response = self.client.get(
            url_for("gn_monitoring.get_individuals", id_module=module.id_module)
        )
        resp_json = response.json
        not_expected_individual_uuid = {individuals[1].uuid_individual}
        expected_individual_uuid = {individuals[0].uuid_individual}
        actual_individual_uuid = {individual["uuid_individual"] for individual in resp_json}

        assert actual_individual_uuid.isdisjoint(not_expected_individual_uuid)
        assert actual_individual_uuid.issubset(expected_individual_uuid)

    def test_create_individuals_forbidden(self, users, module):
        set_logged_user_cookie(self.client, users["self_user"])

        response = self.client.post(
            url_for("gn_monitoring.create_one_individual", id_module=module.id_module), json={}
        )
        assert response.status_code == Forbidden.code

    def test_create_one_individual(self, users, module, monitoring_individual_perm_object):
        set_logged_user_cookie(self.client, users["self_user"])
        set_permissions(
            module=module,
            role=users["self_user"],
            scope_value=1,
            action="C",
            object=monitoring_individual_perm_object,
        )

        individual_name = "Test_Post"
        individual = {"individual_name": individual_name, "cd_nom": CD_NOM}

        response = self.client.post(
            url_for("gn_monitoring.create_one_individual", id_module=module.id_module),
            json=individual,
        )

        json_resp = response.json
        assert json_resp["cd_nom"] == CD_NOM
        assert json_resp["individual_name"] == individual_name
