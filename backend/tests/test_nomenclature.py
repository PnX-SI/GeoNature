# '''
#     Test de l'api nomenclature
# '''


import pytest

from flask import url_for
from .bootstrap_test import app


@pytest.mark.usefixtures('client_class')
class TestAPINomenclature:

    def test_gn_nomenclature_get_by_mnemonique(self):
        query_string = {
            'regne': 'Animalia',
            'group2_inpn': 'Bivalves'
        }
        response = self.client.get(
            url_for(
                'nomenclatures.get_nomenclature_by_mnemonique_and_taxonomy',
                code_type='STADE_VIE'
            ),
            query_string=query_string
        )

        assert response.status_code == 200
