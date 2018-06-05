import pytest

from flask import url_for

from .bootstrap_test import app, post_json, json_of_response, get_token


@pytest.mark.usefixtures('client_class')
class TestGnMeta:
    def test_list_datasets(self):
        """
        Api to get all datasets
        """
        token = get_token(self.client)
        response = self.client.get(url_for('gn_meta.get_datasets_list'))
        assert response.status_code == 200

    def test_dataset_cruved(self):
        """
        API to get datasets with CRUVED authorization
        """
        token = get_token(self.client)
        response = self.client.get(url_for('gn_meta.get_datasets'))
        print(response)
        assert response.status_code == 200
        
        dataset_list = json_of_response(response)
        assert len(dataset_list) == 2

        token = get_token(self.client, login="agent", password="admin")
        response = self.client.get(url_for('gn_meta.get_datasets'))
        dataset_list = json_of_response(response)
        assert (
            response.status_code == 200 and
            len(dataset_list) == 1 and
            dataset_list[0]['id_dataset'] == 2
        )

        token = get_token(self.client, login="partenaire", password="admin")
        response = self.client.get(url_for('gn_meta.get_datasets'))
        dataset_list = json_of_response(response)
        assert (
            response.status_code == 200 and
            len(dataset_list) == 1 and
            dataset_list[0]['id_dataset'] == 1
        )
        
        
        


