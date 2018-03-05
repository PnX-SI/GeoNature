import requests

from .bootstrap_test import geonature_app, releve_data

def run_request(url):
    return requests.get(url)


class TestApiUsersMenu:
    """
        Test de l'api users/menu
    """
    base_url = '{}/users/menu/{}'

    def test_menu_exists(self, geonature_app):
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
        print('test_getToken')
        self.getToken(geonature_app.config['API_ENDPOINT'])

        if self.token:
            assert True
        else:
            assert False

    def test_getReleves(self, geonature_app):
        print('test_getReleves')
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

    def test_insertUpdateDeleteReleves(self, geonature_app, releve_data):

        if not self.token:
            self.getToken(geonature_app.config['API_ENDPOINT'])

        response = requests.post(
            '{}/contact/releve'.format(geonature_app.config['API_ENDPOINT']),
            json=releve_data,
            cookies={'token': self.token}
        )

        if not response.ok:
            assert False

        update_data = dict(response.json())
        update_data['properties'].pop('digitiser')
        update_data['properties']['comment'] = 'Super MODIIFF'

        response = requests.post(
            '{}/contact/releve'.format(geonature_app.config['API_ENDPOINT']),
            json=update_data,
            cookies={'token': self.token}
        )

        resp_data = dict(response.json())

        if not response.ok:
            assert False
        if resp_data['properties']['comment'] == 'Super MODIIFF':
            assert True

        response = requests.delete(
            '{}/contact/releve/{}'.format(
                geonature_app.config['API_ENDPOINT'],
                resp_data['properties']['id_releve_contact']
            ),
            cookies={'token': self.token}
        )

        if not response.ok:
            assert False

        assert True


    def test_get_export_sinp(self, geonature_app):
        if not self.token:
            self.getToken(geonature_app.config['API_ENDPOINT'])

        response = requests.get(
            '{}/contact/export/sinp'.format(geonature_app.config['API_ENDPOINT']),
            cookies={'token': self.token}
        )

        if response.ok:
            assert True
        else:
            assert False
