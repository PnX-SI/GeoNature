import datetime
import json

from flask import Blueprint, current_app, session, send_from_directory, request, render_template
from geojson import FeatureCollection, Feature
from geoalchemy2.shape import from_shape
from pypnusershub.db.models import User
from shapely.geometry import asShape

from utils_flask_sqla.response import json_resp, to_csv_resp, to_json_resp
from geonature.core.gn_permissions import decorators as permissions
from geonature.core.gn_permissions.tools import get_or_fetch_user_cruved
from geonature.utils.env import DB, ROOT_DIR
from geonature.utils.errors import GeonatureApiError
from geonature.utils.utilsgeometry import remove_third_dimension
from geonature.utils import filemanager
from geonature.utils.utilssqlalchemy import GenericTable

from .models import OneStation, TStationsOcchab, THabitatsOcchab
from .query import filter_query_with_cruved

blueprint = Blueprint("occhab", __name__)


@blueprint.route("/station", methods=["POST"])
@permissions.check_cruved_scope("C", True, module_code="OCC_HAB")
@json_resp
def post_station(info_role):
    """
    Post one occhab station (station + habitats)

    .. :quickref: OccHab; Post one occhab station (station + habitats)

    :returns: GeoJson<TStationsOcchab>
    """

    data = dict(request.get_json())
    occ_hab = None
    properties = data['properties']
    if "t_habitats" in properties:
        occ_hab = properties.pop("t_habitats")
    observers_list = None
    if "observers" in properties:
        observers_list = properties.pop("observers")

    station = TStationsOcchab(**properties)
    shape = asShape(data["geometry"])
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
        user_cruved = get_or_fetch_user_cruved(
            session=session, id_role=info_role.id_role, module_code="OCCTAX"
        )
        # check if allowed to update or raise 403
        station.check_if_allowed(info_role, 'U', user_cruved["U"])
        DB.session.merge(station)
    else:
        DB.session.add(station)
    DB.session.commit()
    return station.get_geofeature()


@blueprint.route("/station/<int:id_station>", methods=["GET"])
@permissions.check_cruved_scope("R", True, module_code="OCC_HAB")
@json_resp
def get_one_station(id_station, info_role):
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
@permissions.check_cruved_scope("R", True, module_code="OCC_HAB")
@json_resp
def get_all_habitats(info_role):
    """
        Get all stations with their hab
    """
    params = request.args.to_dict()
    q = DB.session.query(TStationsOcchab)

    if 'id_dataset' in params:
        q = q.filter(TStationsOcchab.id_dataset == params['id_dataset'])

    if 'cd_hab' in params:
        q = q.filter(TStationsOcchab.t_habitats.any(cd_hab=params['cd_hab']))

    if 'date_low' in params:
        q = q.filter(TStationsOcchab.date_min >= params.pop("date_low"))

    if "date_up" in params:
        q = q.filter(TStationsOcchab.date_max <= params.pop("date_up"))

    q = filter_query_with_cruved(
        TStationsOcchab,
        q,
        info_role
    )
    data = q.limit(blueprint.config['NB_MAX_MAP_LIST'])

    user_cruved = get_or_fetch_user_cruved(
        session=session, id_role=info_role.id_role, module_code="OCCTAX"
    )
    feature_list = []
    for d in data:
        feature = d.get_geofeature(True)
        feature['properties']['rights'] = d.get_releve_cruved(
            info_role, user_cruved)

        feature_list.append(feature)
    return FeatureCollection(feature_list)


@blueprint.route("/export_stations/<export_format>", methods=["POST", "GET"])
@permissions.check_cruved_scope("E", True, module_code="OCC_HAB")
def export_all_habitats(info_role, export_format='csv',):
    """
        Download all stations
        The route is in post to avoid a to big query string
    """
    export_view = GenericTable(
        tableName="v_export_sinp",
        schemaName="pr_occhab",
        geometry_field=None,
        srid=current_app.config["LOCAL_SRID"],
    )

    file_name = datetime.datetime.now().strftime("%Y_%m_%d_%Hh%Mm%S")
    file_name = filemanager.removeDisallowedFilenameChars(file_name)
    db_cols_for_shape = []
    columns_to_serialize = []
    for db_col in export_view.db_cols:
        if db_col.key in blueprint.config['EXPORT_COLUMS']:
            db_cols_for_shape.append(db_col)
            columns_to_serialize.append(db_col.key)
    results = DB.session.query(export_view.tableDef).limit(
        blueprint.config['NB_MAX_EXPORT'])
    if export_format == 'csv':
        formated_data = [
            export_view.as_dict(d, columns=[]) for d in results
        ]
        return to_csv_resp(
            file_name, formated_data, separator=";", columns=columns_to_serialize
        )
    elif export_format == 'geojson':
        features = []
        for r in results:
            features.append(
                Feature(
                    geometry=json.loads(r.geojson),
                    properties=export_view.as_dict(
                        r, columns=columns_to_serialize)
                )
            )
        return to_json_resp(
            FeatureCollection(features),
            as_file=True,
            filename=file_name,
            indent=4
        )
    else:
        try:
            filemanager.delete_recursively(
                str(ROOT_DIR / "backend/static/shapefiles"), excluded_files=[".gitkeep"]
            )

            dir_path = str(ROOT_DIR / "backend/static/shapefiles")

            export_view.as_shape(
                db_cols=db_cols_for_shape,
                data=results,
                geojson_col="geojson",
                dir_path=dir_path,
                file_name=file_name,
            )
            return send_from_directory(dir_path, file_name + ".zip", as_attachment=True)
        except GeonatureApiError as e:
            message = str(e)

        return render_template(
            "error.html",
            error=message,
            redirect=current_app.config["URL_APPLICATION"] +
            "/#/" + blueprint.config['MODULE_URL'],
        )


@blueprint.route("/import", methods=["GET"])
@json_resp
def import_data():
    """
    Generate thousand random obs
    """
    import random
    for i in range(10000):
        sta = DB.session.query(TStationsOcchab).get(1)
        sta_dict = sta.get_geofeature(True)
        prop = sta_dict['properties']
        habitat = prop.pop('t_habitats')[0]
        prop.pop('dataset')
        prop.pop('unique_id_sinp_station')
        prop.pop('id_station')
        geom = sta_dict.pop('geometry')
        shape = asShape(geom)
        two_dimension_geom = remove_third_dimension(shape)
        t = from_shape(two_dimension_geom, srid=4326)
        prop['id_dataset'] = [1, 2, 4, 5, 7][random.randint(0, 4)]
        new_sta = TStationsOcchab(**prop)
        new_sta.geom_4326 = t
        # habitat
        habitat.pop('id_habitat')
        habitat.pop('unique_id_sinp_hab')
        habitat.pop('habref')
        cd_hab_random = [80,
                         81,
                         82,
                         83,
                         84,
                         85,
                         86,
                         79
                         ]
        habitat['cd_hab'] = cd_hab_random[random.randint(0, 7)]
        hab = THabitatsOcchab(**habitat)
        new_sta.t_habitats.append(hab)
        DB.session.add(new_sta)
        DB.session.commit()
    return sta_dict
