# '''
#     Test de l'api gn_media
# '''


import pytest

from flask import url_for
from .bootstrap_test import app
from geonature.core.gn_monitoring.models import TBaseSites
from geonature.core.gn_monitoring.config_manager import generate_config
from pypnnomenclature.models import TNomenclatures

from geonature.utils.env import DB

@pytest.mark.usefixtures('client_class')
class TestAPICore:

    # TODO: revoie ce test, ne comprend pas ce qu'il fait
    
    # def test_gn_core_route_config(self):
    #     response = self.client.get(
    #       url_for('core.get_config')
    #     )
    #     query_string= {
    #       'app':'test',
    #       'vue':'test'
    #     }
    #     # response = requests.get(
    #     #     '{}/config?app=test&vue=test'.format(
    #     #         geonature_app.config['API_ENDPOINT']
    #     #     )
    #     # )
    #     assert response.status_code == 200


    def test_gn_core_generic_view(self):
        query_string = {
            'cd_nom':60612,
            'ilike_lb_nom':'Ly'
        }
        response = self.client.get(
          url_for(
            'core.get_generic_view',
            view_schema='gn_synthese',
            view_name='v_synthese_for_web_app'
          ),
          query_string=query_string
        )
        assert response.status_code == 200


