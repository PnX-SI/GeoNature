import pytest
from datetime import datetime
import sqlalchemy as sa
from flask import url_for

from . import *
from .fixtures import *

from geonature.core.gn_synthese.models import Synthese

from pypnnomenclature.models import TNomenclatures

gn_module_validation = pytest.importorskip("gn_module_validation")


@pytest.mark.usefixtures("client_class", "temporary_transaction", "app")
class TestValidation:
    def test_add_validation_status(self, synthese_data):
        login(self.client)
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
