from datetime import datetime
from uuid import uuid4

import pytest 
from flask import url_for

from geonature.utils.env import db

from geonature.core.gn_commons.models import TAdditionalFields
from geonature.core.gn_commons.models.base import TModules
from geonature.core.gn_meta.models import TDatasets
from geonature.core.gn_permissions.models import TObjects
from geonature.core.gn_synthese.models import Synthese

from pypnnomenclature.models import TNomenclatures


from . import *
from .fixtures import *


@pytest.fixture(scope='class')
def create_additional_fields(app, datasets):
    module = TModules.query.filter(TModules.module_code == "SYNTHESE").one()
    obj = TObjects.query.filter(TObjects.code_object == "ALL").one()
    dataset = list(datasets.values())
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
        "objects": [obj],
        "datasets": dataset
    }
    add_field = TAdditionalFields(**field)
    with db.session.begin_nested():
        db.session.add(add_field)


@pytest.mark.usefixtures(
    "client_class", "datasets",
    "create_additional_fields", "temporary_transaction"
)
class TestCommons:
    def test_additional_data(self, datasets):
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
            assert({ d['id_dataset'] for d in f["datasets"] } == { d.id_dataset for d in datasets.values() })
