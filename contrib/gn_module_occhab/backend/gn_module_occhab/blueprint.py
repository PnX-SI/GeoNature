import datetime
import json

from flask import (
    Blueprint,
    current_app,
    session,
    send_from_directory,
    request,
    render_template,
)
from geojson import FeatureCollection, Feature
from geoalchemy2.shape import from_shape
from pypnusershub.db.models import User
from shapely.geometry import asShape
from sqlalchemy import func, distinct
from sqlalchemy.sql import text


from pypnnomenclature.models import TNomenclatures
from utils_flask_sqla.response import json_resp, to_csv_resp, to_json_resp
from utils_flask_sqla_geo.utilsgeometry import remove_third_dimension
from utils_flask_sqla_geo.generic import GenericTableGeo

from geonature.core.gn_permissions import decorators as permissions
from geonature.core.gn_permissions.tools import get_or_fetch_user_cruved
from geonature.core.gn_commons.models import TModules
from geonature.utils.env import DB, ROOT_DIR
from geonature.utils.errors import GeonatureApiError
from geonature.utils import filemanager
from geonature.utils.utilsgeometrytools import export_as_geo_file

from .models import (
    OneStation,
    TStationsOcchab,
    THabitatsOcchab,
    DefaultNomenclaturesValue,
)
from .query import filter_query_with_cruved

blueprint = Blueprint("occhab", __name__)


@blueprint.route("/station", methods=["POST"])
@permissions.check_cruved_scope("C", True, module_code="OCCHAB")
@json_resp
def post_station(info_role):
    """
    Post one occhab station (station + habitats)

    .. :quickref: OccHab;

    Post one occhab station (station + habitats)

    :returns: GeoJson<TStationsOcchab>
    """
    data = dict(request.get_json())
    occ_hab = None
    properties = data["properties"]
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
            DB.session.query(User)
            .filter(User.id_role.in_(list(map(lambda user: user["id_role"], observers_list))))
            .all()
        )
        for o in observers:
            station.observers.append(o)
    t_hab_list_object = []
    if occ_hab is not None:
        for occ in occ_hab:
            if occ["id_habitat"] is None:
                occ.pop("id_habitat")
            data_attr = [k for k in occ]
            for att in data_attr:
                if not getattr(THabitatsOcchab, att, False):
                    occ.pop(att)
            t_hab_list_object.append(THabitatsOcchab(**occ))

    # set habitat complexe
    station.is_habitat_complex = len(t_hab_list_object) > 1

    station.t_habitats = t_hab_list_object
    if station.id_station:
        user_cruved = get_or_fetch_user_cruved(
            session=session, id_role=info_role.id_role, module_code="OCCHAB"
        )
        # check if allowed to update or raise 403
        station.check_if_allowed(info_role, "U", user_cruved["U"])
        DB.session.merge(station)
    else:
        DB.session.add(station)
    DB.session.commit()
    return station.get_geofeature()


@blueprint.route("/station/<int:id_station>", methods=["GET"])
@permissions.check_cruved_scope("R", True, module_code="OCCHAB")
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
    station_geojson = station.get_geofeature()
    user_cruved = get_or_fetch_user_cruved(
        session=session, id_role=info_role.id_role, module_code="OCCHAB"
    )
    station_geojson["properties"]["rights"] = station.get_model_cruved(info_role, user_cruved)
    return station_geojson


@blueprint.route("/station/<int:id_station>", methods=["DELETE"])
@permissions.check_cruved_scope("D", True, module_code="OCCHAB")
@json_resp
def delete_one_station(id_station, info_role):
    """
    Delete a station with its habitat and its observers

    .. :quickref: Occhab;

    """
    station = DB.session.query(TStationsOcchab).get(id_station)
    is_allowed = station.user_is_allowed_to(info_role, info_role.value_filter)
    if is_allowed:
        DB.session.delete(station)
        DB.session.commit()
        return station.get_geofeature()
    else:
        return "Forbidden", 403


@blueprint.route("/stations", methods=["GET"])
@permissions.check_cruved_scope("R", True, module_code="OCCHAB")
@json_resp
def get_all_habitats(info_role):
    """
    Get all stations with their hab

    .. :quickref: Occhab;

    """
    params = request.args.to_dict()
    q = DB.session.query(TStationsOcchab)

    if "id_dataset" in params:
        q = q.filter(TStationsOcchab.id_dataset == params["id_dataset"])

    if "cd_hab" in params:
        q = q.filter(TStationsOcchab.t_habitats.any(cd_hab=params["cd_hab"]))

    if "date_low" in params:
        q = q.filter(TStationsOcchab.date_min >= params.pop("date_low"))

    if "date_up" in params:
        q = q.filter(TStationsOcchab.date_max <= params.pop("date_up"))

    q = filter_query_with_cruved(TStationsOcchab, q, info_role)
    q = q.order_by(TStationsOcchab.date_min.desc())
    limit = request.args.get("limit", None) or blueprint.config["NB_MAX_MAP_LIST"]
    data = q.limit(limit)

    user_cruved = get_or_fetch_user_cruved(
        session=session, id_role=info_role.id_role, module_code="OCCHAB"
    )
    feature_list = []
    for d in data:
        feature = d.get_geofeature()
        feature["properties"]["rights"] = d.get_model_cruved(info_role, user_cruved)

        feature_list.append(feature)
    return FeatureCollection(feature_list)


@blueprint.route("/export_stations/<export_format>", methods=["POST"])
@permissions.check_cruved_scope("E", True, module_code="OCCHAB")
def export_all_habitats(
    info_role,
    export_format="csv",
):
    """
    Download all stations
    The route is in post to avoid a too large query string

    .. :quickref: Occhab;

    """

    data = request.get_json()

    DB.session.execute(func.Find_SRID("gn_synthese", "synthese", "the_geom_local")).scalar()
    export_view = GenericTableGeo(
        tableName="v_export_sinp",
        schemaName="pr_occhab",
        engine=DB.engine,
        geometry_field="geom_local",
        srid=srid,
    )

    file_name = datetime.datetime.now().strftime("%Y_%m_%d_%Hh%Mm%S")
    file_name = filemanager.removeDisallowedFilenameChars(file_name)
    db_cols_for_shape = []
    columns_to_serialize = []
    for db_col in export_view.db_cols:
        if db_col.key in blueprint.config["EXPORT_COLUMS"]:
            if db_col.key != "geometry":
                db_cols_for_shape.append(db_col)
            columns_to_serialize.append(db_col.key)
    results = (
        DB.session.query(export_view.tableDef)
        .filter(export_view.tableDef.columns.id_station.in_(data["idsStation"]))
        .limit(blueprint.config["NB_MAX_EXPORT"])
    )
    if export_format == "csv":
        formated_data = [export_view.as_dict(d, fields=[]) for d in results]
        return to_csv_resp(file_name, formated_data, separator=";", columns=columns_to_serialize)
    elif export_format == "geojson":
        features = []
        for r in results:
            features.append(
                Feature(
                    geometry=json.loads(r.geojson),
                    properties=export_view.as_dict(r, fields=columns_to_serialize),
                )
            )
        return to_json_resp(
            FeatureCollection(features), as_file=True, filename=file_name, indent=4
        )
    else:
        try:
            dir_name, file_name = export_as_geo_file(
                export_format=export_format,
                export_view=export_view,
                db_cols=db_cols_for_shape,
                geojson_col=None,
                data=results,
                file_name=file_name,
            )
            return send_from_directory(dir_name, file_name, as_attachment=True)

        except GeonatureApiError as e:
            message = str(e)

        module_url = TModules.query.filter_by(module_code="OCCHAB").one().module_path
        return render_template(
            "error.html",
            error=message,
            redirect=current_app.config["URL_APPLICATION"] + "/#/" + module_url,
        )


@blueprint.route("/defaultNomenclatures", methods=["GET"])
@json_resp
def getDefaultNomenclatures():
    """Get default nomenclatures define in occhab module

    .. :quickref: Occhab;

    :returns: dict: {'MODULE_CODE': 'ID_NOMENCLATURE'}

    """
    params = request.args
    organism = 0
    if "organism" in params:
        organism = params["organism"]
    types = request.args.getlist("mnemonique")

    q = DB.session.query(
        distinct(DefaultNomenclaturesValue.mnemonique_type),
        func.pr_occhab.get_default_nomenclature_value(
            DefaultNomenclaturesValue.mnemonique_type, organism
        ),
    )
    if len(types) > 0:
        q = q.filter(DefaultNomenclaturesValue.mnemonique_type.in_(tuple(types)))
    data = q.all()

    formated_dict = {}
    for d in data:
        nomenclature_obj = None
        if d[1]:
            nomenclature_obj = DB.session.query(TNomenclatures).get(d[1]).as_dict()
        formated_dict[d[0]] = nomenclature_obj
    return formated_dict

    # TODO
    # @blueprint.route("/stations/dataset/<int:id_dataset>", methods=["POST", "GET"])
    # @json_resp
    # def getStationsDataset(id_dataset):
    """
    Get all stations of a dataset
    """


#     data = dict(request.get_json())
#     sql = text("""
#         SELECT geom_4326
#         FROM pr_occhab.t_stations
#         WHERE id_dataset = :id_dataset AND geom_4326 <> ST_MakeEnvelope(
#             :xmin, :ymin, :xmax, :ymax
#         LIMIT 50
#         )
#     """)
#     DB.engine.execute(
#         sql,
#         id_dataset=id_dataset,
#         xmin="",
#         ymin="",
#         xmax="",
#         ymax="",
#     )
