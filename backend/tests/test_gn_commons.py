# '''
#     Test de l'api gn_media
# '''


import os
import json
import io
from pathlib import Path

import pytest
from flask import url_for
from sqlalchemy.sql import text

from .bootstrap_test import app, post_json, json_of_response, get_token


from geonature.core.gn_commons.repositories import TMediaRepository
from geonature.utils.env import BACKEND_DIR, DB
from geonature.utils.errors import GeoNatureError


@pytest.mark.usefixtures("client_class")
class TestAPIMedias:
    def _get_media(self, id_media):

        response = self.client.get('/gn_commons/media/' + str(id_media))
    
        assert response.status_code == 200

    def _save_media(self, config):
        sql = text("""SELECT ref_nomenclatures.get_id_nomenclature('TYPE_MEDIA', '2')""")
        result = DB.engine.execute(sql)
        for r in result:
            id_nomenclature_media = r[0]
        file_name = Path(BACKEND_DIR, 'tests/test.jpg')
        data = {
            "file": (open(file_name, 'rb'), "hello world.txt"),
            "isFile": True,
            "id_nomenclature_media_type": id_nomenclature_media,
            "id_table_location": 1,
            "uuid_attached_row": "cfecc9af-3949-44ab-bde5-8d1ecd1ab581",
            "title_fr": "Super test",
        }

        response = self.client.post(
            '/gn_commons/media',
            data=data,
            content_type="multipart/form-data",
        )

        assert response.status_code == 200

        media_data = json_of_response(response)

        if not os.path.isfile(os.path.join(config["BASE_DIR"], media_data["media_path"])):
            assert False

        return media_data

    def _update_media(self, data):
        data["isFile"] = False
        data["url"] = "http://codebasicshub.com/uploads/lang/py_pandas.png"
        response = post_json(
            self.client,
            '/gn_commons/media/' + str(data["id_media"]),
            data,
        )
        assert response.status_code == 200

    def _delete_media(self, id_media):
        response = self.client.delete(
        '/gn_commons/media/' + str(id_media),
        )
        # response = requests.delete(
        #     '{}/gn_commons/media/{}'.format(
        #         geonature_app.config['API_ENDPOINT'], id_media
        #     )
        # )
        assert response.status_code == 200

    def test_media_action(self, config):
        data = self._save_media(config)
        self._get_media(data["id_media"])
        self._update_media(data)
        self._get_media(data["id_media"])
        self._delete_media(data["id_media"])


@pytest.mark.usefixtures("client_class")
class TestAPIGNCommons:
    def _create_config_files(self):
        path_occtax = Path(BACKEND_DIR / "static/mobile/occtax")
        path_sync = Path(BACKEND_DIR / "static/mobile/sync")
        try:
            os.mkdir(str(path_occtax))
            os.mkdir(str(path_sync))
        except FileExistsError:
            print("Already exist")
        json_content = """
            {"la": "la"}
        """
        for _f in [path_occtax, path_sync]:
            with open(str(_f / "settings.json"), "w+") as f:
                f.write(json_content)

    def test_get_t_mobile_apps(self):
        self._create_config_files()
        #  with app code query string must return a dict
        url = url_for("gn_commons.get_t_mobile_apps")
        query_string = {"app_code": "OCCTAX"}
        response = self.client.get(
            url, query_string=query_string
        )
        assert response.status_code == 200
        data = json_of_response(response)
        assert type(data) is dict

        # with to app_code must return an array
        response = self.client.get(url)
        assert response.status_code == 200
        data = json_of_response(response)
        assert type(data) is list

    def test_module_orders(self):
        url = url_for("gn_commons.get_modules")
        token = get_token(self.client, login="admin", password="admin")
        self.client.set_cookie("/", "token", token)
        response = self.client.get(url)
        assert response.status_code == 200
        data = json_of_response(response)
        assert type(data) is list

        # test order by number
        assert data[0]["module_code"] == "SYNTHESE"
        assert data[1]["module_code"] == "OCCTAX"

        # test order by alphabetic
        previous_module = None
        for module in data[2 : len(data) - 1]:
            if previous_module:
                assert previous_module < module["module_label"].upper()
            previous_module = module["module_label"].upper()
