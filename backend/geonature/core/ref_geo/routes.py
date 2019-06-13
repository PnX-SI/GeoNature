from flask import Blueprint, request, current_app
from sqlalchemy.sql import text

from geonature.utils.env import DB
from geonature.utils.utilssqlalchemy import json_resp
from geonature.core.ref_geo.models import BibAreasTypes, LiMunicipalities, LAreas

routes = Blueprint("ref_geo", __name__)


@routes.route("/info", methods=["POST"])
@json_resp
def getGeoInfo():
    """
    From a posted geojson, the route return the municipalities intersected
    and the altitude min/max
    .. :quickref: Ref Geo;
    """
    data = dict(request.get_json())
    sql = text(
        """SELECT (ref_geo.fct_get_area_intersection(
        st_setsrid(ST_GeomFromGeoJSON(:geom),4326), :id_area_municipality)).*"""
    )
    try:
        result = DB.engine.execute(
            sql,
            geom=str(data["geometry"]),
            id_area_municipality=current_app.config["BDD"]["id_area_type_municipality"],
        )
    except Exception as e:
        DB.session.rollback()
        raise

    municipality = []
    for row in result:
        municipality.append(
            {
                "id_area": row[0],
                "id_type": row[1],
                "area_code": row[2],
                "area_name": row[3],
            }
        )

    sql = text(
        """SELECT (ref_geo.fct_get_altitude_intersection(
        st_setsrid(ST_GeomFromGeoJSON(:geom),4326))).*
        """
    )
    try:
        result = DB.engine.execute(sql, geom=str(data["geometry"]))
    except Exception as e:
        DB.session.rollback()
        raise
    alt = {}
    for row in result:
        alt = {"altitude_min": row[0], "altitude_max": row[1]}

    return {"municipality": municipality, "altitude": alt}


@routes.route("/areas", methods=["POST"])
@json_resp
def getAreasIntersection():
    """
    From a posted geojson, the route return all the area intersected
    from l_areas
    .. :quickref: Ref Geo;
    """
    data = dict(request.get_json())

    if "id_type" in data:
        id_type = data["id_type"]
    else:
        id_type = None

    sql = text(
        """SELECT (ref_geo.fct_get_area_intersection(
        st_setsrid(ST_GeomFromGeoJSON(:geom),4326),:type)).*"""
    )

    try:
        result = DB.engine.execute(sql, geom=str(data["geometry"]), type=id_type)
    except Exception as e:
        DB.session.rollback()
        raise

    areas = []
    for row in result:
        areas.append(
            {
                "id_area": row[0],
                "id_type": row[1],
                "area_code": row[2],
                "area_name": row[3],
            }
        )

    bibtypesliste = [a["id_type"] for a in areas]
    try:
        bibareatype = (
            DB.session.query(BibAreasTypes)
            .filter(BibAreasTypes.id_type.in_(bibtypesliste))
            .all()
        )
    except Exception as e:
        DB.session.rollback()
        raise
    data = {}
    for b in bibareatype:
        data[b.id_type] = b.as_dict(columns=("type_name", "type_code"))
        data[b.id_type]["areas"] = [a for a in areas if a["id_type"] == b.id_type]

    return data


@routes.route("/municipalities", methods=["GET"])
@json_resp
def get_municipalities():
    """
    Return the municipalities
    .. :quickref: Ref Geo;
    """
    parameters = request.args

    q = DB.session.query(LiMunicipalities).order_by(LiMunicipalities.nom_com.asc())

    if "nom_com" in parameters:
        q = q.filter(
            LiMunicipalities.nom_com.ilike("{}%".format(parameters.get("nom_com")))
        )
    limit = int(parameters.get("limit")) if parameters.get("limit") else 100

    data = q.limit(limit)
    return [d.as_dict() for d in data]


@routes.route("/areas", methods=["GET"])
@json_resp
def get_areas():
    """
        Return the areas of ref_geo.l_areas without geometry
        .. :quickref: Ref Geo;
    """
    # change all args in a list of value
    params = {key: request.args.getlist(key) for key, value in request.args.items()}

    q = DB.session.query(LAreas).order_by(LAreas.area_name.asc())

    if "id_type" in params:
        q = q.filter(LAreas.id_type.in_(params["id_type"]))

    if "area_name" in params:
        q = q.filter(LAreas.area_name.ilike("%{}%".format(params.get("area_name")[0])))

    limit = int(params.get("limit")[0]) if params.get("limit") else 100

    data = q.limit(limit)
    return [d.as_dict() for d in data]

