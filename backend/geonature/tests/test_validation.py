import pytest
from datetime import datetime
import sqlalchemy as sa
from flask import url_for
from werkzeug.exceptions import Unauthorized

from . import *
from .fixtures import *
from .utils import set_logged_user_cookie

from geonature.core.gn_synthese.models import Synthese

from pypnnomenclature.models import TNomenclatures

gn_module_validation = pytest.importorskip("gn_module_validation")


@pytest.mark.usefixtures("client_class", "temporary_transaction", "app")
class TestValidation:
    def test_get_synthese_data(self, users, synthese_data):
        response = self.client.get(url_for("validation.get_synthese_data"))
        assert response.status_code == Unauthorized.code
        set_logged_user_cookie(self.client, users['user'])
        response = self.client.get(url_for("validation.get_synthese_data"))
        assert response.status_code == 200
        assert response.json['nb_total'] >= len(synthese_data)

    def test_get_status_names(self, users, synthese_data):
        response = self.client.get(url_for("validation.get_statusNames"))
        assert response.status_code == Unauthorized.code
        set_logged_user_cookie(self.client, users['user'])
        response = self.client.get(url_for("validation.get_statusNames"))
        assert response.status_code == 200

    def test_add_validation_status(self, users, synthese_data):
        set_logged_user_cookie(self.client, users['user'])
        synthese = synthese_data[0]
        id_nomenclature_valid_status = TNomenclatures.query.filter(sa.and_(
            TNomenclatures.cd_nomenclature == "1",
            TNomenclatures.nomenclature_type.has(mnemonique="STATUT_VALID")
        )).one()

        data = {
            "statut": id_nomenclature_valid_status.id_nomenclature,
            "comment": "lala",
            "validation_date": str(datetime.now()),
            "validation_auto": True
        }
        response = self.client.post(
            url_for("validation.post_status", id_synthese=synthese.id_synthese),
            data=data
        )
        assert response.status_code == 200

    def test_get_validation_date(self, synthese_data):
        s = synthese_data[0]
        response = self.client.get(url_for("validation.get_validation_date", uuid=s.unique_id_sinp))
        assert response.status_code == 404
        # TODO
