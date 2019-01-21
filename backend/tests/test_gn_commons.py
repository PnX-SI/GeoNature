# '''
#     Test de l'api gn_media
# '''


# import os
# import json
# import io

# import pytest
# from flask import url_for
# from sqlalchemy.sql import text

# from .bootstrap_test import app, post_json, json_of_response


# from geonature.core.gn_commons.repositories import TMediaRepository
# from geonature.utils.env import BACKEND_DIR, DB

# @pytest.mark.usefixtures('client_class')
# class TestAPIMedias:

#     def _get_media(self, id_media):
#         response = self.client.get(
#             url_for('gn_commons.get_media', id_media=id_media)
#         )

#         assert response.status_code == 200

#     def _save_media(self, config):
#         sql = text(
#         """SELECT ref_nomenclatures.get_id_nomenclature('TYPE_MEDIA', '2')"""
#         )
#         result = DB.engine.execute(sql)
#         for r in result:
#             id_nomenclature_media = r[0]
#         data = {
#             'file': (io.BytesIO(b'my file contents'), 'hello world.txt'),
#             "isFile": True,
#             "id_nomenclature_media_type": id_nomenclature_media,
#             "id_table_location": 1,
#             "uuid_attached_row": "cfecc9af-3949-44ab-bde5-8d1ecd1ab581",
#             "title_fr": "Super test"
#         }

#         response = self.client.post(
#             url_for('gn_commons.insert_or_update_media',),
#             data=data,
#             content_type='multipart/form-data'
#         )

#         assert response.status_code == 200


#         media_data = json_of_response(response)

#         if not os.path.isfile(os.path.join(
#             config['BASE_DIR'],
#             media_data['media_path']
#         )):
#             assert False
        
#         return media_data

#     def _update_media(self, data):
#         data['isFile'] = False
#         data['url'] = 'http://codebasicshub.com/uploads/lang/py_pandas.png'
#         response = post_json(
#             self.client,
#             url_for('gn_commons.insert_or_update_media', id_media=data['id_media']),
#             data
#         )
#         assert response.status_code == 200

#     def _delete_media(self, id_media):
#         response = self.client.delete(
#             url_for('gn_commons.insert_or_update_media', id_media=id_media),
#         )
#         # response = requests.delete(
#         #     '{}/gn_commons/media/{}'.format(
#         #         geonature_app.config['API_ENDPOINT'], id_media
#         #     )
#         # )
#         assert response.status_code == 200

#     def test_media_action(self, config):
#         data = self._save_media(config)
#         self._get_media(data['id_media'])
#         self._update_media(data)
#         self._get_media(data['id_media'])
#         self._delete_media(data['id_media'])
