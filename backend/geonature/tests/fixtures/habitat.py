from geonature.core.gn_meta.models import TDatasets
import pytest
from datetime import datetime


from shapely.geometry import Point

from geoalchemy2.shape import from_shape
import sqlalchemy as sa


from geonature.utils.env import db

from pypn_habref_api.models import Habref
from pypnnomenclature.models import TNomenclatures

occhab = pytest.importorskip("gn_module_occhab")

from gn_module_occhab.models import Station, OccurenceHabitat
from gn_module_occhab.schemas import StationSchema


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
