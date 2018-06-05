import pytest

from flask import url_for

from .bootstrap_test import app, post_json, json_of_response, get_token


@pytest.mark.usefixtures('client_class')
class TestGnMeta:
    def test_list_datasets(self):
        token = get_token(self.client)
        response = self.client.get(url_for('gn_meta.get_datasets_list'))
        assert response.status_code == 200

    def test_dataset_cruved(self):
        token = get_token(self.client)
        response = self.client.get(url_for('gn_meta.get_datasets'))
        print('LAAAAAAAAA')
        print(response)
        assert response.status_code == 200
        
        dataset_list = json_of_response(response)
        assert len(dataset_list) == 2


