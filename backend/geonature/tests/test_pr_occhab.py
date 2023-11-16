import pytest
from copy import deepcopy

from flask import url_for
from werkzeug.exceptions import Unauthorized, Forbidden, BadRequest
from shapely.geometry import Point
import geojson
from geojson import Feature
from geoalchemy2.shape import from_shape, to_shape
import sqlalchemy as sa
from marshmallow import EXCLUDE

from geonature.utils.env import db

from pypn_habref_api.models import Habref
from pypnnomenclature.models import TNomenclatures
from utils_flask_sqla_geo.schema import FeatureSchema, FeatureCollectionSchema

from .utils import set_logged_user
from .fixtures import *

occhab = pytest.importorskip("gn_module_occhab")

from gn_module_occhab.models import Station, OccurenceHabitat
from gn_module_occhab.schemas import StationSchema


@pytest.fixture
def station(datasets):
    ds = datasets["own_dataset"]
    p = Point(3.634, 44.399)
    nomenc = TNomenclatures.query.filter(
        sa.and_(
            TNomenclatures.nomenclature_type.has(mnemonique="NAT_OBJ_GEO"),
            TNomenclatures.mnemonique == "Stationnel",
        )
    ).one()
    s = Station(
        dataset=ds,
        comment="Ma super station",
        geom_4326=from_shape(p, srid=4326),
        nomenclature_geographic_object=nomenc,
    )
    habref = Habref.query.first()
    nomenc_tech_collect = TNomenclatures.query.filter(
        sa.and_(
            TNomenclatures.nomenclature_type.has(mnemonique="TECHNIQUE_COLLECT_HAB"),
            TNomenclatures.label_fr == "Plongées",
        )
    ).one()
    s.habitats.extend(
        [
            OccurenceHabitat(
                cd_hab=habref.cd_hab,
                nom_cite="forêt",
                id_nomenclature_collection_technique=nomenc_tech_collect.id_nomenclature,
            ),
            OccurenceHabitat(
                cd_hab=habref.cd_hab,
                nom_cite="prairie",
                id_nomenclature_collection_technique=nomenc_tech_collect.id_nomenclature,
            ),
        ]
    )
    with db.session.begin_nested():
        db.session.add(s)
    return s


@pytest.fixture
def station2(datasets, station):
    ds = datasets["own_dataset"]
    p = Point(5, 46)
    nomenc = TNomenclatures.query.filter(
        sa.and_(
            TNomenclatures.nomenclature_type.has(mnemonique="NAT_OBJ_GEO"),
            TNomenclatures.mnemonique == "Stationnel",
        )
    ).one()
    s = Station(
        dataset=ds,
        comment="Ma super station 2",
        geom_4326=from_shape(p, srid=4326),
        nomenclature_geographic_object=nomenc,
    )
    habref = Habref.query.filter(Habref.cd_hab != station.habitats[0].cd_hab).first()
    nomenc_tech_collect = TNomenclatures.query.filter(
        sa.and_(
            TNomenclatures.nomenclature_type.has(mnemonique="TECHNIQUE_COLLECT_HAB"),
            TNomenclatures.label_fr == "Plongées",
        )
    ).one()
    s.habitats.extend(
        [
            OccurenceHabitat(
                cd_hab=habref.cd_hab,
                nom_cite="forêt",
                id_nomenclature_collection_technique=nomenc_tech_collect.id_nomenclature,
            ),
            OccurenceHabitat(
                cd_hab=habref.cd_hab,
                nom_cite="prairie",
                id_nomenclature_collection_technique=nomenc_tech_collect.id_nomenclature,
            ),
        ]
    )
    with db.session.begin_nested():
        db.session.add(s)
    return s


@pytest.mark.usefixtures("client_class", "temporary_transaction")
class TestOcchab:
    def test_list_stations(self, users, datasets, station):
        url = url_for("occhab.list_stations")

        response = self.client.get(url)
        assert response.status_code == Unauthorized.code

        set_logged_user(self.client, users["noright_user"])
        response = self.client.get(url)
        assert response.status_code == Forbidden.code

        set_logged_user(self.client, users["user"])
        response = self.client.get(url)
        assert response.status_code == 200
        StationSchema(many=True).validate(response.json)

        set_logged_user(self.client, users["user"])
        response = self.client.get(url, query_string={"format": "geojson"})
        assert response.status_code == 200
        StationSchema(as_geojson=True, many=True).validate(response.json)
        collection = FeatureCollectionSchema().load(response.json)
        assert station.id_station in {feature["id"] for feature in collection["features"]}

        response = self.client.get(url, query_string={"format": "geojson", "habitats": "1"})
        assert response.status_code == 200
        collection = FeatureCollectionSchema().load(response.json)
        feature = next(filter(lambda feature: feature["id"], collection["features"]))
        assert len(feature["properties"]["habitats"]) == len(station.habitats)

    def test_get_station(self, users, station):
        url = url_for("occhab.get_station", id_station=station.id_station)

        response = self.client.get(url)
        assert response.status_code == Unauthorized.code

        set_logged_user(self.client, users["noright_user"])
        response = self.client.get(url)
        assert response.status_code == Forbidden.code

        set_logged_user(self.client, users["stranger_user"])
        response = self.client.delete(url)
        assert response.status_code == Forbidden.code

        set_logged_user(self.client, users["user"])
        response = self.client.get(url)
        assert response.status_code == 200
        response_station = StationSchema(
            only=["observers", "dataset", "habitats"],
            as_geojson=True,
        ).load(
            response.json,
            unknown=EXCLUDE,
        )
        assert set(response_station.habitats) == set(station.habitats)

    def test_create_station(self, users, datasets, station):
        url = url_for("occhab.create_or_update_station")
        point = Point(3.634, 44.399)
        nomenc_nat_obj_geo = TNomenclatures.query.filter(
            sa.and_(
                TNomenclatures.nomenclature_type.has(mnemonique="NAT_OBJ_GEO"),
                TNomenclatures.mnemonique == "Stationnel",
            )
        ).one()
        nomenc_tech_collect = TNomenclatures.query.filter(
            sa.and_(
                TNomenclatures.nomenclature_type.has(mnemonique="TECHNIQUE_COLLECT_HAB"),
                TNomenclatures.label_fr == "Lidar",
            )
        ).one()
        habref = Habref.query.first()
        feature = Feature(
            geometry=point,
            properties={
                "id_dataset": datasets["own_dataset"].id_dataset,
                "id_nomenclature_geographic_object": nomenc_nat_obj_geo.id_nomenclature,
                "comment": "Une station",
                "observers": [
                    {
                        "id_role": users["user"].id_role,
                    },
                ],
                "habitats": [
                    {
                        "cd_hab": habref.cd_hab,
                        "id_nomenclature_collection_technique": nomenc_tech_collect.id_nomenclature,
                        "nom_cite": "prairie",
                    },
                ],
            },
        )

        response = self.client.post(url, data=feature)
        assert response.status_code == Unauthorized.code

        set_logged_user(self.client, users["noright_user"])
        response = self.client.post(url, data=feature)
        assert response.status_code == Forbidden.code

        set_logged_user(self.client, users["user"])

        response = self.client.post(url, data=feature)
        assert response.status_code == 200, response.json
        new_feature = FeatureSchema().load(response.json)
        new_station = db.session.get(Station, new_feature["id"])
        assert new_station.comment == "Une station"
        assert to_shape(new_station.geom_4326).equals_exact(Point(3.634, 44.399), 0.01)
        assert len(new_station.habitats) == 1
        habitat = new_station.habitats[0]
        assert habitat.nom_cite == "prairie"
        assert len(new_station.observers) == 1
        observer = new_station.observers[0]
        assert observer.id_role == users["user"].id_role

        # Test unexisting id dataset
        data = deepcopy(feature)
        data["properties"]["id_dataset"] = -1
        response = self.client.post(url, data=data)
        assert response.status_code == 400, response.json
        assert "unexisting dataset" in response.json["description"].casefold(), response.json

        # Try modify existing station
        data = deepcopy(feature)
        data["properties"]["id_station"] = station.id_station
        response = self.client.post(
            url_for(
                "occhab.create_or_update_station",
                id_station=station.id_station,
            ),
            data=data,
        )
        db.session.refresh(station)
        assert station.comment == "Une station"  # original comment

        # Try leveraging observers to modify existing user
        data = deepcopy(feature)
        data["properties"]["observers"][0]["nom_role"] = "nouveau nom"
        response = self.client.post(url, data=data)
        assert response.status_code == 200, response.json
        db.session.refresh(users["user"])
        assert users["user"].nom_role != "nouveau nom"

        # Try associate other station habitat to this station
        data = deepcopy(feature)
        id_habitat = station.habitats[0].id_habitat
        data["properties"]["habitats"][0]["id_habitat"] = id_habitat
        response = self.client.post(url, data=data)
        assert response.status_code == 400, response.json
        assert (
            "habitat does not belong to this station" in response.json["description"].casefold()
        ), response.json
        assert id_habitat in {hab.id_habitat for hab in station.habitats}

    def test_update_station(self, users, station, station2):
        url = url_for("occhab.create_or_update_station", id_station=station.id_station)
        feature = StationSchema(as_geojson=True, only=["habitats", "observers", "dataset"]).dump(
            station
        )

        response = self.client.post(url, data=feature)
        assert response.status_code == Unauthorized.code

        set_logged_user(self.client, users["noright_user"])
        response = self.client.post(url, data=feature)
        assert response.status_code == Forbidden.code

        set_logged_user(self.client, users["stranger_user"])
        response = self.client.post(url, data=feature)
        assert response.status_code == Forbidden.code

        set_logged_user(self.client, users["user"])

        # Try modifying id_station
        id_station = station.id_station
        data = deepcopy(feature)
        data["properties"]["id_station"] = station2.id_station
        data["properties"]["habitats"] = []
        assert len(station2.habitats) == 2
        id_habitats = [hab.id_habitat for hab in station2.habitats]
        response = self.client.post(url, data=data)
        assert response.status_code == 400, response.json
        assert "unmatching id_station" in response.json["description"].casefold(), response.json
        # db.session.refresh(station2)
        assert len(station2.habitats) == 2

        # Try adding an occurence
        cd_hab_list = [occhab.cd_hab for occhab in OccurenceHabitat.query.all()]
        other_habref = Habref.query.filter(~Habref.cd_hab.in_(cd_hab_list)).first()
        feature["properties"]["habitats"].append(
            {
                "cd_hab": other_habref.cd_hab,
                "id_nomenclature_collection_technique": feature["properties"]["habitats"][0][
                    "id_nomenclature_collection_technique"
                ],
                "nom_cite": "monde merveilleux",
            },
        )
        response = self.client.post(url, data=feature)
        assert response.status_code == 200, response.json
        feature = FeatureSchema().load(response.json)
        assert len(feature["properties"]["habitats"]) == 3

        # Try modifying existing occurence
        habitat = next(
            filter(
                lambda hab: hab["nom_cite"] == "monde merveilleux",
                feature["properties"]["habitats"],
            )
        )
        habitat["nom_cite"] = "monde fantastique"
        response = self.client.post(url, data=feature)
        assert response.status_code == 200, response.json
        feature = FeatureSchema().load(response.json)
        assert len(feature["properties"]["habitats"]) == 3
        habitat = next(
            filter(
                lambda hab: hab["id_habitat"] == habitat["id_habitat"],
                feature["properties"]["habitats"],
            )
        )
        assert habitat["nom_cite"] == "monde fantastique"

        # Try associate/modify other station habitat
        habitat = feature["properties"]["habitats"][0]
        habitat2 = station2.habitats[0]
        habitat["id_habitat"] = habitat2.id_habitat
        response = self.client.post(url, data=feature)
        assert response.status_code == 400, response.json
        assert (
            "habitat does not belong to this station" in response.json["description"].casefold()
        ), response.json
        assert habitat2.id_station == station2.id_station

        # # Try re-create habitat
        # data = deepcopy(feature)
        # del data["properties"]["habitats"][1]["id_habitat"]
        # response = self.client.post(url, data=data)
        # assert response.status_code == 200, response.json

        # # Try associate other station habitat to this habitat
        # data = deepcopy(feature)
        # id_habitat = station2.habitats[0].id_habitat
        # data["properties"]["habitats"][0]["id_habitat"] = id_habitat
        # station2_habitats = {hab.id_habitat for hab in station2.habitats}
        # response = self.client.post(url, data=data)
        # assert response.status_code == 200, response.json
        # feature = FeatureSchema().load(response.json)
        # station = Station.query.get(feature["properties"]["id_station"])
        # station_habitats = {hab.id_habitat for hab in station.habitats}
        # assert station_habitats.isdisjoint(station2_habitats)

    def test_delete_station(self, users, station):
        url = url_for("occhab.delete_station", id_station=station.id_station)

        response = self.client.delete(url)
        assert response.status_code == Unauthorized.code

        set_logged_user(self.client, users["noright_user"])
        response = self.client.delete(url)
        assert response.status_code == Forbidden.code

        set_logged_user(self.client, users["stranger_user"])
        response = self.client.delete(url)
        assert response.status_code == Forbidden.code

        set_logged_user(self.client, users["user"])
        response = self.client.delete(url)
        assert response.status_code == 204
        assert not db.session.query(
            Station.select.filter_by(id_station=station.id_station).exists()
        ).scalar()

    def test_get_default_nomenclatures(self, users):
        response = self.client.get(url_for("occhab.get_default_nomenclatures"))
        assert response.status_code == Unauthorized.code
        set_logged_user(self.client, users["user"])
        response = self.client.get(url_for("occhab.get_default_nomenclatures"))
        assert response.status_code == 200
