from io import BytesIO, StringIO
from typing import List
from geonature.core.gn_meta.models import TDatasets
from pypnusershub.db.models import User, UserApplicationRight
import pytest
from copy import deepcopy
import json

import pandas as pd
from flask import url_for
from werkzeug.datastructures import TypeConversionDict
from werkzeug.exceptions import Unauthorized, Forbidden, BadRequest
from shapely.geometry import Point
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
from datetime import datetime


def create_habitat(nom_cite, nomenc_tech_collect_NOMENC_TYPE, nomenc_tech_collect_LABEL):
    habref = db.session.scalars(sa.select(Habref).limit(1)).first()

    nomenc_tech_collect = db.session.execute(
        sa.select(TNomenclatures).where(
            sa.and_(
                TNomenclatures.nomenclature_type.has(mnemonique=nomenc_tech_collect_NOMENC_TYPE),
                TNomenclatures.label_fr == nomenc_tech_collect_LABEL,
            )
        )
    ).scalar_one()
    return OccurenceHabitat(
        cd_hab=habref.cd_hab,
        nom_cite=nom_cite,
        id_nomenclature_collection_technique=nomenc_tech_collect.id_nomenclature,
    )


@pytest.fixture
def stations(datasets):
    """
    Fixture to generate test stations

    Parameters
    ----------
    datasets : TDatasets
        dataset associated with the station (fixture)

    Returns
    -------
    Dict[Station]
        dict that contains test stations
    """

    def create_stations(
        dataset: TDatasets,
        coords: tuple,
        nomenc_object_MNEM: str,
        nomenc_object_NOMENC_TYPE: str,
        comment: str = "Did you create a station ?",
        date_min=datetime.now(),
        date_max=datetime.now(),
    ):
        """
        Function to generate a station

        Parameters
        ----------
        dataset : TDatasets
            dataset associated with it
        coords : tuple
            longitude and latitude coordinates (WGS84)
        nomenc_object_MNEM : str
            mnemonique of the nomenclature associated to the station
        nomenc_object_NOMENC_TYPE : str
            nomenclature type associated to the station
        comment : str, optional
            Just a comment, by default "Did you create a station ?"
        """
        nomenclature_object = db.session.execute(
            sa.select(TNomenclatures).where(
                sa.and_(
                    TNomenclatures.nomenclature_type.has(mnemonique=nomenc_object_NOMENC_TYPE),
                    TNomenclatures.mnemonique == nomenc_object_MNEM,
                )
            )
        ).scalar_one()
        s = Station(
            dataset=dataset,
            comment=comment,
            geom_4326=from_shape(Point(*coords), srid=4326),
            nomenclature_geographic_object=nomenclature_object,
            date_min=date_min,
            date_max=date_max,
        )
        habitats = []
        for nom_type, nom_label in [("TECHNIQUE_COLLECT_HAB", "Plongées")]:
            for nom_cite in ["forêt", "prairie"]:
                habitats.append(create_habitat(nom_cite, nom_type, nom_label))
        s.habitats.extend(habitats)
        return s

    stations = {
        "station_1": create_stations(
            datasets["own_dataset"],
            (3.634, 44.399),
            "Stationnel",
            "NAT_OBJ_GEO",
            comment="Station1",
            date_min=datetime.strptime("01/02/70", "%d/%m/%y"),
            date_max=datetime.strptime("01/02/80", "%d/%m/%y"),
        ),
        "station_2": create_stations(
            datasets["own_dataset"],
            (3.634, 44.399),
            "Stationnel",
            "NAT_OBJ_GEO",
            comment="Station2",
        ),
    }
    with db.session.begin_nested():
        for station_key in stations:
            db.session.add(stations[station_key])
        db.session.flush()
    return stations


@pytest.fixture
def station(stations):
    """
    Add to the session and return the test station 1 (will be removed in the future)

    Parameters
    ----------
    stations : List[Station]
        fixture

    Returns
    -------
    Station
        station 1
    """
    return stations["station_1"]


@pytest.fixture
def station2(stations):
    """
    Add to the session and return the test station 2 (will be removed in the future)

    Parameters
    ----------
    stations : List[Station]
        fixture

    Returns
    -------
    Station
        station 2
    """
    return stations["station_2"]


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
            only=["id_station", "observers", "dataset", "habitats"],
            as_geojson=True,
        ).load(
            response.json,
            unknown=EXCLUDE,
        )
        assert set(response_station.habitats) == set(station.habitats)

    def test_create_station(self, users, datasets, station):
        url = url_for("occhab.create_or_update_station")
        point = Point(3.634, 44.399)
        nomenc_nat_obj_geo = db.session.execute(
            sa.select(TNomenclatures).where(
                sa.and_(
                    TNomenclatures.nomenclature_type.has(mnemonique="NAT_OBJ_GEO"),
                    TNomenclatures.mnemonique == "Stationnel",
                )
            )
        ).scalar_one()
        nomenc_tech_collect = db.session.execute(
            sa.select(TNomenclatures).where(
                sa.and_(
                    TNomenclatures.nomenclature_type.has(mnemonique="TECHNIQUE_COLLECT_HAB"),
                    TNomenclatures.label_fr == "Lidar",
                )
            )
        ).scalar_one()
        habref = db.session.scalars(sa.select(Habref).limit(1)).first()
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

        # Try leveraging create route to modify existing station: this should not works!
        data = deepcopy(feature)
        data["properties"]["id_station"] = station.id_station
        response = self.client.post(url, data=data)
        assert response.status_code == 200, response.json
        db.session.refresh(station)
        assert station.comment == "Station1"  # original comment of existing station
        FeatureSchema().load(response.json)["id"] != station.id_station  # new id for new station

        # Try leveraging observers to modify existing user
        data = deepcopy(feature)
        data["properties"]["observers"][0]["nom_role"] = "nouveau nom"
        response = self.client.post(url, data=data)
        assert response.status_code == 200, response.json
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
        data = deepcopy(feature)
        id_station = station.id_station
        data["properties"]["id_station"] = station2.id_station
        data["properties"]["habitats"] = []
        assert len(station2.habitats) == 2
        id_habitats = [hab.id_habitat for hab in station2.habitats]
        response = self.client.post(url, data=data)
        assert response.status_code == 200, response.json
        FeatureSchema().load(response.json)["id"] == id_station  # not changed because read only
        assert len(station.habitats) == 0  # station updated
        assert len(station2.habitats) == 2  # station2 not changed

        # Test modifying id dataset with unexisting id dataset
        data = deepcopy(feature)
        id_dataset = station.id_dataset
        data["properties"]["id_dataset"] = -1
        response = self.client.post(url, data=data)
        assert response.status_code == 400, response.json
        assert "unexisting dataset" in response.json["description"].casefold(), response.json
        station = db.session.get(Station, station.id_station)
        assert station.id_dataset == id_dataset  # not changed

        # Try adding an occurence
        cd_hab_list = [
            occhab.cd_hab
            for occhab in db.session.scalars(sa.select(OccurenceHabitat)).unique().all()
        ]
        other_habref = db.session.scalars(
            sa.select(Habref).where(~Habref.cd_hab.in_(cd_hab_list)).limit(1)
        ).first()
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
        data = deepcopy(feature)
        id_habitat_station2 = station2.habitats[0].id_habitat
        data["properties"]["habitats"][0]["id_habitat"] = id_habitat_station2
        response = self.client.post(url, data=data)
        assert response.status_code == 400, response.json
        assert (
            "habitat does not belong to this station" in response.json["description"].casefold()
        ), response.json
        habitat_station2 = db.session.get(OccurenceHabitat, id_habitat_station2)
        assert habitat_station2.id_station == station2.id_station
        station = db.session.get(Station, station.id_station)
        assert len(station.habitats) == 3
        assert len(station2.habitats) == 2

        # Try re-create an habitat (remove old, add new)
        data = deepcopy(feature)
        keep_ids = {hab["id_habitat"] for hab in data["properties"]["habitats"][0:1]}
        removed_id = data["properties"]["habitats"][2]["id_habitat"]
        del data["properties"]["habitats"][2]["id_habitat"]
        response = self.client.post(url, data=data)
        assert response.status_code == 200, response.json
        ids = set((hab.id_habitat for hab in station.habitats))
        assert removed_id not in ids
        assert keep_ids.issubset(ids)
        assert len(station.habitats) == 3

        # Try associate other station habitat to this habitat
        station_habitats = {hab.id_habitat for hab in station.habitats}
        station2_habitats = {hab.id_habitat for hab in station2.habitats}
        data = deepcopy(feature)
        id_habitat = station2.habitats[0].id_habitat
        data["properties"]["habitats"][0]["id_habitat"] = id_habitat
        response = self.client.post(url, data=data)
        assert response.status_code == 400, response.json
        assert (
            "habitat does not belong to this station" in response.json["description"].casefold()
        ), response.json
        assert station_habitats == {hab.id_habitat for hab in station.habitats}
        assert station2_habitats == {hab.id_habitat for hab in station2.habitats}

    def test_delete_station(self, users, station):
        url = url_for("occhab.delete_station", id_station=station.id_station)

        response = self.client.delete(url)
        assert response.status_code == Unauthorized.code

        set_logged_user(self.client, users["noright_user"])
        response = self.client.delete(url)
        assert response.status_code == Forbidden.code
        assert db.session.scalar(
            sa.exists().where(Station.id_station == station.id_station).select()
        )

        set_logged_user(self.client, users["stranger_user"])
        response = self.client.delete(url)
        assert response.status_code == Forbidden.code
        assert db.session.scalar(
            sa.exists().where(Station.id_station == station.id_station).select()
        )

        set_logged_user(self.client, users["user"])
        response = self.client.delete(url)
        assert response.status_code == 204
        assert not db.session.execute(
            sa.exists().where(Station.id_station == station.id_station).select()
        ).scalar()

    def test_get_default_nomenclatures(self, users):
        response = self.client.get(url_for("occhab.get_default_nomenclatures"))
        assert response.status_code == Unauthorized.code
        set_logged_user(self.client, users["user"])
        response = self.client.get(url_for("occhab.get_default_nomenclatures"))
        assert response.status_code == 200

    def test_filter_by_params(self, datasets, stations):
        def query_test_filter_by_params(params):
            query = Station.filter_by_params(
                TypeConversionDict(**params),
            )
            return db.session.scalars(query).unique().all()

        # Test Filter by dataset
        ds: TDatasets = datasets["own_dataset"]
        stations_res = query_test_filter_by_params(dict(id_dataset=ds.id_dataset))
        assert len(stations_res) >= 1

        # Test filter by cd_hab
        habref = db.session.scalars(sa.select(Habref).limit(1)).first()
        assert len(stations["station_1"].habitats) > 1
        assert stations["station_1"].habitats[0].cd_hab == habref.cd_hab
        stations_res = query_test_filter_by_params(dict(cd_hab=habref.cd_hab))
        assert len(stations_res) >= 1
        for station in stations_res:
            assert len(station.habitats) > 1
            assert any([habitat.cd_hab == habref.cd_hab for habitat in station.habitats])

        # test filter by date max
        date_format = "%d/%m/%y"
        station_res = query_test_filter_by_params(
            dict(date_up="1981-02-01"),
        )
        assert any(
            [station.id_station == stations["station_1"].id_station for station in station_res]
        )

        # test filter by date min
        station_res = query_test_filter_by_params(
            dict(date_low="1969-02-01"),
        )
        assert all(
            [
                any([station.id_station == station_session.id_station for station in station_res])
                for station_session in stations.values()
            ]
        )

    def test_filter_by_scope(self):
        res = Station.filter_by_scope(0)
        res = db.session.scalars(res).unique().all()
        assert not len(res)  # <=> len(res) == 0

    def test_has_instance_permission(self, stations):
        assert not stations["station_1"].has_instance_permission(scope=0)

    def test_export_occhab(self, stations, users):
        """
        Check if the export route in OCCHAB works and if the returned data is consistent.
        """

        set_logged_user(self.client, users["admin_user"])

        data = {"idsStation": [stations["station_1"].id_station, stations["station_2"].id_station]}
        uuidINPN = set(
            [
                str(stations["station_1"].unique_id_sinp_station),
                str(stations["station_2"].unique_id_sinp_station),
            ]
        )
        # Test the CSV export
        response = self.client.post(
            url_for("occhab.export_all_habitats", export_format="csv"), data=data
        )
        assert response.status_code == 200
        # Read the CSV and verify all declared stations are contained in the export
        uuids_INPN_export = pd.read_csv(
            StringIO(response.data.decode("utf-8")), sep=";"
        ).identifiantStaSINP.unique()
        assert all([True if uuid_ in uuids_INPN_export else False for uuid_ in uuidINPN])

        # Test the GEOJSON export
        response = self.client.post(
            url_for("occhab.export_all_habitats", export_format="geojson"), data=data
        )
        assert response.status_code == 200
        # READ the GEOJson and check if all stations INPN uuid are present
        uuids_INPN_export = [
            item["properties"]["identifiantStaSINP"]
            for item in json.loads(response.data)["features"]
        ]
        assert all([True if uuid_ in uuids_INPN_export else False for uuid_ in uuidINPN])

        # Test the SHAPEFILE export
        response = self.client.post(
            url_for("occhab.export_all_habitats", export_format="shapefile"), data=data
        )
        assert response.status_code == 200
