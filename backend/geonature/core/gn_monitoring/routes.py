from flask import Blueprint, request
from sqlalchemy.sql import func
from geojson import FeatureCollection

from geonature.utils.env import DB
from geonature.core.gn_monitoring.models import TBaseSites, corSiteArea, corSiteModule

from utils_flask_sqla.response import json_resp
from utils_flask_sqla_geo.generic import get_geojson_feature
from ref_geo.models import LAreas
from sqlalchemy import select


routes = Blueprint("gn_monitoring", __name__)


@routes.route("/siteslist", methods=["GET"])
@json_resp
def get_list_sites():
    """
    Return the sites list for an application in a dict {id_base_site, nom site}
    .. :quickref: Monitoring;

    :param id_base_site: id of base site
    :param module_code: code of the module
    :param id_module: id of the module
    :param base_site_name: part of the name of the site
    :param type: int
    """
    query = select(TBaseSites)
    parameters = request.args

    if parameters.get("module_code"):
        query = query.where(TBaseSites.modules.any(module_code=parameters.get("module_code")))

    if parameters.get("id_module"):
        query = query.where(TBaseSites.modules.any(id_module=parameters.get("id_module")))

    if parameters.get("id_base_site"):
        query = query.where(TBaseSites.id_base_site == parameters.get("id_base_site"))

    if parameters.get("base_site_name"):
        query = query.where(
            TBaseSites.base_site_name.ilike("%{}%".format(parameters.get("base_site_name")))
        )

    data = DB.session.scalars(query).all()
    return [n.as_dict(fields=["id_base_site", "base_site_name"]) for n in data]


@routes.route("/siteslist/<int:id_site>", methods=["GET"])
@json_resp
def get_onelist_site(id_site):
    """
    Get minimal information for a site {id_base_site, nom site}
    .. :quickref: Monitoring;

    :param id_site: id of base site
    :param type: int
    """
    query = select(
        TBaseSites.id_base_site, TBaseSites.base_site_name, TBaseSites.base_site_code
    ).where(TBaseSites.id_base_site == id_site)

    data = DB.session.execute(query).scalar_one()
    return {"id_base_site": data.id_base_site, "base_site_name": data.base_site_name}


@routes.route("/siteareas/<int:id_site>", methods=["GET"])
@json_resp
def get_site_areas(id_site):
    """
    Get areas of a site from cor_site_area as geojson

    .. :quickref: Monitoring;

    :param id_module: int
    :type id_module: int
    :param id_area_type:
    :type id_area_type: int
    """
    params = request.args

    query = (
        select(corSiteArea, func.ST_Transform(LAreas.geom, 4326))
        .join(LAreas, LAreas.id_area == corSiteArea.c.id_area)
        .where(corSiteArea.c.id_base_site == id_site)
    )

    if "id_area_type" in params:
        query = query.where(LAreas.id_type == params["id_area_type"])
    if "id_module" in params:
        query = query.join(corSiteModule, corSiteModule.c.id_base_site == id_site).where(
            corSiteModule.c.id_module == params["id_module"]
        )

    data = DB.session.execute(query).all()
    features = []
    for d in data:
        feature = get_geojson_feature(d[2])
        feature["id"] = d[1]
        features.append(feature)
    return FeatureCollection(features)
