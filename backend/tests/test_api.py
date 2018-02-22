import requests

from .bootstrap_test import geonature_app

def run_request(url):
    return requests.get(url)


class TestApiUsersMenu:
    """
        Test de l'api users/menu
    """
    base_url = '{}/users/menu/{}'

    def test_menu_exists(self, geonature_app):
        print('test_menu_exists')
        response = run_request(
            self.base_url.format(geonature_app.config['API_ENDPOINT'], 10)
        )

        if response.ok:
            assert True
        else:
            assert False

    def test_menu_notexists(self, geonature_app):
        print('test_menu_notexists')
        response = run_request(
            self.base_url.format(geonature_app.config['API_ENDPOINT'], 123456)
        )
        if response.status_code == 404:
            assert True
        else:
            assert False


class TestApiReleve:
    token = None

    def getToken(self, base_url):
        response = requests.post(
            '{}/auth/login'.format(base_url),
            json={'login': "admin", 'password': "admin", 'id_application': 14, 'with_cruved': True}
        )
        self.token = response.cookies['token']


    def test_getToken(self, geonature_app):
        self.getToken(geonature_app.config['API_ENDPOINT'])

        if self.token:
            assert True
        else:
            assert False

    def test_getReleves(self, geonature_app):
        if not self.token:
            self.getToken(geonature_app.config['API_ENDPOINT'])

        response = requests.get(
            '{}/contact/releves'.format(geonature_app.config['API_ENDPOINT']),
            cookies={'token': self.token}
        )

        if response.ok:
            assert True
        else:
            assert False

