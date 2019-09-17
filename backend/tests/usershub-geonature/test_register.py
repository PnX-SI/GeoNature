import json
import pytest

from cookies import Cookie
from flask import url_for, session, Response, request, current_app

from tests.bootstrap_test import app, post_json, json_of_response, get_token
from pypnusershub.db.models import User
from geonature.utils.env import DB
from geonature.core.gn_meta.models import CorDatasetActor, CorAcquisitionFrameworkActor


@pytest.mark.usefixtures("client_class")
class TestApiRegister:
    """
        Test de l'api register
        La config de la gesion des compte doit être en mode auto_validation (AUTO_DATASET_CREATION = true)
    """

    user_form = {
        "prenom_role": "la",
        "nom_role": "la",
        "identifiant": "hello_test",
        "password": "hello",
        "password_confirmation": "hello",
        "email": "email_test@mail.com",
        "organisme": "",
        "remarques": "",
        "champs_addi": {},
    }

    def test_inscription_success(self):
        """
            - Appel de la route inscription qui écrit dans temp_user et renvoie un token
            - Récupératon du token pour valider le compte et le passer dans t_roles 
            - Vérification du JDD créé
        """
        # inscription
        response = post_json(
            self.client, url_for("users.inscription"), self.__class__.user_form
        )
        resp_json = json_of_response(response)
        assert response.status_code == 200

        # validation
        token = resp_json["token"]
        response = self.client.get(url_for("users.confirmation", token=token))

        # 302 redirect = success
        assert response.status_code == 302
        user = DB.session.query(User).filter_by(identifiant="hello_test").first()
        assert user is not None

        # verif du JDD
        jdd_actor = (
            DB.session.query(CorDatasetActor)
            .filter(CorDatasetActor.id_role == user.id_role)
            .first()
        )
        # vérif du CA
        assert jdd_actor is not None
        af_actor = (
            DB.session.query(CorAcquisitionFrameworkActor)
            .filter(CorAcquisitionFrameworkActor.id_role == user.id_role)
            .first()
        )
        assert af_actor is not None

    def test_inscirption_same_id(self):
        response = post_json(
            self.client, url_for("users.inscription"), self.__class__.user_form
        )
        resp_json = json_of_response(response)
        assert response.status_code == 400

    def test_inscirption_wrong_pass(self):
        user_form = self.__class__.user_form
        user_form["password_confirmation"] = "fake"
        response = post_json(self.client, url_for("users.inscription"), user_form)
        resp_json = json_of_response(response)
        assert response.status_code == 500

    def test_password_recovery(self):
        """
            - Création d'un token
            - Maj du mdp
        """
        data = {"email": "email_test@mail.com"}
        response = post_json(
            self.client,
            url_for("register.post_usershub", type_action="create_cor_role_token"),
            data,
        )

        json_resp = json_of_response(response)

        data = {
            "password": "new_pass",
            "password_confirmation": "new_pass",
            "token": json_resp["token"],
        }

        self.client.put(
            url_for("users.new_password"),
            data=json.dumps(data),
            content_type="application/json",
        )
        assert response.status_code == 200

        # todo: test sur le changement de mdp en mode connecté ne fonctionne pas...

