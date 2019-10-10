from flask import Blueprint, current_app, session, request
from geoalchemy2.shape import from_shape
from shapely.geometry import asShape

from geonature.utils.utilssqlalchemy import json_resp
from geonature.utils.utilsgeometry import remove_third_dimension
from geonature.utils.env import DB

from pypnusershub.db.models import User

from .models import TStationsOcchab, THabitatsOcchab

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
    if occ_hab is not None:

        for occ in occ_hab:
            data_attr = [k for k in occ]
            for att in data_attr:
                if not getattr(THabitatsOcchab, att, False):
                    occ.pop(att)
            habitat_obj = THabitatsOcchab(**occ)
            station.t_habitats.append(habitat_obj)
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
    params = request.args
    station = DB.session.query(TStationsOcchab).get(id_station)
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
    return [d.get_geofeature(True) for d in data]
