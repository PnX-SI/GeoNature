# '''
#     Test de l'api nomenclature
# '''


import pytest

from flask import url_for
from .bootstrap_test import app, json_of_response


@pytest.mark.usefixtures("client_class")
class TestAPINomenclature:
    def test_gn_nomenclature_get_by_mnemonique(self):
        query_string = {"regne": "Animalia", "group2_inpn": "Bivalves"}
        response = self.client.get(
            url_for(
                "nomenclatures.get_nomenclature_by_mnemonique_and_taxonomy", code_type="STADE_VIE",
            ),
            query_string=query_string,
        )

        assert response.status_code == 200

    def test_get_nomenclature_by_type_list(self):
        """
        Tests get nomenclatures avec une liste de code_type
        filtré par regne et groupe
        """

        # Avec des code_types
        query_string = """
        regne=Animalia&group2_inpn=Bivalves&code_type=TECHNIQUE_OBS&code_type=METH_OBS&code_type=ETA_BIO"""
        response = self.client.get(
            url_for("nomenclatures.get_nomenclature_by_type_list_and_taxonomy",),
            query_string=query_string,
        )
        data = json_of_response(response)
        assert response.status_code == 200
        assert len(data) == 3

        #  Sans id_type ni code type string => 404
        response = self.client.get(
            url_for("nomenclatures.get_nomenclature_by_type_list_and_taxonomy",)
        )
        assert response.status_code == 404
