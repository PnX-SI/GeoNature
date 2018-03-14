import os
import requests

from .bootstrap_test import geonature_app
from geonature.core.gn_medias.repositories import TMediaRepository

class TestAPIMedias:

    def test_save_media(self, geonature_app):
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
            '{}/gn_medias/upload_file'.format(geonature_app.config['API_ENDPOINT']),
            data=data,
            files={'file': test_file}
        )
        if not response.ok:
            assert False
        if not os.path.isfile(os.path.join(
            geonature_app.config['BASE_DIR'],
            dict(response.json())['path']
        )):
            assert False
