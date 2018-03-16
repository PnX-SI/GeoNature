'''
    Test de l'api gn_media
'''


import os
import requests

from .bootstrap_test import geonature_app
from geonature.core.gn_monitoring.models import TBaseSites

from geonature.utils.env import DB

class TestAPIMedias:

    def test_gn_monitoring_action(self, geonature_app):
        sites = DB.session.query(TBaseSites).all()
        for s in sites:
            print (s.as_dict(recursif=True))
        assert True
