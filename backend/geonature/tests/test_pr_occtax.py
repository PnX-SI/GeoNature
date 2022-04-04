import pytest

from flask import url_for, current_app
from werkzeug.exceptions import Forbidden

from .utils import set_logged_user_cookie
from .fixtures import *

occtax = pytest.importorskip("occtax")

from occtax.models import DefaultNomenclaturesValue


@pytest.fixture()
def releve_data(client, datasets):
    """
    Releve associated with dataset created by "user"
    """
    id_dataset = datasets["own_dataset"].id_dataset
    id_nomenclature_grp_typ = (
        DefaultNomenclaturesValue.query.filter_by(mnemonique_type="TYP_GRP")
        .with_entities(DefaultNomenclaturesValue.id_nomenclature)
        .scalar()
    )
    data = {
        "depth": 2,
        "geometry": {
            "type": "Point",
            "coordinates": [3.428936004638672, 44.276611357355904],
        },
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

    return data


@pytest.mark.usefixtures("client_class", "temporary_transaction", "datasets")
class TestOcctax:
    def test_post_releve(self, users, releve_data):
        # post with cruved = C = 2
        set_logged_user_cookie(self.client, users["user"])
        response = self.client.post(url_for("pr_occtax.createReleve"), json=releve_data)
        assert response.status_code == 200

        set_logged_user_cookie(self.client, users["noright_user"])
        response = self.client.post(url_for("pr_occtax.createReleve"), json=releve_data)
        assert response.status_code == Forbidden.code

        # TODO : test update, test post occurrence

    def test_get_defaut_nomenclatures(self):
        response = self.client.get(url_for("pr_occtax.getDefaultNomenclatures"))
        assert response.status_code == 200
