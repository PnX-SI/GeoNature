from inspect import Parameter
import pytest

from flask import url_for, current_app
from werkzeug.exceptions import Forbidden, NotFound
from shapely.geometry import Point
from geoalchemy2.shape import from_shape
from sqlalchemy import func

from geonature.core.gn_permissions.models import VUsersPermissions
from geonature.utils.env import db
from .utils import set_logged_user_cookie
from .fixtures import *

occtax = pytest.importorskip("occtax")

from occtax.models import DefaultNomenclaturesValue, TRelevesOccurrence
from occtax.repositories import ReleveRepository

# FIXME: not importable due to current app
#   from occtax.schemas import ReleveSchema
#   Fallback: using TRelevesOccurrence...


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
            "altitude_min": 1000,
            "altitude_max": 1200,
            "meta_device_entry": "web",
            "comment": None,
            "observers": [1],
            "observers_txt": "tatatato",
            "id_nomenclature_grp_typ": id_nomenclature_grp_typ,
        },
    }

    return data


@pytest.fixture(scope="function")
def releve(app, users, releve_data):
    data = releve_data["properties"]
    coords = releve_data["geometry"]["coordinates"]
    data["geom_4326"] = from_shape(Point(coords[0], coords[1]), srid=4326)
    # FIXME use ReleveSchema when importable
    releve_db = TRelevesOccurrence(
        id_dataset=data["id_dataset"],
        id_digitiser=data["id_digitiser"],
        date_min=data["date_min"],
        date_max=data["date_max"],
        hour_min=data["hour_min"],
        hour_max=data["hour_max"],
        altitude_min=data["altitude_min"],
        altitude_max=data["altitude_max"],
        meta_device_entry=data["meta_device_entry"],
        comment=data["comment"],
        observers=[users["user"]],
        observers_txt=data["observers_txt"],
        id_nomenclature_grp_typ=data["id_nomenclature_grp_typ"],
        geom_4326=data["geom_4326"],
    )

    with db.session.begin_nested():
        db.session.add(releve_db)

    return releve_db


@pytest.fixture(scope="function")
def unexisting_id_releve():
    return (db.session.query(func.max(TRelevesOccurrence.id_releve_occtax)).scalar() or 0) + 1


@pytest.fixture(scope="function")
def permission(users):
    return db.session.query(VUsersPermissions).filter_by(id_role=users["user"].id_role).first()


@pytest.mark.usefixtures("client_class", "temporary_transaction", "datasets")
class TestOcctax:
    def test_get_releve(self, users, releve):
        set_logged_user_cookie(self.client, users["user"])

        response = self.client.get(url_for("pr_occtax.getReleves"))

        assert response.status_code == 200
        json_resp = response.json
        assert json_resp["total"] >= 1
        assert releve.id_releve_occtax in [
            int(releve_json["id"]) for releve_json in json_resp["items"]["features"]
        ]

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


@pytest.mark.usefixtures("client_class", "temporary_transaction")
class TestOcctaxGetReleveFilter:
    def test_get_releve_filter_observers_not_present(self, users, releve):
        query_string = {"observers": [users["admin_user"].id_role]}

        set_logged_user_cookie(self.client, users["user"])

        response = self.client.get(url_for("pr_occtax.getReleves"), query_string=query_string)

        assert response.status_code == 200
        json_resp = response.json
        assert releve.id_releve_occtax not in [
            int(releve_json["id"]) for releve_json in json_resp["items"]["features"]
        ]

    def test_get_releve_filter_observers(self, users, releve):
        query_string = {"observers": [users["user"].id_role]}

        set_logged_user_cookie(self.client, users["user"])

        response = self.client.get(url_for("pr_occtax.getReleves"), query_string=query_string)

        assert response.status_code == 200
        json_resp = response.json
        assert releve.id_releve_occtax in [
            int(releve_json["id"]) for releve_json in json_resp["items"]["features"]
        ]

    def test_get_releve_filter_altitude_min(self, users, releve):
        query_string = {"altitude_min": releve.altitude_min - 1}

        set_logged_user_cookie(self.client, users["user"])

        response = self.client.get(url_for("pr_occtax.getReleves"), query_string=query_string)

        assert response.status_code == 200
        json_resp = response.json
        assert releve.id_releve_occtax in [
            int(releve_json["id"]) for releve_json in json_resp["items"]["features"]
        ]

    def test_get_releve_filter_altitude_min_not_present(self, users, releve):
        query_string = {"altitude_min": releve.altitude_min + 1}

        set_logged_user_cookie(self.client, users["user"])

        response = self.client.get(url_for("pr_occtax.getReleves"), query_string=query_string)

        assert response.status_code == 200
        json_resp = response.json
        assert releve.id_releve_occtax not in [
            int(releve_json["id"]) for releve_json in json_resp["items"]["features"]
        ]


@pytest.mark.usefixtures("client_class", "temporary_transaction")
@pytest.mark.parametrize(
    "wrong_value",
    (
        {"cd_nom": "wrong"},
        {"date_up": 42},
        {"date_low": 42},
        {"date_eq": 42},
        {"altitude_min": "wrong"},
        {"altitude_max": "wrong"},
        {"organism": "wrong"},
    ),
)
class TestOcctaxGetReleveFilterWrongType:
    def test_get_releve_filter_wrong_type(self, users, wrong_value):
        query_string = wrong_value
        set_logged_user_cookie(self.client, users["user"])

        response = self.client.get(url_for("pr_occtax.getReleves"), query_string=query_string)

        assert response.status_code == 500


@pytest.mark.usefixtures("temporary_transaction")
class TestReleveRepository:
    def test_get_one(self, releve, permission):
        repository = ReleveRepository(TRelevesOccurrence)
        repo = repository.get_one(id_releve=releve.id_releve_occtax, info_user=permission)

        assert repo[0].id_releve_occtax == releve.id_releve_occtax

    def test_get_one_not_found(self, unexisting_id_releve, permission):
        repository = ReleveRepository(TRelevesOccurrence)

        with pytest.raises(NotFound):
            repository.get_one(id_releve=unexisting_id_releve, info_user=permission)

    def test_delete(self, releve, permission):
        repository = ReleveRepository(TRelevesOccurrence)

        rel = repository.delete(releve.id_releve_occtax, permission)

        assert rel.id_releve_occtax == releve.id_releve_occtax

    def test_delete_not_found(self, unexisting_id_releve):
        repository = ReleveRepository(TRelevesOccurrence)

        with pytest.raises(NotFound):
            repository.delete(unexisting_id_releve, permission)
