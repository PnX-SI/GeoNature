'''
    Test de l'api gn_media
'''


import os
import requests

from .bootstrap_test import geonature_app
from geonature.core.gn_monitoring.models import TBaseSites
from geonature.core.gn_monitoring.config_manager import generate_config
from pypnnomenclature.models import TNomenclatures

from geonature.utils.env import DB

class TestAPICore:

    def test_gn_core_route_config(self, geonature_app):
        response = requests.get(
            '{}/config?app=test&vue=test'.format(
                geonature_app.config['API_ENDPOINT']
            )
        )
        if not response.ok:
            assert False
        assert True

    def test_gn_core_generic_view(self, geonature_app):
        response = requests.get(
            '{}/genericview/taxonomie/v_bibtaxon_attributs_animalia?cd_nom=18437&ilike_patrimonial=o'.format(
                geonature_app.config['API_ENDPOINT']
            )
        )
        if not response.ok:
            assert False
        assert True

