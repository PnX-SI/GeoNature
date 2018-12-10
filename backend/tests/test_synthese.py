from flask import current_app

import pytest

from flask import url_for, current_app

from .bootstrap_test import app, post_json, json_of_response, get_token

@pytest.mark.usefixtures('client_class')
class TestSynthese:
    def test_list_sources(self):
        response = self.client.get(
            url_for('gn_synthese.get_sources')
        )

        assert response.status_code == 200


    def test_get_defaut_nomenclature(self):
        response = self.client.get(
            url_for('gn_synthese.getDefaultsNomenclatures')
        )
        assert response.status_code == 200
         

    def test_get_synthese_data(self):
        token = get_token(self.client)
        self.client.set_cookie('/', 'token', token)
        # test on synonymy and taxref attrs
        query_string = {
            'cd_ref': 209902,
            'taxhub_attribut_102': 'eau',
            'taxonomy_group2_inpn': 'Insectes',
            'taxonomy_id_hab': 3
        }
        response = self.client.get(
            url_for('gn_synthese.get_synthese'),
            query_string=query_string
        )
        data = json_of_response(response)
        assert len(data['data']['features']) == 1
        assert data['data']['features'][0]['properties']['cd_nom'] == 713776
        assert response.status_code == 200


        # test geometry filters
        key_municipality = 'area_'+str(current_app.config['BDD']['id_area_type_municipality'])
        query_string = {        
            'geoIntersection': 
                """
                POLYGON ((5.580368041992188 43.42100882994726, 5.580368041992188 45.30580259943578, 8.12919616699219 45.30580259943578, 8.12919616699219 43.42100882994726, 5.580368041992188 43.42100882994726))
                """,
            key_municipality: 294

        }
        response = self.client.get(
            url_for('gn_synthese.get_synthese'),
            query_string=query_string
        )
        data = json_of_response(response)
        assert len(data['data']['features']) >= 2

    def test_get_synthese_data_cruved(self):
        # test cruved
        token = get_token(self.client, login="partenaire", password="admin")
        self.client.set_cookie('/', 'token', token)

        response = self.client.get(
            url_for('gn_synthese.get_synthese')
        )
        data = json_of_response(response)

        assert len(data['data']['features']) == 0
        assert response.status_code == 200


    def test_export(self):
        token = get_token(self.client, login="admin", password="admin")
        self.client.set_cookie('/', 'token', token)

        # csv
        response = self.client.get(
            url_for('gn_synthese.export'),
            query_string={'export_format': 'csv'}
        )
        assert response.status_code == 200 

        response = self.client.get(
            url_for('gn_synthese.export'),
            query_string={'export_format': 'geojson'}
        )
        assert response.status_code == 200 

        response = self.client.get(
            url_for('gn_synthese.export'),
            query_string={'export_format': 'shapefile'}
        )
        assert response.status_code == 200 









    
