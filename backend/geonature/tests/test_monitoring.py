from flask import url_for
import pytest
from werkzeug.exceptions import Forbidden
from sqlalchemy import select
from apptax.taxonomie.models import Taxref
from pypnnomenclature.models import BibNomenclaturesTypes, TNomenclatures
from geonature.core.gn_monitoring.models import TIndividuals, TMarkingEvent
from geonature.utils.env import db
from geonature.core.gn_permissions.models import PermAction, PermObject, Permission
from pypnusershub.tests.utils import logged_user_headers, set_logged_user_cookie


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
def nomenclature_type_markings():
    typ_marquage = db.session.scalar(
        select(BibNomenclaturesTypes).where(
            BibNomenclaturesTypes.mnemonique == "TYP_MARQUAGE",
        )
    )
    nomenclature = TNomenclatures(
        id_type=typ_marquage.id_type,
        cd_nomenclature="MARQUAGE PEINTURE",
        label_default="MARQUAGE PEINTURE",
        label_fr="MARQUAGE PEINTURE",
        active=True,
    )
    with db.session.begin_nested():
        db.session.add(nomenclature)

    return nomenclature


@pytest.fixture
def markings(users, module, individuals, nomenclature_type_markings):
    user = users["self_user"]
    markings = []
    for individual in individuals:
        markings.append(
            TMarkingEvent(
                id_individual=individual.id_individual,
                id_module=module.id_module,
                digitiser=user,
                operator=user,
                marking_date="2025-01-01",
                marking_location="Là bas",
                marking_code="0007",
                marking_details="Super super",
                id_nomenclature_marking_type=nomenclature_type_markings.id_nomenclature,
            )
        )

    with db.session.begin_nested():
        db.session.add_all(markings)

    return markings


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

    def test_model_individual_has_instance_permission(
        self, app, users, individuals, module, monitoring_individual_perm_object
    ):
        set_logged_user_cookie(self.client, users["self_user"])
        set_permissions(
            module=module,
            role=users["self_user"],
            scope_value=1,
            action="R",
            object=monitoring_individual_perm_object,
        )

        individual = individuals[0]
        # Scope 0 => toujours Faux
        assert individual.has_instance_permission(0) == False
        # Scope 1 => toujours vrai
        assert individual.has_instance_permission(3) == True

        # Test avec l'utilisateur numérisateur : toujours vrai
        with app.test_request_context(headers=logged_user_headers(users["self_user"])):
            app.preprocess_request()
            assert individual.has_instance_permission(1) == True
            assert individual.has_instance_permission(2) == True

        # Test avec un utilisateur de la même structure que le numérisateur
        #   scope 1 => Faux; scope 2 : vrai
        with app.test_request_context(headers=logged_user_headers(users["associate_user"])):
            app.preprocess_request()
            assert individual.has_instance_permission(1) == False
            assert individual.has_instance_permission(2) == True

        # Test avec un utilisateur d'une autre structure que le numérisateur : toujours faux
        with app.test_request_context(headers=logged_user_headers(users["stranger_user"])):
            app.preprocess_request()
            assert individual.has_instance_permission(1) == False
            assert individual.has_instance_permission(2) == False

    def test_model_marking_has_instance_permission(
        self, app, users, markings, module, monitoring_individual_perm_object
    ):
        set_logged_user_cookie(self.client, users["self_user"])
        set_permissions(
            module=module,
            role=users["self_user"],
            scope_value=1,
            action="R",
            object=monitoring_individual_perm_object,
        )

        marking = markings[0]
        # Scope 0 => toujours Faux
        assert marking.has_instance_permission(0) == False
        # Scope 1 => toujours vrai
        assert marking.has_instance_permission(3) == True

        # Test avec l'utilisateur numérisateur : toujours vrai
        with app.test_request_context(headers=logged_user_headers(users["self_user"])):
            app.preprocess_request()
            assert marking.has_instance_permission(1) == True
            assert marking.has_instance_permission(2) == True

        # Test avec un utilisateur de la même structure que le numérisateur
        #   scope 1 => Faux; scope 2 : vrai
        with app.test_request_context(headers=logged_user_headers(users["associate_user"])):
            app.preprocess_request()
            assert marking.has_instance_permission(1) == False
            assert marking.has_instance_permission(2) == True

        # Test avec un utilisateur d'une autre structure que le numérisateur : toujours faux
        with app.test_request_context(headers=logged_user_headers(users["stranger_user"])):
            app.preprocess_request()
            assert marking.has_instance_permission(1) == False
            assert marking.has_instance_permission(2) == False
