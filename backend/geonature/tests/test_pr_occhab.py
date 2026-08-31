from io import StringIO
from geonature.core.gn_meta.models import TDatasets
import pytest
from copy import deepcopy
import json
from datetime import datetime

import pandas as pd
from flask import url_for, current_app, g
from werkzeug.datastructures import TypeConversionDict
from werkzeug.exceptions import Unauthorized, Forbidden, Conflict
from shapely.geometry import Point
from geojson import Feature
from geoalchemy2.shape import from_shape, to_shape
import sqlalchemy as sa
from marshmallow import EXCLUDE

from geonature.utils.env import db
from geonature.core.gn_commons.models.base import TModules, BibWidgets
from geonature.core.gn_commons.models.additional_fields import TAdditionalFields
from geonature.core.gn_permissions.models import PermObject

from pypn_habref_api.models import Habref
from pypnnomenclature.models import TNomenclatures
from utils_flask_sqla_geo.schema import FeatureSchema, FeatureCollectionSchema

from .utils import set_logged_user

occhab = pytest.importorskip("gn_module_occhab")

from gn_module_occhab.models import Station, OccurenceHabitat
from gn_module_occhab.schemas import StationSchema


@pytest.fixture(scope="function")
def occhab_additional_fields():
    """
    Un champ texte et un champ nomenclature pour chacun des deux niveaux du
    formulaire Occhab. Ces champs ne sont rattachés à aucun jeu de données :
    ils s'appliquent donc à toutes les stations du module.
    """
    module = db.session.execute(
        sa.select(TModules).where(TModules.module_code == "OCCHAB")
    ).scalar_one()
    widgets = {
        widget_name: db.session.execute(
            sa.select(BibWidgets).where(BibWidgets.widget_name == widget_name)
        ).scalar_one()
        for widget_name in ("text", "nomenclature")
    }

    fields = {}
    for level, code_object in [
        ("station", "OCCHAB_STATION"),
        ("habitat", "OCCHAB_HABITAT"),
    ]:
        obj = db.session.execute(
            sa.select(PermObject).where(PermObject.code_object == code_object)
        ).scalar_one()
        for widget_name, widget in widgets.items():
            field_name = f"{level}_{widget_name}_field"
            fields[f"{level}_{widget_name}"] = TAdditionalFields(
                field_name=field_name,
                field_label=field_name,
                required=False,
                id_widget=widget.id_widget,
                modules=[module],
                objects=[obj],
            )
    with db.session.begin_nested():
        db.session.add_all(fields.values())
    return fields


@pytest.mark.usefixtures("client_class")
class TestOcchab:
    def test_list_stations(self, users, datasets, station):
        url = url_for("occhab.list_stations")

        response = self.client.get(url)
        assert response.status_code == Unauthorized.code

        set_logged_user(self.client, users["noright_user"])
        response = self.client.get(url)
        assert response.status_code == Forbidden.code

        for user_pseudo in ["user", "user_restricted_occhab"]:
            set_logged_user(self.client, users[user_pseudo])
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

        station.id_digitiser = users["stranger_user"].id_role
        db.session.flush()
        response = self.client.get(url)
        assert response.status_code == 200

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

        # Test with restricted rights
        set_logged_user(self.client, users["user_restricted_occhab"])
        response = self.client.get(url)
        assert response.status_code == 200

    @pytest.mark.parametrize("withObserversAsTXT", [True, False])
    def test_create_station(self, users, datasets, station, withObserversAsTXT, monkeypatch):

        monkeypatch.setitem(current_app.config["OCCHAB"], "OBSERVERS_AS_TXT", withObserversAsTXT)

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
        observer = (
            {
                "observers": [
                    {
                        "id_role": users["user"].id_role,
                    },
                ]
            }
            if not withObserversAsTXT
            else {"observers_txt": "test"}
        )
        feature = Feature(
            geometry=point,
            properties={
                "id_dataset": datasets["own_dataset"].id_dataset,
                "id_nomenclature_geographic_object": nomenc_nat_obj_geo.id_nomenclature,
                "comment": "Une station",
                **observer,
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
        if not withObserversAsTXT:
            assert len(new_station.observers) == 1
            observer = new_station.observers[0]
            assert observer.id_role == users["user"].id_role
        else:
            assert len(new_station.observers_txt) > 0

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
        if not withObserversAsTXT:
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

        # Try to update a station not created by user -> must fail because U = 1
        set_logged_user(self.client, users["user_restricted_occhab"])
        url = url_for("occhab.create_or_update_station", id_station=station2.id_station)
        feature = StationSchema(as_geojson=True, only=["habitats", "observers", "dataset"]).dump(
            station2
        )
        feature["station_name"] = "monde merveilleux"
        response = self.client.post(url, data=feature)
        assert response.status_code == Forbidden.code

    def test_delete_station(self, users, station, station2):
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

        # Try to delete a station not created by user -> must fail because D = 1
        url = url_for("occhab.delete_station", id_station=station2.id_station)
        set_logged_user(self.client, users["user_restricted_occhab"])
        response = self.client.delete(url)
        assert response.status_code == Forbidden.code

    def test_station_actions_on_closed_af(self, users, datasets, station):
        """
        Test that creating, updating and deleting a station fails when the
        associated dataset's acquisition framework is closed.
        """

        af = datasets["own_dataset"].acquisition_framework
        af.opened = False
        db.session.flush()

        set_logged_user(self.client, users["user"])

        feature = StationSchema(as_geojson=True, only=["observers", "dataset"]).dump(station)

        # ---- Test CREATE on closed AF ----
        url_create = url_for("occhab.create_or_update_station")
        response = self.client.post(url_create, data=feature)

        assert response.status_code == Conflict.code

        # ---- Test UPDATE on closed AF ----
        url_update = url_for("occhab.create_or_update_station", id_station=station.id_station)
        response = self.client.post(url_update, data=feature)
        assert response.status_code == Conflict.code

        # ---- Test DELETE on closed AF ----
        url_delete = url_for("occhab.delete_station", id_station=station.id_station)
        response = self.client.delete(url_delete)
        assert response.status_code == Conflict.code

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

    def test_filter_by_scope(self, stations, users, datasets):
        user = users["stranger_user"]
        station1 = stations["station_1"]

        res = (
            db.session.scalars(sa.select(Station).where(Station.filter_by_scope(scope=0)))
            .unique()
            .all()
        )
        assert len(res) == 0

        res = (
            db.session.scalars(
                sa.select(Station).where(Station.filter_by_scope(scope=3, user=user))
            )
            .unique()
            .all()
        )
        assert len(res) >= 2

        # No access
        station1.id_digitiser = None
        station1.observers = []
        db.session.flush()
        res = (
            db.session.scalars(
                sa.select(Station).where(Station.filter_by_scope(scope=1, user=user))
            )
            .unique()
            .all()
        )
        assert station1 not in res

        # Access because is observer
        station1.observers = [user]

        res = (
            db.session.scalars(
                sa.select(Station).where(Station.filter_by_scope(scope=1, user=user))
            )
            .unique()
            .all()
        )
        assert station1 in res

        # Access because is digitiser
        station1.observers = []
        station1.id_digitiser = user.id_role
        db.session.flush()
        res = (
            db.session.scalars(
                sa.select(Station).where(Station.filter_by_scope(scope=1, user=user))
            )
            .unique()
            .all()
        )
        assert station1 in res

        # Acces because has right on dataset
        user = users["user"]
        res = (
            db.session.scalars(
                sa.select(Station).where(Station.filter_by_scope(scope=1, user=user))
            )
            .unique()
            .all()
        )
        assert station1 in res

    def test_has_instance_permission_scopes(self, stations, users, datasets):
        station_example = stations["station_1"]
        user = users["stranger_user"]

        # Scopes always true or false
        assert station_example.has_instance_permission(scope=0) is False
        assert station_example.has_instance_permission(scope=3) is True

        g.current_user = user

        # User has no right
        station_example.observers = []
        station_example.id_digitiser = None
        assert station_example.has_instance_permission(scope=1) is False
        assert station_example.has_instance_permission(scope=2) is False

        # User is observer
        station_example.observers = [user]
        assert station_example.has_instance_permission(scope=1) is True
        assert station_example.has_instance_permission(scope=2) is True

        # User is digitiser
        station_example.observers = []
        station_example.id_digitiser = user.id_role
        assert station_example.has_instance_permission(scope=1) is True

        # User has right on dataset
        g.current_user = users["user"]
        station_example.id_digitiser = None
        assert station_example.has_instance_permission(scope=1) is True

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
        ).uuid_station.unique()
        assert all([True if uuid_ in uuids_INPN_export else False for uuid_ in uuidINPN])

        # Test the GEOJSON export
        response = self.client.post(
            url_for("occhab.export_all_habitats", export_format="geojson"), data=data
        )
        assert response.status_code == 200
        # READ the GEOJson and check if all stations INPN uuid are present
        uuids_INPN_export = [
            item["properties"]["uuid_station"] for item in json.loads(response.data)["features"]
        ]
        assert all([True if uuid_ in uuids_INPN_export else False for uuid_ in uuidINPN])

        # Test the SHAPEFILE export
        response = self.client.post(
            url_for("occhab.export_all_habitats", export_format="shapefile"), data=data
        )
        assert response.status_code == 200

    def test_create_station_with_additional_data(
        self, users, datasets, station, occhab_additional_fields
    ):
        """
        Les champs additionnels sont enregistrés aux deux niveaux, et ceux de type
        nomenclature sont accompagnés de leur libellé sous une clé `_label_`.
        """
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
            geometry=Point(3.634, 44.399),
            properties={
                "id_dataset": datasets["own_dataset"].id_dataset,
                "id_nomenclature_geographic_object": nomenc_nat_obj_geo.id_nomenclature,
                "observers": [{"id_role": users["user"].id_role}],
                "additional_data": {
                    "station_text_field": "une station",
                    "station_nomenclature_field": nomenc_nat_obj_geo.id_nomenclature,
                },
                "habitats": [
                    {
                        "cd_hab": habref.cd_hab,
                        "id_nomenclature_collection_technique": nomenc_tech_collect.id_nomenclature,
                        "nom_cite": "prairie",
                        "additional_data": {
                            "habitat_text_field": "un habitat",
                            "habitat_nomenclature_field": nomenc_tech_collect.id_nomenclature,
                        },
                    },
                ],
            },
        )

        set_logged_user(self.client, users["user"])
        response = self.client.post(url_for("occhab.create_or_update_station"), data=feature)
        assert response.status_code == 200, response.json

        new_station = db.session.get(Station, FeatureSchema().load(response.json)["id"])
        assert new_station.additional_data["station_text_field"] == "une station"
        assert (
            new_station.additional_data["station_nomenclature_field"]
            == nomenc_nat_obj_geo.id_nomenclature
        )
        assert (
            new_station.additional_data["_label_station_nomenclature_field"]
            == nomenc_nat_obj_geo.label_default
        )

        habitat = new_station.habitats[0]
        assert habitat.additional_data["habitat_text_field"] == "un habitat"
        assert (
            habitat.additional_data["habitat_nomenclature_field"]
            == nomenc_tech_collect.id_nomenclature
        )
        assert (
            habitat.additional_data["_label_habitat_nomenclature_field"]
            == nomenc_tech_collect.label_default
        )

        # les données des deux niveaux ne se mélangent pas
        assert "habitat_text_field" not in new_station.additional_data
        assert "station_text_field" not in habitat.additional_data

    def test_update_station_additional_nomenclature_label(
        self, users, station, occhab_additional_fields
    ):
        """
        À la mise à jour d'un champ additionnel de type nomenclature, le libellé
        `_label_` doit suivre la nouvelle valeur. Le client ne doit donc pas
        renvoyer celui qu'il a reçu : il serait réappliqué après le libellé
        recalculé et figerait l'ancienne valeur.
        """
        nomenclatures = (
            db.session.scalars(
                sa.select(TNomenclatures)
                .where(TNomenclatures.nomenclature_type.has(mnemonique="TECHNIQUE_COLLECT_HAB"))
                .order_by(TNomenclatures.id_nomenclature)
                .limit(2)
            )
            .unique()
            .all()
        )
        before, after = nomenclatures[0], nomenclatures[1]

        with db.session.begin_nested():
            station.additional_data = {
                "station_nomenclature_field": before.id_nomenclature,
                "_label_station_nomenclature_field": before.label_default,
            }

        set_logged_user(self.client, users["user"])
        url = url_for("occhab.create_or_update_station", id_station=station.id_station)
        feature = StationSchema(as_geojson=True, only=["habitats", "observers", "dataset"]).dump(
            station
        )
        # le client renvoie la valeur seule, sans le libellé reçu
        feature["properties"]["additional_data"] = {
            "station_nomenclature_field": after.id_nomenclature
        }

        response = self.client.post(url, data=feature)
        assert response.status_code == 200, response.json

        updated = db.session.get(Station, station.id_station)
        assert updated.additional_data["station_nomenclature_field"] == after.id_nomenclature
        assert (
            updated.additional_data["_label_station_nomenclature_field"] == after.label_default
        )

    def test_get_station_with_additional_data(self, users, station, occhab_additional_fields):
        with db.session.begin_nested():
            station.additional_data = {"station_text_field": "une station"}
            station.habitats[0].additional_data = {"habitat_text_field": "un habitat"}

        set_logged_user(self.client, users["user"])
        response = self.client.get(url_for("occhab.get_station", id_station=station.id_station))
        assert response.status_code == 200

        properties = response.json["properties"]
        assert properties["additional_data"]["station_text_field"] == "une station"
        assert properties["habitats"][0]["additional_data"]["habitat_text_field"] == "un habitat"
