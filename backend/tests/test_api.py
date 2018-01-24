import requests

from .bootstrap_test import geonature_app


class TestApiUsersMenu:
    """
        Test de l'api users/menu
    """
    def run_request(self, url, id_menu):
        base_url = '{}/users/menu/{}'
        url = base_url.format(url, id_menu)
        return requests.get(url)

    def test_menu_exists(self, geonature_app):
        print('test_menu_exists')
        response = self.run_request(geonature_app.config['API_ENDPOINT'], 10)

        if response.ok:
            assert True
        else:
            assert False

    def test_menu_notexists(self, geonature_app):
        print('test_menu_notexists')
        response = self.run_request(geonature_app.config['API_ENDPOINT'], 123456)
        if response.status_code == 404:
            assert True
        else:
            assert False
