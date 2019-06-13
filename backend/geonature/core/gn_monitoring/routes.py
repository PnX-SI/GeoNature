from flask import Blueprint, request
from sqlalchemy.sql import func
from geojson import FeatureCollection

from geonature.utils.env import DB
from geonature.core.gn_monitoring.models import TBaseSites, corSiteArea, corSiteModule
from geonature.core.ref_geo.models import LAreas
from geonature.utils.utilssqlalchemy import json_resp, get_geojson_feature


routes = Blueprint("gn_monitoring", __name__)


@routes.route("/siteslist", methods=["GET"])
@json_resp
def get_list_sites():
    """
        Return the sites list for an application in a dict {id_base_site, nom site}
        .. :quickref: Monitoring;

        :param id_site: id of base site
        :param type: int
    """
    q = DB.session.query(
        TBaseSites.id_base_site, TBaseSites.base_site_name, TBaseSites.base_site_code
    )
    parameters = request.args

    if parameters.get("name_app"):
        q = q.filter(
            TBaseSites.applications.any(nom_application=parameters.get("name_app"))
        )

    if parameters.get("id_app"):
        q = q.filter(
            TBaseSites.applications.any(id_application=parameters.get("id_app"))
        )

    if parameters.get("id_base_site"):
        q = q.filter(TBaseSites.id_base_site == parameters.get("id_base_site"))

    if parameters.get("base_site_name"):
        q = q.filter(
            TBaseSites.base_site_name.ilike(
                "%{}%".format(parameters.get("base_site_name"))
            )
        )

    data = q.all()
    return [
        {"id_base_site": n.id_base_site, "base_site_name": n.base_site_name}
        for n in data
    ]


@routes.route("/siteslist/<int:id_site>", methods=["GET"])
@json_resp
def get_onelist_site(id_site):
    """
        Get minimal information for a site {id_base_site, nom site}
        .. :quickref: Monitoring;

        :param id_site: id of base site
        :param type: int
    """
    q = DB.session.query(
        TBaseSites.id_base_site, TBaseSites.base_site_name, TBaseSites.base_site_code
    ).filter(TBaseSites.id_base_site == id_site)

    data = q.one()
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

    q = (
        DB.session.query(corSiteArea, func.ST_Transform(LAreas.geom, 4326))
        .join(LAreas, LAreas.id_area == corSiteArea.c.id_area)
        .filter(corSiteArea.c.id_base_site == id_site)
    )

    if "id_area_type" in params:
        q = q.filter(LAreas.id_type == params["id_area_type"])
    if "id_module" in params:
        q = q.join(corSiteModule, corSiteModule.c.id_base_site == id_site).filter(
            corSiteModule.c.id_module == params["id_module"]
        )

    data = q.all()
    features = []
    for d in data:
        feature = get_geojson_feature(d[2])
        feature["id"] = d[1]
        features.append(feature)
    return FeatureCollection(features)
