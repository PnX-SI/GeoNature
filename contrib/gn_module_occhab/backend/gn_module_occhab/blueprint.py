import datetime
import json
import geojson
from marshmallow import EXCLUDE, INCLUDE

from flask import (
    Blueprint,
    current_app,
    session,
    send_from_directory,
    request,
    render_template,
    jsonify,
    g,
)
from werkzeug.exceptions import BadRequest, Forbidden, NotFound
from geojson import FeatureCollection, Feature
from geoalchemy2.shape import from_shape
from pypnusershub.db.models import User
from shapely.geometry import asShape
from sqlalchemy import func, distinct, select
from sqlalchemy.sql import text
from sqlalchemy.orm import raiseload, joinedload


from pypnnomenclature.models import TNomenclatures
from utils_flask_sqla.response import json_resp, to_csv_resp, to_json_resp
from utils_flask_sqla_geo.utilsgeometry import remove_third_dimension
from utils_flask_sqla_geo.utils import geojsonify
from utils_flask_sqla_geo.generic import GenericTableGeo
from ref_geo.utils import get_local_srid

from geonature.core.gn_permissions import decorators as permissions
from geonature.core.gn_permissions.decorators import login_required
from geonature.core.gn_permissions.tools import get_scopes_by_action
from geonature.core.gn_meta.models import TDatasets as Dataset
from geonature.utils.env import db
from geonature.utils.errors import GeonatureApiError
from geonature.utils import filemanager
from geonature.utils.utilsgeometrytools import export_as_geo_file

from .models import (
    Station,
    OccurenceHabitat,
    DefaultNomenclatureValue,
)
from .schemas import StationSchema


blueprint = Blueprint("occhab", __name__)


@blueprint.route("/stations/", methods=["GET"])
@permissions.check_cruved_scope("R", module_code="OCCHAB", get_scope=True)
def list_stations(scope):
    stations = Station.filter_by_params(request.args)
    stations = Station.filter_by_scope(scope=scope, query=stations)
    stations = stations.order_by(Station.date_min.desc()).options(
        raiseload("*"),
        joinedload(Station.observers),
        joinedload(Station.dataset),
    )
    only = [
        "observers",
        "dataset",
    ]
    if request.args.get("habitats", default=False, type=int):
        only.extend(
            [
                "habitats",
                "habitats.habref",
            ]
        )
        stations = stations.options(
            joinedload(Station.habitats).options(
                joinedload(OccurenceHabitat.habref),
            ),
        )
    if request.args.get("nomenclatures", default=False, type=int):
        only.extend(Station.__nomenclatures__)
        stations = stations.options(*[joinedload(nomenc) for nomenc in Station.__nomenclatures__])
    fmt = request.args.get("format", default="geojson")
    if fmt not in ("json", "geojson"):
        raise BadRequest("Unsupported format")
    if fmt == "json":
        return jsonify(
            StationSchema(only=only).dump(db.session.scalars(stations).unique().all(), many=True)
        )
    elif fmt == "geojson":
        return geojsonify(
            StationSchema(only=only, as_geojson=True).dump(
                db.session.scalars(stations).unique().all(), many=True
            )
        )


@blueprint.route("/stations/<int:id_station>/", methods=["GET"])
@permissions.check_cruved_scope("R", module_code="OCCHAB", get_scope=True)
def get_station(id_station, scope):
    """
    Return one station

    .. :quickref: Occhab;

    :param id_station: the id_station
    :type id_station: int

    :return: a dict representing one station with its habitats
    :rtype dict<TStationsOcchab>

    """
    station = (
        db.session.scalars(
            select(Station)
            .options(
                raiseload("*"),
                joinedload(Station.observers),
                joinedload(Station.dataset),
                joinedload(Station.habitats).options(
                    joinedload(OccurenceHabitat.habref),
                    *[
                        joinedload(getattr(OccurenceHabitat, nomenc))
                        for nomenc in OccurenceHabitat.__nomenclatures__
                    ],
                ),
                *[joinedload(getattr(Station, nomenc)) for nomenc in Station.__nomenclatures__],
            )
            .where(Station.id_station == id_station)
        )
        .unique()
        .one_or_none()
    )
    if not station:
        raise NotFound("")

    if not station.has_instance_permission(scope):
        raise Forbidden("You do not have access to this station.")
    only = [
        "observers",
        "dataset",
        "habitats",
        *Station.__nomenclatures__,
        *[f"habitats.{nomenclature}" for nomenclature in OccurenceHabitat.__nomenclatures__],
        "habitats.habref",
        "+cruved",
    ]
    station_schema = StationSchema(as_geojson=True, only=only)
    return geojsonify(station_schema.dump(station))


@blueprint.route("/stations/", methods=["POST"])
@blueprint.route("/stations/<int:id_station>/", methods=["POST"])
@login_required
def create_or_update_station(id_station=None):
    """
    Post one occhab station (station + habitats)

    .. :quickref: OccHab;

    Post one occhab station (station + habitats)

    :returns: Station as GeoJSON
    """
    scopes = get_scopes_by_action(module_code="OCCHAB")
    if id_station is None:
        station = None  # Station()
        if scopes["C"] < 1:
            raise Forbidden(f"You do not have create permission on stations.")
    else:
        station = db.session.get(Station, id_station)
        if not station.has_instance_permission(scopes["U"]):
            raise Forbidden("You do not have update permission on this station.")
    # Allows habitats
    # Allows only observers.id_role
    # Dataset are not accepted as we expect id_dataset on station directly
    station_schema = StationSchema(
        only=["habitats", "observers.id_role"],
        dump_only=["id_station", "habitats.id_station"],
        unknown=EXCLUDE,
        as_geojson=True,
    )
    station = station_schema.load(request.json, instance=station)
    with db.session.no_autoflush:
        # avoid flushing station.id_dataset before validating dataset!
        dataset = db.session.get(Dataset, station.id_dataset)
        if dataset is None:
            raise BadRequest("Unexisting dataset")
        if not dataset.has_instance_permission(scopes["C"]):
            raise Forbidden("You do not have access to this dataset.")
    db.session.add(station)
    db.session.commit()
    return geojsonify(station_schema.dump(station))


@blueprint.route("/stations/<int:id_station>/", methods=["DELETE"])
@permissions.check_cruved_scope("D", module_code="OCCHAB", get_scope=True)
def delete_station(id_station, scope):
    """
    Delete a station with its habitat and its observers

    .. :quickref: Occhab;

    """
    station = db.get_or_404(Station, id_station)
    if not station.has_instance_permission(scope):
        raise Forbidden("You do not have access to this station.")
    db.session.delete(station)
    db.session.commit()
    return "", 204


@blueprint.route("/export_stations/<export_format>", methods=["POST"])
@permissions.check_cruved_scope("E", module_code="OCCHAB")
def export_all_habitats(
    export_format="csv",
):
    """
    Download all stations
    The route is in post to avoid a too large query string

    .. :quickref: Occhab;

    """

    data = request.get_json()

    export_view = GenericTableGeo(
        tableName="v_export_sinp",
        schemaName="pr_occhab",
        engine=db.engine,
        geometry_field="geom_local",
        srid=get_local_srid(db.session),
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
    results = db.session.scalars(
        select(export_view.tableDef)
        .where(export_view.tableDef.columns.id_station.in_(data["idsStation"]))
        .limit(blueprint.config["NB_MAX_EXPORT"])
    ).all()
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
        dir_name, file_name = export_as_geo_file(
            export_format=export_format,
            export_view=export_view,
            db_cols=db_cols_for_shape,
            geojson_col=None,
            data=results,
            file_name=file_name,
        )
        return send_from_directory(dir_name, file_name, as_attachment=True)


@blueprint.route("/defaultNomenclatures", methods=["GET"])
@login_required
def get_default_nomenclatures():
    """Get default nomenclatures define in occhab module

    .. :quickref: Occhab;

    :returns: dict: {'MODULE_CODE': 'ID_NOMENCLATURE'}

    """
    params = request.args
    organism = 0
    if "organism" in params:
        organism = params["organism"]
    types = request.args.getlist("mnemonique")

    query = select(
        distinct(DefaultNomenclatureValue.mnemonique_type),
        func.pr_occhab.get_default_nomenclature_value(
            DefaultNomenclatureValue.mnemonique_type, organism
        ),
    )
    if len(types) > 0:
        query = query.where(DefaultNomenclatureValue.mnemonique_type.in_(tuple(types)))
    data = db.session.execute(query).all()

    formated_dict = {}
    for d in data:
        nomenclature_obj = None
        if d[1]:
            nomenclature_obj = db.session.get(TNomenclatures, d[1]).as_dict()
        formated_dict[d[0]] = nomenclature_obj
    return formated_dict
