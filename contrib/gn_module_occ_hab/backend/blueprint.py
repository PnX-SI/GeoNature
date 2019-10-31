from .models import OneStation, TStationsOcchab, THabitatsOcchab
from pypnusershub.db.models import User
from geonature.utils.env import DB
from geonature.utils.utilsgeometry import remove_third_dimension
from geonature.utils.utilssqlalchemy import json_resp
from shapely.geometry import asShape
from geojson import FeatureCollection
from geoalchemy2.shape import from_shape
from flask import Blueprint, current_app, session, request

blueprint = Blueprint("occhab", __name__)


@blueprint.route("/station", methods=["POST"])
@json_resp
def post_station():
    """
    Post one occhab station (station + habitats)

    .. :quickref: OccHab; Post one occhab station (station + habitats)

    :returns: GeoJson<TStationsOcchab>
    """

    data = dict(request.get_json())
    occ_hab = None
    if "t_habitats" in data:
        occ_hab = data.pop("t_habitats")
    observers_list = None
    if "observers" in data:
        observers_list = data.pop("observers")

    station = TStationsOcchab(**data)
    print(station.observer_rel)
    shape = asShape(data["geom_4326"])
    two_dimension_geom = remove_third_dimension(shape)
    station.geom_4326 = from_shape(two_dimension_geom, srid=4326)
    if observers_list is not None:
        observers = (
            DB.session.query(User).filter(
                User.id_role.in_(observers_list)).all()
        )
        for o in observers:
            station.observers.append(o)
    t_hab_list_object = []
    if occ_hab is not None:
        for occ in occ_hab:
            if occ['id_habitat'] is None:
                occ.pop('id_habitat')
            data_attr = [k for k in occ]
            for att in data_attr:
                if not getattr(THabitatsOcchab, att, False):
                    occ.pop(att)
            t_hab_list_object.append(THabitatsOcchab(**occ))
    station.t_habitats = t_hab_list_object
    if station.id_station:
        DB.session.merge(station)
    else:
        DB.session.add(station)
    DB.session.commit()
    return station.get_geofeature()


@blueprint.route("/station/<int:id_station>", methods=["GET"])
@json_resp
def get_one_station(id_station):
    """
        Return one station

        .. :quickref: Occhab;

        :param id_station: the id_station
        :type id_station: int

        :return: a dict representing one station with its habitats
        :rtype dict<TStationsOcchab>

    """
    station = DB.session.query(OneStation).get(id_station)
    return station.get_geofeature(True)


@blueprint.route("/stations", methods=["GET"])
@json_resp
def get_all_habitats():
    """
        Return all station with their habitat
    """
    params = request.args
    q = DB.session.query(TStationsOcchab)

    if 'id_dataset' in params:
        q = q.filter(TStationsOcchab.id_dataset == params['id_dataset'])
    data = q.all()
    # for d in data:
    #     print(d.observer_rel)
    return FeatureCollection(
        [d.get_geofeature(True) for d in data])
