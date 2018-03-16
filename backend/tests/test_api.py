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


class TestApiModulePrConcact:
    """
        Test de l'api du module pr_contact
    """

    def get_token(self, base_url, login="admin", password="admin"):
        response = requests.post(
            '{}/auth/login'.format(base_url),
            json={
                'login': login,
                'password': password,
                'id_application': 14,
                'with_cruved': True
            }
        )
        if response.ok:
            return response.cookies['token']
        else:
            raise Exception('Invalid login {}, {}'.format(login, password))

    def test_get_token(self, geonature_app):
        token = self.get_token(geonature_app.config['API_ENDPOINT'])

        if token:
            assert True
        else:
            assert False

    def test_get_releves(self, geonature_app):
        token = self.get_token(geonature_app.config['API_ENDPOINT'])

        response = requests.get(
            '{}/occtax/releves'.format(geonature_app.config['API_ENDPOINT']),
            cookies={'token': token}
        )

        if response.ok:
            assert True
        else:
            assert False

    def test_insert_update_delete_releves(self, geonature_app, releve_data):
        token = self.get_token(geonature_app.config['API_ENDPOINT'])

        response = requests.post(
            '{}/occtax/releve'.format(geonature_app.config['API_ENDPOINT']),
            json=releve_data,
            cookies={'token': token}
        )

        if not response.ok:
            assert False

        update_data = dict(response.json())
        update_data['properties'].pop('digitiser')
        update_data['properties']['comment'] = 'Super MODIIFF'

        response = requests.post(
            '{}/occtax/releve'.format(geonature_app.config['API_ENDPOINT']),
            json=update_data,
            cookies={'token': token}
        )

        resp_data = dict(response.json())

        if not response.ok:
            assert False
        if resp_data['properties']['comment'] == 'Super MODIIFF':
            assert True

        response = requests.delete(
            '{}/occtax/releve/{}'.format(
                geonature_app.config['API_ENDPOINT'],
                resp_data['properties']['id_releve_contact']
            ),
            cookies={'token': token}
        )

        if not response.ok:
            assert False

        assert True

    def test_get_export_sinp(self, geonature_app):
        token = self.get_token(geonature_app.config['API_ENDPOINT'])

        response = requests.get(
            '{}/occtax/export/sinp'.format(geonature_app.config['API_ENDPOINT']),
            cookies={'token': token}
        )

        if response.ok:
            assert True
        else:
            assert False

    # ## Test des droits ####
    def test_user_can_get_releve(self, geonature_app):
        """
            user admin is observer of releve 1
        """
        token = self.get_token(
            geonature_app.config['API_ENDPOINT'],
            login="admin",
            password="admin"
        )
        response = requests.get(
            '{}/occtax/releve/1'.format(geonature_app.config['API_ENDPOINT']),
            cookies={'token': token}
        )
        assert response.status_code == 200

    def test_user_cannot_get_releve(self, geonature_app):
        """
            user agent is not observer, digitiser
            or in cor_dataset_actor
        """
        token = self.get_token(
            geonature_app.config['API_ENDPOINT'],
            login="agent",
            password="admin"
        )
        response = requests.get(
            '{}/occtax/releve/1'.format(geonature_app.config['API_ENDPOINT']),
            cookies={'token': token}
        )
        assert response.status_code == 403

    def test_user_cannot_delete_releve(self, geonature_app):
        """
            user agent is not observer, digitiser
            or in cor_dataset_actor
        """
        token = self.get_token(
            geonature_app.config['API_ENDPOINT'],
            login="agent",
            password="admin"
        )
        response = requests.delete(
            '{}/occtax/releve/1'.format(geonature_app.config['API_ENDPOINT']),
            cookies={'token': token}
        )
        assert response.status_code == 403
