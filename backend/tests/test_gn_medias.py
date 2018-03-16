'''
    Test de l'api gn_media
'''


import os
import requests

from .bootstrap_test import geonature_app
from geonature.core.gn_medias.repositories import TMediaRepository


class TestAPIMedias:

    def _get_media(self, geonature_app, id_media):
        response = requests.get(
            '{}/gn_medias/{}'.format(
                geonature_app.config['API_ENDPOINT'], id_media
            )
        )
        if not response.ok:
            assert False

    def _save_media(self, geonature_app):
        test_file = open(
            os.path.join(os.path.dirname('.'), 'bootstrap_test.py'),
            'rb'
        )
        data = {
            "isFile": True,
            "title_fr": "Super test",
            "id_type": 2,
            "entity_name": "gn_monitoring.t_base_sites.id_base_site",
            "entity_value": -1
        }
        response = requests.post(
            '{}/gn_medias/'.format(geonature_app.config['API_ENDPOINT']),
            data=data,
            files={'file': test_file}
        )
        media_data = dict(response.json())
        if not response.ok:
            assert False
        if not os.path.isfile(os.path.join(
            geonature_app.config['BASE_DIR'],
            media_data['path']
        )):
            assert False
        return media_data

    def _update_media(self, geonature_app, data):
        data['isFile'] = False
        data['url'] = 'http://codebasicshub.com/uploads/lang/py_pandas.png'
        response = requests.post(
            '{}/gn_medias/{}'.format(
                geonature_app.config['API_ENDPOINT'], data['id_media']
            ),
            data=data
        )
        if not response.ok:
            assert False

    def _delete_media(self, geonature_app, id_media):
        response = requests.delete(
            '{}/gn_medias/{}'.format(
                geonature_app.config['API_ENDPOINT'], id_media
            )
        )
        if not response.ok:
            assert False

    def test_media_action(self, geonature_app):
        data = self._save_media(geonature_app)
        self._get_media(geonature_app, data['id_media'])
        self._update_media(geonature_app, data)
        self._get_media(geonature_app, data['id_media'])
        self._delete_media(geonature_app, data['id_media'])
        self._get_media(geonature_app, data['id_media'])
