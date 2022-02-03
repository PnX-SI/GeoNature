import pytest

from datetime import datetime as dt

from flask import url_for, current_app
from werkzeug.exceptions import Forbidden

from geonature.utils.env import db
from .utils import set_logged_user_cookie
from .fixtures import *

from occtax.models import DefaultNomenclaturesValue, TRelevesOccurrence


occtax = pytest.importorskip("occtax")



@pytest.fixture()
def releve_data(client, datasets):
    """
        Releve associated with dataset created by "user"
    """
    id_dataset = datasets["own_dataset"].id_dataset
    id_nomenclature_grp_typ = (
        DefaultNomenclaturesValue.query
        .filter_by(mnemonique_type='TYP_GRP')
        .with_entities(DefaultNomenclaturesValue.id_nomenclature)
        .scalar()
    )

    return {
        "depth": 2,
        "geometry": {"type": "Point", "coordinates": [3.428936004638672, 44.276611357355904],},
        "properties": {
            "id_dataset": id_dataset,
            "id_digitiser": 1,
            "date_min": "2018-03-02",
            "date_max": "2018-03-02",
            "hour_min": None,
            "hour_max": None,
            "altitude_min": None,
            "altitude_max": None,
            "meta_device_entry": "web",
            "comment": None,
            "observers": [1],
            "observers_txt": "tatatato",
            "id_nomenclature_grp_typ": id_nomenclature_grp_typ,
        },
    }


@pytest.fixture()
def releve(client, module, datasets):
    id_nomenclature_grp_typ = (
        DefaultNomenclaturesValue.query
        .filter_by(mnemonique_type='TYP_GRP')
        .with_entities(DefaultNomenclaturesValue.id_nomenclature)
        .scalar()
    )
    with db.session.begin_nested():
        releve_1 = TRelevesOccurrence(
            date_min=dt.now(),
            date_max=dt.now(),
            id_module=module.id_module,
            id_dataset=datasets["with_module_1"].id_dataset,
            id_nomenclature_grp_typ=id_nomenclature_grp_typ
        )
        db.session.add(releve_1)

    


@pytest.mark.usefixtures("client_class", "temporary_transaction", "datasets")
class TestOcctax:
    def test_post_releve_in_occtax(self, users, releve_data):
        # post with cruved = C = 2
        set_logged_user_cookie(self.client, users['user'])
        response = self.client.post(
            url_for("pr_occtax.createReleve"),
            json=releve_data
        )
        assert response.status_code == 200
        data = response.json

    def test_post_releve_in_module_bis(self, users, releve_data, module):
        # post with cruved = C = 2
        set_logged_user_cookie(self.client, users['user'])
        response = self.client.post(
            url_for("pr_occtax.createReleve", module_code=module.module_code),
            json=releve_data
        )
        assert response.status_code == 200
        data = response.json
        # assert False
        assert data["properties"]["id_module"] == module.id_module

        set_logged_user_cookie(self.client, users['noright_user'])
        
        response = self.client.post(
            url_for("pr_occtax.createReleve"),
            json=releve_data
        )
        assert response.status_code == Forbidden.code

        #TODO : test update, test post occurrence

    def test_get_defaut_nomenclatures(self):
        response = self.client.get(url_for("pr_occtax.getDefaultNomenclatures"))
        assert response.status_code == 200

    def test_get_releves(self, users, module, datasets, releve):
        set_logged_user_cookie(self.client, users['user'])

        # get occtax data of OCCTAX_DS module
        # must return only releve of dataset of 'own_dataset'
        response = self.client.get(
            url_for("pr_occtax.getReleves", module_code=module.module_code),
        )
        assert response.status_code == 200
        assert len(response.json["items"]["features"]) == 1
        for r in response.json["items"]["features"]:
            assert r["properties"]["id_dataset"] == datasets["with_module_1"].id_dataset

        # get occtax data of 'Occtax' module must be empty
        response = self.client.get(
            url_for("pr_occtax.getReleves"),
        )
        assert response.status_code == 200
        assert len(response.json["items"]["features"]) == 0

