from datetime import datetime
from uuid import uuid4

import pytest
from flask import url_for
from werkzeug.exceptions import Unauthorized, Forbidden, NotFound, Conflict
from sqlalchemy import func
from geoalchemy2.elements import WKTElement

from geonature.utils.env import db

from geonature.core.gn_commons.models import TAdditionalFields, TPlaces
from geonature.core.gn_commons.models.base import TModules
from geonature.core.gn_meta.models import TDatasets
from geonature.core.gn_permissions.models import TObjects
from geonature.core.gn_synthese.models import Synthese

from pypnnomenclature.models import TNomenclatures


from . import *
from .fixtures import *
from .utils import set_logged_user_cookie


@pytest.fixture(scope="function")
def place(users):
    place = TPlaces(place_name="test", role=users["user"])
    with db.session.begin_nested():
        db.session.add(place)
    return place


@pytest.fixture(scope="function")
def additional_field(app, datasets):
    module = TModules.query.filter(TModules.module_code == "SYNTHESE").one()
    obj = TObjects.query.filter(TObjects.code_object == "ALL").one()
    datasets = list(datasets.values())
    additional_field = TAdditionalFields(
        field_name="test",
        field_label="Un label",
        required=True,
        description="une descrption",
        quantitative=False,
        unity="degré C",
        field_values=["la", "li"],
        id_widget=1,
        modules=[module],
        objects=[obj],
        datasets=datasets,
    )
    with db.session.begin_nested():
        db.session.add(additional_field)
    return additional_field


@pytest.mark.usefixtures("client_class", "temporary_transaction")
class TestCommons:
    def test_list_modules(self, users):
        response = self.client.get(url_for("gn_commons.list_modules"))
        assert response.status_code == Unauthorized.code

        set_logged_user_cookie(self.client, users["noright_user"])
        response = self.client.get(url_for("gn_commons.list_modules"))
        assert response.status_code == 200
        assert len(response.json) == 0

        set_logged_user_cookie(self.client, users["admin_user"])
        response = self.client.get(url_for("gn_commons.list_modules"))
        assert response.status_code == 200
        assert len(response.json) > 0

    def test_list_places(self, place, users):
        response = self.client.get(url_for("gn_commons.list_places"))
        assert response.status_code == Unauthorized.code

        set_logged_user_cookie(self.client, users["user"])
        response = self.client.get(url_for("gn_commons.list_places"))
        assert response.status_code == 200
        assert place.id_place in [p["properties"]["id_place"] for p in response.json]

        set_logged_user_cookie(self.client, users["associate_user"])
        response = self.client.get(url_for("gn_commons.list_places"))
        assert response.status_code == 200
        assert place.id_place not in [p["properties"]["id_place"] for p in response.json]

    def test_add_place(self, users):
        place = TPlaces(
            place_name="test",
            place_geom=WKTElement("POINT (6.058788299560547 44.740515073054915)", srid=4326),
        )
        geofeature = place.as_geofeature()

        response = self.client.post(url_for("gn_commons.add_place"))
        assert response.status_code == Unauthorized.code

        set_logged_user_cookie(self.client, users["noright_user"])
        response = self.client.post(url_for("gn_commons.add_place"))
        assert response.status_code == Forbidden.code

        set_logged_user_cookie(self.client, users["user"])
        response = self.client.post(url_for("gn_commons.add_place"), data=geofeature)
        assert response.status_code == 200
        assert db.session.query(
            TPlaces.query.filter_by(
                place_name=place.place_name, id_role=users["user"].id_role
            ).exists()
        ).scalar()

        set_logged_user_cookie(self.client, users["user"])
        response = self.client.post(url_for("gn_commons.add_place"), data=geofeature)
        assert response.status_code == Conflict.code

    def test_delete_place(self, place, users):
        unexisting_id = db.session.query(func.max(TPlaces.id_place)).scalar() + 1
        response = self.client.delete(url_for("gn_commons.delete_place", id_place=unexisting_id))
        assert response.status_code == Unauthorized.code

        set_logged_user_cookie(self.client, users["associate_user"])
        response = self.client.delete(url_for("gn_commons.delete_place", id_place=unexisting_id))
        assert response.status_code == NotFound.code

        response = self.client.delete(url_for("gn_commons.delete_place", id_place=place.id_place))
        assert response.status_code == Forbidden.code

        set_logged_user_cookie(self.client, users["user"])
        response = self.client.delete(url_for("gn_commons.delete_place", id_place=place.id_place))
        assert response.status_code == 204
        assert not db.session.query(
            TPlaces.query.filter_by(id_place=place.id_place).exists()
        ).scalar()

    def test_additional_data(self, datasets, additional_field):
        query_string = {"module_code": "SYNTHESE", "object_code": "ALL"}
        response = self.client.get(
            url_for("gn_commons.get_additional_fields"), query_string=query_string
        )

        assert response.status_code == 200
        data = response.get_json()
        for f in data:
            for m in f["modules"]:
                assert m["module_code"] == "SYNTHESE"
            for o in f["objects"]:
                assert o["code_object"] == "ALL"
            assert {d["id_dataset"] for d in f["datasets"]} == {
                d.id_dataset for d in datasets.values()
            }
        # check mandatory column are here
        addi_one = data[0]
        assert "type_widget" in addi_one
        assert "bib_nomenclature_type" in addi_one
