from flask import Blueprint, request, g
from geonature.core.gn_monitoring.schema import TIndividualsSchema
from geonature.core.gn_permissions.tools import get_scope
from marshmallow import ValidationError, EXCLUDE
from sqlalchemy.sql import func, select
from sqlalchemy.orm import raiseload, joinedload
from geojson import FeatureCollection
from werkzeug.exceptions import BadRequest, Forbidden, NotFound

from geonature.core.gn_commons.models import TModules
from geonature.core.gn_permissions.decorators import _forbidden_message, login_required
from geonature.utils.env import DB
from geonature.core.gn_monitoring.models import (
    TBaseSites,
    TIndividuals,
    corSiteArea,
    corSiteModule,
)

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

    data = DB.session.scalars(query).all()
    features = []
    for d in data:
        feature = get_geojson_feature(d[2])
        feature["id"] = d[1]
        features.append(feature)
    return FeatureCollection(features)


@routes.route("/individuals/<int:id_module>", methods=["GET"])
@login_required
def get_individuals(id_module):
    action = "R"
    object_code = "MONITORINGS_INDIVIDUALS"
    module = DB.session.get(TModules, id_module)
    if module is None:
        raise NotFound("Module not found")
    module_code = module.module_code
    current_user = g.current_user
    max_scope = get_scope(
        action, id_role=current_user.id_role, module_code=module_code, object_code=object_code
    )

    if not max_scope:
        raise Forbidden(description=_forbidden_message(action, module_code, object_code))

    # FIXME: when all sqlalchemy 2.0 PR are merged, update it to fit the good practices
    # like @qfilter etc...
    query = select(TIndividuals).where(TIndividuals.modules.any(TModules.id_module == id_module))
    results = (
        DB.session.scalars(TIndividuals.filter_by_scope(query, max_scope, current_user))
        .unique()
        .all()
    )

    schema = TIndividualsSchema(exclude=["modules"])
    # In the future: paginate the query. But need infinite scroll on
    # select frontend side
    return schema.jsonify(results, many=True)


@routes.route("/individual/<int:id_module>", methods=["POST"])
@login_required
def create_one_individual(id_module: int):
    # Id module is an optional parameter to associate an individual
    # to a module
    action = "C"
    object_code = "MONITORINGS_INDIVIDUALS"
    module = DB.session.get(TModules, id_module)
    if module is None:
        raise NotFound("Module not found")
    module_code = module.module_code
    current_user = g.current_user
    max_scope = get_scope(
        action, id_role=current_user.id_role, module_code=module_code, object_code=object_code
    )

    if not max_scope:
        raise Forbidden(description=_forbidden_message(action, module_code, object_code))

    # Exclude id_digitiser since it is set by the current user
    individual_schema = TIndividualsSchema(exclude=["id_digitiser"], unknown=EXCLUDE)
    individual_instance = TIndividuals(id_digitiser=g.current_user.id_role)
    try:
        individual = individual_schema.load(data=request.get_json(), instance=individual_instance)
    except ValidationError as error:
        raise BadRequest(error.messages)

    individual.modules = [module]
    DB.session.add(individual)
    DB.session.commit()
    return individual_schema.jsonify(individual)
