import uuid

from pypnusershub.auth import user_manager
from pypnusershub.db.models_register import TempUser
import pytest
from flask import url_for, current_app
from sqlalchemy import select
from pypnusershub.db.models import Application, CorRoleToken, Organisme
from unittest.mock import MagicMock

# Apparently: need to import both?
from geonature.tests.fixtures import acquisition_frameworks, datasets, module
from geonature.tests.utils import set_logged_user
from geonature.utils.env import db


@pytest.fixture
def organisms():
    """
    Returns all organismes
    """
    return db.session.scalars(select(Organisme).order_by(Organisme.id_organisme)).all()


@pytest.fixture
def add_mail_to_user(users):
    """
    Add a mail to the current user
    """
    with db.session.begin_nested():
        users["admin_user"].email = "Xp6dM@example.com"
        db.session.add(users["admin_user"])


@pytest.fixture
def fake_smtp(monkeypatch):
    mock_send = MagicMock(return_value=True)

    monkeypatch.setattr("geonature.utils.utilsmails.send_mail", mock_send)
    monkeypatch.setattr(
        "geonature.core.users.register_post_actions.send_mail", mock_send, raising=False
    )

    return mock_send


@pytest.mark.usefixtures("client_class", "temporary_transaction", "add_mail_to_user", "fake_smtp")
class TestUsers:
    example_user_data = {
        "identifiant": "temp_user",
        "email": "temp@example.com",
        "password": "P@ssword1234",
        "password_confirmation": "P@ssword1234",
        "nom_role": "Temp",
        "prenom_role": "User",
        "champs_addi": {"champ1": "valeur1", "champ2": "valeur2"},
    }

    def test_get_organismes(self, users, organisms):
        set_logged_user(self.client, users["admin_user"])

        response = self.client.get(url_for("users.get_organismes"))

        assert response.status_code == 200
        resp_uuids = [uuid.UUID(json_r["uuid_organisme"]) for json_r in response.get_json()]
        for org in organisms:
            assert org.uuid_organisme in resp_uuids

    @pytest.mark.skip()
    def test_get_organismes_no_right(self, users):
        set_logged_user(self.client, users["noright_user"])

        response = self.client.get(url_for("users.get_organismes"))

        assert response.status_code == 403

    def test_get_organisme_order_by(self, users, organisms):
        set_logged_user(self.client, users["admin_user"])
        order_by_column = "nom_organisme"

        response = self.client.get(
            url_for("users.get_organismes"), query_string={"orderby": order_by_column}
        )

        assert response.status_code == 200
        actual_names = [j_resp[order_by_column] for j_resp in response.json]
        expected_names = sorted(
            [getattr(org, order_by_column) for org in organisms], key=str.casefold
        )
        assert actual_names == expected_names

    def test_get_role(self, users):
        self_user = users["self_user"]
        set_logged_user(self.client, users["admin_user"])

        response = self.client.get(url_for("users.get_role", id_role=self_user.id_role))

        assert response.status_code == 200
        assert self_user.id_role == response.json["id_role"]

    def test_get_roles(self, users):
        noright_user = users["noright_user"]
        set_logged_user(self.client, users["admin_user"])

        response = self.client.get(url_for("users.get_roles"))

        assert response.status_code == 200
        assert noright_user.id_role in [j_resp["id_role"] for j_resp in response.json]

    def test_get_roles_group(self):
        pass

    def test_get_roles_order_by(self, users):
        set_logged_user(self.client, users["admin_user"])

        response = self.client.get(
            url_for("users.get_roles"), query_string={"orderby": "identifiant"}
        )

        assert response.status_code == 200
        identifiants_resp = [resp["identifiant"] for resp in response.json]
        assert identifiants_resp.index(users["admin_user"].identifiant) < identifiants_resp.index(
            users["stranger_user"].identifiant
        )

    def test_get_organismes_jdd_no_auth(self):
        response = self.client.get(url_for("users.get_organismes_jdd"))

        assert response.status_code == 401

    def test_get_organismes_jdd(self, users, datasets):
        # Need to have a dataset to have the organism...
        set_logged_user(self.client, users["admin_user"])

        response = self.client.get(url_for("users.get_organismes_jdd"))
        assert users["admin_user"].organisme.nom_organisme in [
            org["nom_organisme"] for org in response.json
        ]

    @pytest.mark.xfail(reason="Quel est le but de ce test ?")
    def test_get_organismes_jdd_no_dataset(self, users):
        set_logged_user(self.client, users["admin_user"])

        response = self.client.get(url_for("users.get_organismes_jdd"))

        assert response.status_code == 200
        assert users["admin_user"].organisme.nom_organisme not in [
            org["nom_organisme"] for org in response.json
        ]

    def test_inscription_not_found(self, monkeypatch):
        monkeypatch.setitem(current_app.config["ACCOUNT_MANAGEMENT"], "ENABLE_SIGN_UP", False)

        response = self.client.post(url_for("users.inscription"))

        assert response.status_code == 404
        assert response.json["description"] == "Page not found"

    def test_inscription_enabled_and_disabled(self):
        """
        Test POST /inscription when ENABLE_SIGN_UP is enabled and disabled.
        """
        # Disabled case: expect 404
        current_app.config["ACCOUNT_MANAGEMENT"]["ENABLE_SIGN_UP"] = False
        url = url_for("users.inscription")
        response = self.client.post(url)
        assert response.status_code == 404
        assert response.json["description"] == "Page not found"

        # Enabled case: expect 200
        current_app.config["ACCOUNT_MANAGEMENT"]["ENABLE_SIGN_UP"] = True
        current_app.config["CODE_APPLICATION"] = "GN"

        # Get an existing application
        app = db.session.execute(select(Application)).scalars().first()
        assert app, "There must be at least one Application in DB"

        response = self.client.post(url, json=self.example_user_data)
        assert response.status_code == 200

    def test_inscription_invalid_password(self):
        current_app.config["CODE_APPLICATION"] = "GN"

        # Get an existing application
        app = db.session.execute(select(Application)).scalars().first()
        assert app, "There must be at least one Application in DB"

        data = self.example_user_data.copy()
        data["password"] = "invalid_password"
        data["password_confirmation"] = "invalid_password"
        response = self.client.post(url_for("users.inscription"), json=data)
        assert response.status_code == 400
        assert response.json["description"] == "Le mot de passe ne respècte pas les critères"

    def test_login_recovery_enabled_and_disabled(self, users):
        """
        Test POST /login/recovery when ENABLE_USER_MANAGEMENT is enabled and disabled.
        """
        url = url_for("users.login_recovery")
        payload = {"email": users["admin_user"].email}

        # Disabled case
        current_app.config["ACCOUNT_MANAGEMENT"]["ENABLE_USER_MANAGEMENT"] = False
        response = self.client.post(url, json=payload)
        assert response.status_code == 404

        # Enabled case
        current_app.config["ACCOUNT_MANAGEMENT"]["ENABLE_USER_MANAGEMENT"] = True
        response = self.client.post(url, json=payload)
        assert response.status_code == 200

    def test_confirmation_route(self):
        """
        Test GET /confirmation behavior with and without token.
        """
        current_app.config["ACCOUNT_MANAGEMENT"]["ENABLE_SIGN_UP"] = True
        current_app.config["CODE_APPLICATION"] = "GN"
        url_confirmation = url_for("users.confirmation")
        url_inscription = url_for("users.inscription")
        # Missing token -> BadRequest
        resp = self.client.get(url_confirmation)
        assert resp.status_code == 400
        assert "Token not found" in resp.json["description"]

        resp = self.client.post(
            url_inscription,
            json=self.example_user_data,
        )
        assert resp.status_code == 200

        token = (
            db.session.execute(select(TempUser).where(TempUser.email == "temp@example.com"))
            .scalar_one()
            .token_role
        )

        resp = self.client.get(url_confirmation, query_string={"token": token})
        assert resp.status_code == 200

        resp = self.client.get(url_confirmation, query_string={"token": "badtoken"})
        assert resp.status_code == 400

    def test_update_role_fields(self, users):
        """
        Test PUT /role updates allowed fields only.
        """
        set_logged_user(self.client, users["admin_user"])
        data = {
            "nom_role": "New Admin Name",
            "active": False,  # blacklisted, should not change
        }

        resp = self.client.put(url_for("users.update_role"), json=data)
        assert resp.status_code == 200

        assert resp.json["nom_role"] == "New Admin Name"
        assert resp.json["active"] == True

    def test_password_new_cases(self, users):
        """
        Test PUT /password/new for missing token and with token.
        """
        # Missing token
        url = url_for("users.new_password")
        resp = self.client.put(url, json={"password": "x", "password_confirmation": "x"})
        assert resp.status_code == 400
        assert resp.json["description"] == "No token provided"

        with db.session.begin_nested():
            cor_role_token = CorRoleToken(
                token="jesuisuntokennul", id_role=users["admin_user"].id_role
            )
            db.session.add(cor_role_token)

        resp = self.client.put(
            url,
            json={
                "token": "jesuisuntokennul",
                "password": "doesnt respect password criterium",
                "password_confirmation": "doesnt respect password criterium",
            },
        )
        assert resp.status_code == 400
        assert resp.json["description"] == "Le mot de passe ne respècte pas les critères"

        resp = self.client.put(
            url,
            json={
                "token": "jesuisuntokennul",
                "password": "P@ssword1234",
                "password_confirmation": "P@ssword1234",
            },
        )
        assert resp.status_code == 200
        assert resp.json["message"] == "Password changed with success"

    def test_change_password_route(self, users):
        user = users["admin_user"]
        user.password = "x"
        token = user_manager.create_cor_role_token(user.email)
        set_logged_user(self.client, user)
        url = url_for("users.change_password_route")
        resp = self.client.put(
            url,
            json={
                "init_password": "x",
                "password": "y",
                "password_confirmation": "y",
                "token": token,
            },
        )
        assert resp.status_code == 400
        assert resp.json["description"] == "Le mot de passe ne respècte pas les critères"
        resp = self.client.put(
            url,
            json={
                "init_password": "x",
                "password": "P@ssword1234",
                "password_confirmation": "P@ssword1234",
                "token": token,
            },
        )
        assert resp.status_code == 200
        assert resp.json["message"] == "Password changed with success"

    def test_get_organism(self, users, organisms):
        """
        Test GET /organism/<id> returns organism details
        """
        set_logged_user(self.client, users["admin_user"])
        # Cannot take organisms[0] because its ID is -1, and would raise a 404
        organism = organisms[1]

        response = self.client.get(
            url_for("users.get_organism", id_organisme=organism.id_organisme)
        )

        assert response.status_code == 200
        assert response.json["id_organisme"] == organism.id_organisme
        assert response.json["nom_organisme"] == organism.nom_organisme

    def test_get_organismes(self, users, organisms):
        """
        Test GET /organisms returns all organisms
        """
        set_logged_user(self.client, users["admin_user"])

        response = self.client.get(url_for("users.get_organismes", orderby="nom_organisme:desc"))

        assert response.status_code == 200
        first_letter = [org["nom_organisme"][0] for org in response.json]
        assert first_letter == sorted(first_letter, reverse=True)

        response = self.client.get(url_for("users.get_organismes", orderby="nom_organisme"))

        assert response.status_code == 200
        first_letter = [org["nom_organisme"][0] for org in response.json]
        assert first_letter == sorted(first_letter, reverse=False)

    def test_get_organism_with_search_params(self, users, organisms):
        """
        Test GET /organisms with search params
        """
        set_logged_user(self.client, users["admin_user"])
        # Cannot take organisms[0] because its ID is -1, and would raise a 404
        organism = organisms[1]

        response = self.client.get(url_for("users.get_organismes", search=organism.nom_organisme))

        assert response.status_code == 200
        assert response.json[0]["id_organisme"] == organism.id_organisme
        assert response.json[0]["nom_organisme"] == organism.nom_organisme

        organism = organisms[3]
        for variation in [
            organism.nom_organisme,
            organism.nom_organisme.lower(),
            organism.nom_organisme.upper(),
            organism.nom_organisme.title(),
            organism.nom_organisme[:-2],
        ]:
            response = self.client.get(url_for("users.get_organismes", search=variation))

            assert response.status_code == 200
            assert response.json[0]["id_organisme"] == organism.id_organisme
            assert response.json[0]["nom_organisme"] == organism.nom_organisme

    def test_get_organism_not_found(self, users, organisms):
        """
        Test GET /organism/<id> returns 404 for non-existent organism
        """
        set_logged_user(self.client, users["admin_user"])
        id_organism = max([org.id_organisme for org in organisms]) + 1

        response = self.client.get(url_for("users.get_organism", id_organisme=id_organism))

        assert response.status_code == 404
        assert "Organism not found" in response.json["description"]

    def test_get_organism_no_auth(self, organisms):
        """
        Test GET /organism/<id> requires authentication
        """
        # Cannot take organisms[0] because its ID is -1, and would raise a 404
        organism = organisms[1]

        response = self.client.get(
            url_for("users.get_organism", id_organisme=organism.id_organisme)
        )

        assert response.status_code == 401

    def test_create_organism(self, users):
        """
        Test POST /organism creates a new organism
        """
        set_logged_user(self.client, users["admin_user"])

        new_organism_data = {
            "nom_organisme": "Test Organism",
            "adresse_organisme": "123 Test Street",
            "cp_organisme": "12345",
            "ville_organisme": "Test City",
            "tel_organisme": "0123456789",
            "email_organisme": "test@example.com",
            "url_organisme": "https://test.example.com",
            "url_logo": "https://test.example.com/logo.png",
        }

        response = self.client.post(url_for("users.create_organism"), json=new_organism_data)

        assert response.status_code == 200
        assert response.json["nom_organisme"] == "Test Organism"
        assert response.json["adresse_organisme"] == "123 Test Street"
        assert response.json["email_organisme"] == "test@example.com"
        assert "id_organisme" in response.json

    def test_create_organism_missing_name(self, users):
        """
        Test POST /organism returns 400 when organism name is missing
        """
        set_logged_user(self.client, users["admin_user"])

        new_organism_data = {
            "adresse_organisme": "123 Test Street",
        }

        response = self.client.post(url_for("users.create_organism"), json=new_organism_data)

        assert response.status_code == 400
        assert response.json["description"] == "Organism name is required"

    def test_create_organism_no_permission(self, users):
        """
        Test POST /organism requires CREATE permission
        """
        set_logged_user(self.client, users["noright_user"])

        new_organism_data = {
            "nom_organisme": "Test Organism",
        }

        response = self.client.post(url_for("users.create_organism"), json=new_organism_data)

        assert response.status_code == 403

    def test_create_organism_internal_error(self, users, monkeypatch):
        """
        Test POST /organism handles internal errors gracefully
        """
        set_logged_user(self.client, users["admin_user"])

        # Mock insert_or_update_organism to raise an exception
        def mock_insert_error(*args, **kwargs):
            raise Exception("Database connection error")

        monkeypatch.setattr(
            "geonature.core.users.routes.insert_or_update_organism", mock_insert_error
        )

        new_organism_data = {
            "nom_organisme": "Test Organism",
        }

        response = self.client.post(url_for("users.create_organism"), json=new_organism_data)

        assert response.status_code == 500
        # We check `response.data` since `response.json` is None
        assert (
            b'"description": "Error creating organism: Database connection error"' in response.data
        )

    def test_change_mail_route(self, users, fake_smtp):
        url = url_for("users.new_mail")
        user = users["admin_user"]
        set_logged_user(self.client, user)

        current_app.config["ACCOUNT_MANAGEMENT"]["ENABLE_USER_MANAGEMENT"] = True
        new_email = "new_email@example.com"
        payload = {"new_mail": new_email}
        resp = self.client.put(url, json=payload)
        assert resp.status_code == 200
        assert resp.json["message"] == "Confirmation mail sent to new_email@example.com"
        assert fake_smtp.called
        args, kwargs = fake_smtp.call_args
        assert new_email in args[0]

        resp = self.client.put(url, json={})
        assert resp.status_code == 400
        assert resp.json["description"] == "No new mail provided"

        current_app.config["ACCOUNT_MANAGEMENT"]["ENABLE_USER_MANAGEMENT"] = False
        resp = self.client.put(url, json=payload)
        assert resp.status_code == 404

    def test_confirm_new_mail_route(self, users, fake_smtp):
        """
        Test PUT /mail/new behavior.
        """
        url = url_for("users.confirm_new_mail")
        user = users["admin_user"]
        set_logged_user(self.client, user)
        current_app.config["ACCOUNT_MANAGEMENT"]["ENABLE_USER_MANAGEMENT"] = True

        old_email = user.email
        new_email = "new_email@example.com"
        payload = {"new_mail": new_email, "user": user.id_role}
        resp = self.client.put(url, json=payload)
        assert resp.status_code == 200
        assert resp.json["message"] == "Mail successfully changed"
        assert user.email == new_email
        assert fake_smtp.called
        args, kwargs = fake_smtp.call_args
        assert old_email in args[0]

        resp = self.client.put(url, json={"user": user.id_role})
        assert resp.status_code == 400
        assert resp.json["description"] == "No new mail provided"

        payload_mismatch = {"new_mail": "another@example.com", "user": 99999}  # Wrong ID
        resp = self.client.put(url, json=payload_mismatch)
        assert resp.status_code == 400
        assert "User id does not match user connected" in resp.json["description"]
