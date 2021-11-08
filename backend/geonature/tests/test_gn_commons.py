from datetime import datetime
from operator import and_
from uuid import uuid4
from geonature.core.gn_synthese.models import Synthese

import pytest 
from flask import url_for

from geonature.utils.env import DB

from geonature.core.gn_commons.models import TAdditionalFields
from geonature.core.gn_commons.models.base import TModules
from geonature.core.gn_meta.models import TDatasets
from geonature.core.gn_permissions.models import TObjects
from pypnnomenclature.models import TNomenclatures



from . import app, temporary_transaction, acquisition_frameworks, datasets, users, login, synthese_data

@pytest.fixture(scope='class')
def create_aditional_fields(app, datasets):
    module = TModules.query.filter(TModules.module_code == "SYNTHESE").one_or_none()
    object = TObjects.query.filter(TObjects.code_object == "ALL").one_or_none()
    dataset = TDatasets.query.filter(TDatasets.dataset_name == "test").all()
    field = {
        "field_name": "test",
        "field_label": "Un label",
        "required": True,
        "description": "une descrption",
        "quantitative": False,
        "unity": "degré C",
        "field_values": ["la", "li"],
        "id_widget": 1,
        "modules": [module],
        "objects": [object],
        "datasets": dataset
    }
    add_field = TAdditionalFields(**field)
    DB.session.add(add_field)



@pytest.mark.usefixtures(
    "client_class", "datasets",
    "create_aditional_fields", "temporary_transaction"
)
class TestCommons:
    def test_additional_data(self):
        query_string = {
            "module_code": "SYNTHESE",
            "object_code": "ALL"
        }
        response = self.client.get(
            url_for("gn_commons.get_additional_fields"),
            query_string=query_string
        )

        assert response.status_code == 200
        data = response.get_json()
        for f in data:
            for m in f["modules"]:
                assert m["module_code"] == "SYNTHESE"
            for o in f["objects"]:
                assert o["code_object"] == "ALL"
            for d in f["datasets"]:
                assert d["dataset_name"] == "test"

    def test_add_validation_status(self, synthese_data):
        login(self.client)
        synthese = next(synthese_data)
        id_nomenclature_valid_status = DB.session.query(TNomenclatures).filter(and_(
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

