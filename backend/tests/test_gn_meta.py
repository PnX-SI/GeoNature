import pytest

from flask import url_for, current_app

from .bootstrap_test import app, post_json, json_of_response, get_token

from geonature.core.users import routes as users


@pytest.mark.usefixtures('client_class')
class TestGnMeta:
    def test_list_datasets(self):
        """
        Api to get all datasets
        """
        #token = get_token(self.client)
        response = self.client.get(url_for('gn_meta.get_datasets_list'))
        assert response.status_code == 200

    def test_one_dataset(self):
        """
        API to get one dataset from id_dataset
        """
        response = self.client.get(url_for('gn_meta.get_dataset', id_dataset=1))
        assert response.status_code == 200

    def test_dataset_cruved_3(self):
        """
        API to get datasets with CRUVED authorization
        CRUVED right = 3
        """
        token = get_token(self.client)
        response = self.client.get(url_for('gn_meta.get_datasets'))
        assert response.status_code == 200

        dataset_list = json_of_response(response)
        assert len(dataset_list['data']) >= 2

    def test_dataset_cruved_2(self):
        """
        API to get datasets with CRUVED authorization
        CRUVED = 2
        """
        token = get_token(self.client, login="agent", password="admin")
        response = self.client.get(url_for('gn_meta.get_datasets'))
        dataset_list = json_of_response(response)
        assert (
            response.status_code == 200 and
            len(dataset_list['data']) == 1 and
            dataset_list['data'][0]['id_dataset'] == 2
        )

    def test_dataset_cruved_1(self):
        """
        API to get datasets with CRUVED authorization
        CRUVED = 1
        """
        token = get_token(self.client, login="partenaire", password="admin")
        response = self.client.get(url_for('gn_meta.get_datasets'))
        dataset_list = json_of_response(response)
        assert (
            response.status_code == 200 and
            len(dataset_list['data']) == 1 and
            dataset_list['data'][0]['id_dataset'] == 1
        )

    def test_mtd_interraction(self):
        from geonature.core.gn_meta.mtd_utils import post_jdd_from_user, get_jdd_by_user_id, parse_jdd_xml

        """
        Test du web service MTD
        A partir d'un utilisateur renvoyé par le CAS
        on insert l'utilisateur 'demo.geonature' et son organisme s'il existe pas
        puis on poste les CA et JDD renvoyé à le WS MTD
        """
        user = {
            "id_role": 10991,
            "identifiant": 'test.mtd',
            "nom_role": 'test_mtd',
            "prenom_role": 'test_mtd',
            "id_organisme": 104,
        }

        organism = {
            "id_organisme": 104,
            "nom_organisme": 'test'
        }
        resp = users.insert_organism(organism)
        assert resp.status_code == 200

        resp = users.insert_role(user)
        users.insert_in_cor_role(current_app.config['BDD']['ID_USER_SOCLE_1'], user['id_role'])
        assert resp.status_code == 200

        jdds = post_jdd_from_user(id_user=10991, id_organism=104)
        assert len(jdds) >= 1
