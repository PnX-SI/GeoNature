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

    def test_get_all_nomenclatures_with_taxo(self):
        """
        Route use for build nomenclature for mobile
        """
        response = self.client.get(url_for("nomenclatures.get_nomenclature_with_taxonomy_list"))
        data = json_of_response(response)
        nomenclature_type = data[0]
        mandatory_attr = ["id_type", "mnemonique", "label_default", "nomenclatures"]
        for attr in mandatory_attr:
            assert attr in nomenclature_type
        assert type(nomenclature_type["nomenclatures"]) is list
        nomenclature_item = nomenclature_type["nomenclatures"][0]
        mandatory_attr = [
            "id_nomenclature",
            "cd_nomenclature",
            "hierarchy",
            "label_default",
            "taxref",
        ]
        for attr in mandatory_attr:
            assert attr in nomenclature_item
        # find a nomenclature type with taxref coresp
        nom_type_with_taxref = None
        for nom_typ in data:
            if nom_typ["mnemonique"] == "METH_DETERMIN":
                nom_type_with_taxref = nom_typ
        nom_item_with_taxref = None
        if nom_type_with_taxref:
            for nom_item in nom_type_with_taxref["nomenclatures"]:
                print(nom_item)
                if len(nom_item["taxref"]) > 0:
                    nom_item_with_taxref = nom_item["taxref"]
            if nom_item_with_taxref:
                mandatory_attr = ["regne", "group2_inpn"]
                for attr in mandatory_attr:
                    assert attr in nom_item_with_taxref[0]
