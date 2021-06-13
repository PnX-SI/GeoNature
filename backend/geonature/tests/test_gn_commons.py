import pytest 

from geonature.utils.env import DB

from geonature.core.gn_commons.models import TAdditionalFields
from geonature.core.gn_commons.models.base import TModules
from geonature.core.gn_meta.models import TDatasets
from geonature.core.gn_permissions.models import TObjects

from flask import url_for

from . import app, temporary_transaction, datasets, users

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
    "client_class", "temporary_transaction", "datasets",
    "create_aditional_fields"
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

