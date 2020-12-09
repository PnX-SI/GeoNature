'''
    test pour l'api post synthese
    comme matiere a tester on prend des donnée issues de la synthese pour tester les différentes routes
    leur bon état de marche comme les erreurs attendues

    - recupération d'une donnée de la synthèse

    - test get pour les trois cas
      - id_synthese
      - uuid
      - id_source et entity_source_pk_value

    - test post d'un nouvelle donnée avec une donnée de la synthese
    - test patchs dans les 3 cas
    - test erreurs
      - source non définie
      - jdd dnon defini
    - test delete 
'''



from geonature.core.gn_synthese.exchanges.models import Synthese

import os

import json
import io
from pathlib import Path

import pytest
from flask import url_for
from sqlalchemy.sql import text
from sqlalchemy.sql.expression import cast

from .bootstrap_test import app, post_json, json_of_response, get_token

from geonature.core.gn_meta.models import TAcquisitionFramework, TDatasets
from geonature.utils.env import BACKEND_DIR, DB
from geonature.utils.errors import GeoNatureError

from copy import deepcopy

        # import pdb; pdb.set_trace()
@pytest.mark.usefixtures("client_class")
class TestAPIExchanges:

    _data_synthese=None

    def data_synthese(self):
        return deepcopy(self._data_synthese)
 
    def _get_synthese_sample(self):

        synthese = DB.session.query(Synthese).limit(1).one()
        id_synthese = synthese.id_synthese
        assert(id_synthese is not None)
 
        url_id_synthese = '/exchanges/synthese/{}'.format(id_synthese)
        response = self.client.get(url_id_synthese)
        assert(response.status_code == 200)
        self._data_synthese = json_of_response(response)
        assert(self._data_synthese['properties']['id_synthese'] == id_synthese)


        url_uuid = '/exchanges/synthese/{}'.format(self._data_synthese['properties']['unique_id_sinp'])
        response = self.client.get(url_uuid)
        assert(response.status_code == 200)
        response_data = json_of_response(response)
        assert(self._data_synthese['properties']['unique_id_sinp'] == response_data['properties']['unique_id_sinp'])

        url_source = '/exchanges/synthese/{}/{}'.format(self._data_synthese['properties']['id_source'], self._data_synthese['properties']['entity_source_pk_value'])
        response = self.client.get(url_source)
        assert(response.status_code == 200)
        response_data = json_of_response(response)
        assert(self._data_synthese['properties']['id_synthese'] == response_data['properties']['id_synthese'])

    def get_max_entity_source_pk_value(self):
        return  (
            DB.session.query(
                cast(Synthese.entity_source_pk_value, DB.Integer) + 1
                )
            .filter_by(id_source=self._data_synthese['properties']['id_source'])
            .order_by(
                cast(Synthese.entity_source_pk_value, DB.Integer)
                .desc()
            )
            .first()[0]
        )

    def _post_synthese(self):

        url_synthese = '/exchanges/synthese/'
        id_synthese = self._data_synthese['properties']['id_synthese']
        for key in ['id_synthese', 'unique_id_sinp']:
            del self._data_synthese['properties'][key]

        

        self._data_synthese['properties']['entity_source_pk_value'] = str(self.get_max_entity_source_pk_value())
        response = post_json(
            self.client,
            url_synthese,
            self._data_synthese
        )
        assert(response.status_code == 200)
        self._data_synthese = json_of_response(response)
        assert(self._data_synthese['properties']['id_synthese'] != id_synthese)
        assert(self._data_synthese['properties']['unique_id_sinp'] is not None)

    def _patch_synthese(self):

        id_synthese = self._data_synthese['properties']['id_synthese']
        url_id_synthese = '/exchanges/synthese/{}'.format(id_synthese)
        url_uuid = '/exchanges/synthese/{}'.format(self._data_synthese['properties']['unique_id_sinp'])
        url_source = '/exchanges/synthese/{}/{}'.format(self._data_synthese['properties']['id_source'], self._data_synthese['properties']['entity_source_pk_value'])
        
        # for key in ['id_synthese', 'unique_id_sinp']:
        #     del self._data_synthese['properties'][key]

        # response = self.client.patch(
        #     url_id_synthese,
        #     data=json.dumps(self._data_synthese),
        #     content_type="application/json",
        # )
        # assert(response.status_code == 200)
        # self._data_synthese = json_of_response(response)
        # assert(self._data_synthese['properties']['id_synthese'] == id_synthese)

        # id_synthese = self._data_synthese['properties']['id_synthese']
        # response = self.client.patch(
        #     url_uuid,
        #     data=json.dumps({'properties': {'count_max':100}}),
        #     content_type="application/json",
        # )
        # assert(response.status_code == 200)
        # self._data_synthese = json_of_response(response)
        # assert(self._data_synthese['properties']['count_max'] == 100)
        # assert(self._data_synthese['properties']['id_synthese'] == id_synthese)

        id_synthese = self._data_synthese['properties']['id_synthese']
        response = self.client.patch(
            url_source,
            data=json.dumps({'properties': {'count_max':10}}),
            content_type="application/json",
        )
        assert(response.status_code == 200)
        self._data_synthese = json_of_response(response)
        assert(self._data_synthese['properties']['id_synthese'] == id_synthese)
        assert(self._data_synthese['properties']['count_max'] == 10)


    def _delete_synthese(self):
        id_synthese = self._data_synthese['properties']['id_synthese']
        url_synthese = '/exchanges/synthese/{}'.format(self._data_synthese['properties']['id_synthese'])
        url_source = '/exchanges/synthese/{}/{}'.format(self._data_synthese['properties']['id_source'], self._data_synthese['properties']['entity_source_pk_value'])
        response = self.client.delete(
            url_source
        )
        assert(response.status_code == 200)
        response = self.client.get(
            url_synthese
        )
        assert(response.status_code != 200)



    def _errors_synthese(self):
        # erreur pour les patch selon plusieurs config
        url_synthese = '/exchanges/synthese/'
        url_source = '/exchanges/synthese/{}/{}'.format(self._data_synthese['properties']['id_source'], self._data_synthese['properties']['entity_source_pk_value'])

        # cd_nomenclature mal renseigné
        data_synthese = self.data_synthese()
        data_synthese['properties']['cd_nomenclature_geo_object_nature'] = "Ceci n'est pas un cd_nomenclature"
        response = self.client.patch(
            url_source,
            data=json.dumps(data_synthese),
            content_type="application/json",
        )
        assert(response.status_code != 200)
        code = json_of_response(response).get('code')
        assert(code == 1)


        # source n'existe pas
        data_synthese = self.data_synthese()
        del data_synthese['properties']['id_source']
        del data_synthese['properties']['id_synthese']
        del data_synthese['properties']['unique_id_sinp']
        response = self.client.post(
            url_synthese,
            data=json.dumps(data_synthese),
            content_type="application/json",
        )
        assert(response.status_code != 200)
        code = json_of_response(response).get('code')
        assert(code == 2)

        # jdd n'existe pas
        data_synthese = self.data_synthese()
        del data_synthese['properties']['id_dataset']
        del data_synthese['properties']['id_synthese']
        del data_synthese['properties']['unique_id_sinp']

        response = self.client.post(
            url_synthese,
            data=json.dumps(data_synthese),
            content_type="application/json",
        )
        assert(response != 200)
        code = json_of_response(response).get('code')
        assert(code == 3)

    def _full_cycle_test(self):

        # test d'un post avec creation source et jdd et delete du tout
        data_synthese = self.data_synthese()

        for key in ['unique_id_sinp', 'id_synthese', 'id_source', 'entity_source_pk_value']:
            del data_synthese['properties'][key] 

        # POST source
        url_source = '/exchanges/source/'
        data_source = {
            'name_source': 'Source test',
            'desc_source': 'Ceci est un source pour faire un test',
            'entity_source_pk_field': 'id_bidule',
            'url_source': '???'
        }
        response = post_json(
            self.client,
            url_source,
            data_source
        )
        assert(response.status_code == 200)
        source = json_of_response(response)

        # POST jdd
        id_acquisition_framework = DB.session.query(TAcquisitionFramework).limit(1).all()[0].id_acquisition_framework
        assert(id_acquisition_framework is not None)
        url_dataset = '/meta/dataset'
        data_dataset = {
            'id_acquisition_framework': id_acquisition_framework,
            'dataset_name': 'dataset de test',
            'dataset_shortname': 'dataset de test',
            'dataset_desc': 'dataset de test',
            'marine_domain': False,
            'terrestrial_domain': False,
            'cor_dataset_actor': [],
            'modules': [],
        }
        response = post_json(
            self.client,
            url_dataset,
            data_dataset
        )
        assert(response.status_code == 200)
        dataset = json_of_response(response)

        # POST synthese
        data_synthese['properties']['id_source'] = source['id_source']
        data_synthese['properties']['id_dataset'] = dataset['id_dataset']
        data_synthese['properties']['entity_source_pk_value'] = str(self.get_max_entity_source_pk_value())
        url_synthese = '/exchanges/synthese/'
        response = post_json(
            self.client,
            url_synthese,
            data_synthese
        )
        assert(response.status_code == 200)
        self._data_synthese = json_of_response(response)
        
        # DELETE synthese
        url_source = '/exchanges/synthese/{}/{}'.format(
            self._data_synthese['properties']['id_source'],
            self._data_synthese['properties']['entity_source_pk_value'])
        response = self.client.delete(url_source)
        assert(response.status_code == 200)
        response = self.client.get(url_source)
        assert(response.status_code != 200)

        # DELETE jdd

        url_dataset = url_dataset + "/" +  str(dataset['id_dataset'])
        DB.session.query(TDatasets).filter_by(id_dataset=dataset['id_dataset']).delete()
        DB.session.commit()
        # 
        # pas de route delete dataset  actuellement
        #
        # response = self.client.delete(url_dataset)
        # assert(response.status_code == 200)
        try:
            response = self.client.get(url_dataset)
            # erreur si pas d'erreur (dataset supprimé juste avant)
            assert(False)
        except:
            pass

        # DELETE source
        url_source = '/exchanges/source/' + str(source['id_source'])
        response = self.client.delete(url_source)
        assert(response.status_code == 200)
        response = self.client.get(url_source)
        assert(response.status_code != 200)




    def test_exchanges_action(self, config):
        token = get_token(self.client, login="admin", password="admin")
        self.client.set_cookie("/", "token", token)

        self._get_synthese_sample()
        self._post_synthese()
        self._patch_synthese()
        self._delete_synthese()
        self._errors_synthese()
        self._full_cycle_test()
