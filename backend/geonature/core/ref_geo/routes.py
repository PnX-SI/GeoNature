from itertools import groupby
import json

from flask import Blueprint, request, current_app
from flask.json import jsonify
import sqlalchemy as sa
from sqlalchemy import func
from sqlalchemy.sql import text
from sqlalchemy.orm import joinedload
from werkzeug.exceptions import BadRequest

from geonature.utils.env import db

from ref_geo.models import BibAreasTypes, LiMunicipalities, LAreas
from utils_flask_sqla.response import json_resp


routes = Blueprint("ref_geo", __name__)

altitude_stmt = sa.select([sa.column("altitude_min"), sa.column("altitude_max"),]).select_from(
    func.ref_geo.fct_get_altitude_intersection(
        func.ST_SetSRID(
            func.ST_GeomFromGeoJSON(sa.bindparam("geojson")),
            4326,
        ),
    )
)

geojson_intersect_filter = func.ST_Intersects(
    LAreas.geom,
    func.ST_Transform(
        func.ST_SetSRID(func.ST_GeomFromGeoJSON(sa.bindparam("geojson")), 4326),
        func.Find_SRID("ref_geo", "l_areas", "geom"),
    ),
)

area_size_func = func.ST_Area(
    func.ST_Transform(
        func.ST_SetSrid(
            func.ST_GeomFromGeoJSON(sa.bindparam("geojson")),
            4326,
        ),
        func.Find_SRID("ref_geo", "l_areas", "geom"),
    )
)


@routes.route("/info", methods=["POST"])
def getGeoInfo():
    """
    From a posted geojson, the route return the municipalities intersected
    and the altitude min/max

    .. :quickref: Ref Geo;
    """
    if request.json is None:
        raise BadRequest("Missing request payload")
    try:
        geojson = request.json["geometry"]
    except KeyError:
        raise BadRequest("Missing 'geometry' in request payload")
    geojson = json.dumps(geojson)

    areas = LAreas.query.filter_by(enable=True).filter(
        geojson_intersect_filter.params(geojson=geojson)
    )
    if "area_type" in request.json:
        areas = areas.join(BibAreasTypes).filter_by(type_code=request.json["area_type"])
    elif "id_type" in request.json:
        try:
            id_type = int(request.json["id_type"])
        except ValueError:
            raise BadRequest("Parameter 'id_type' must be an integer")
        areas = areas.filter_by(id_type=id_type)

    altitude = db.session.execute(altitude_stmt, params={"geojson": geojson}).fetchone()

    return jsonify(
        {
            "areas": [
                area.as_dict(fields=["id_area", "id_type", "area_code", "area_name"])
                for area in areas.all()
            ],
            "altitude": altitude,
        }
    )


@routes.route("/altitude", methods=["POST"])
def getAltitude():
    """
    From a posted geojson get the altitude min/max

    .. :quickref: Ref Geo;
    """
    if request.json is None:
        raise BadRequest("Missing request payload")
    try:
        geojson = request.json["geometry"]
    except KeyError:
        raise BadRequest("Missing 'geometry' in request payload")
    geojson = json.dumps(geojson)

    altitude = db.session.execute(altitude_stmt, params={"geojson": geojson}).fetchone()
    return jsonify(altitude)


@routes.route("/areas", methods=["POST"])
def getAreasIntersection():
    """
    From a posted geojson, the route return all the area intersected
    from l_areas
    .. :quickref: Ref Geo;
    """
    if request.json is None:
        raise BadRequest("Missing request payload")
    try:
        geojson = request.json["geometry"]
    except KeyError:
        raise BadRequest("Missing 'geometry' in request payload")
    geojson = json.dumps(geojson)

    areas = LAreas.query.filter_by(enable=True).filter(
        geojson_intersect_filter.params(geojson=geojson)
    )
    if "area_type" in request.json:
        areas = areas.join(BibAreasTypes).filter_by(type_code=request.json["area_type"])
    elif "id_type" in request.json:
        try:
            id_type = int(request.json["id_type"])
        except ValueError:
            raise BadRequest("Parameter 'id_type' must be an integer")
        areas = areas.filter_by(id_type=id_type)
    areas = areas.order_by(LAreas.id_type)

    response = {}
    for id_type, _areas in groupby(areas.all(), key=lambda area: area.id_type):
        _areas = list(_areas)
        response[id_type] = _areas[0].area_type.as_dict(fields=["type_code", "type_name"])
        response[id_type].update(
            {
                "areas": [
                    area.as_dict(
                        fields=[
                            "area_code",
                            "area_name",
                            "id_area",
                            "id_type",
                        ]
                    )
                    for area in _areas
                ],
            }
        )

    return jsonify(response)


@routes.route("/municipalities", methods=["GET"])
@json_resp
def get_municipalities():
    """
    Return the municipalities
    .. :quickref: Ref Geo;
    """
    parameters = request.args

    q = db.session.query(LiMunicipalities).order_by(LiMunicipalities.nom_com.asc())

    if "nom_com" in parameters:
        q = q.filter(LiMunicipalities.nom_com.ilike("{}%".format(parameters.get("nom_com"))))
    limit = int(parameters.get("limit")) if parameters.get("limit") else 100

    data = q.limit(limit)
    return [d.as_dict() for d in data]


@routes.route("/areas", methods=["GET"])
def get_areas():
    """
    Return the areas of ref_geo.l_areas
    .. :quickref: Ref Geo;
    """
    # change all args in a list of value
    params = {key: request.args.getlist(key) for key, value in request.args.items()}

    q = (
        db.session.query(LAreas)
        .options(joinedload("area_type").load_only("type_code"))
        .order_by(LAreas.area_name.asc())
    )

    if "enable" in params:
        enable_param = params["enable"][0].lower()
        accepted_enable_values = ["true", "false", "all"]
        if enable_param not in accepted_enable_values:
            response = {
                "message": f"Le paramètre 'enable' accepte seulement les valeurs: {', '.join(accepted_enable_values)}.",
                "status": "warning",
            }
            return response, 400
        if enable_param == "true":
            q = q.filter(LAreas.enable == True)
        elif enable_param == "false":
            q = q.filter(LAreas.enable == False)
    else:
        q = q.filter(LAreas.enable == True)

    if "id_type" in params:
        q = q.filter(LAreas.id_type.in_(params["id_type"]))

    if "type_code" in params:
        q = q.filter(LAreas.area_type.has(BibAreasTypes.type_code.in_(params["type_code"])))

    if "area_name" in params:
        q = q.filter(LAreas.area_name.ilike("%{}%".format(params.get("area_name")[0])))

    limit = int(params.get("limit")[0]) if params.get("limit") else 100

    data = q.limit(limit)
    return jsonify([d.as_dict(fields=["area_type.type_code"]) for d in data])


@routes.route("/area_size", methods=["Post"])
def get_area_size():
    """
    Return the area size from a given geojson

    .. :quickref: Ref Geo;

    :returns: An area size (int)
    """
    if request.json is None:
        raise BadRequest("Missing request payload")
    try:
        geojson = request.json["geometry"]
    except KeyError:
        raise BadRequest("Missing 'geometry' in request payload")
    geojson = json.dumps(geojson)

    query = db.session.query(area_size_func.params(geojson=geojson))

    return jsonify(db.session.execute(query).scalar())
