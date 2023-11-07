import json
from operator import or_
from pathlib import Path

from flask import Blueprint, request, current_app, g, url_for
from flask.json import jsonify
from werkzeug.exceptions import Forbidden, Conflict
import requests
from sqlalchemy.orm import joinedload

from utils_flask_sqla.response import json_resp
from utils_flask_sqla_geo.utilsgeometry import remove_third_dimension

from geonature.core.gn_commons.models import (
    TModules,
    TParameters,
    TMobileApps,
    TPlaces,
    TAdditionalFields,
)
from geonature.core.gn_commons.repositories import TMediaRepository
from geonature.core.gn_commons.repositories import get_table_location_id
from geonature.utils.env import DB, db, BACKEND_DIR
from geonature.utils.config import config_frontend, config
from geonature.core.gn_permissions import decorators as permissions
from geonature.core.gn_permissions.decorators import login_required
from geonature.core.gn_permissions.tools import get_scope
import geonature.core.gn_commons.tasks  # noqa: F401

from shapely.geometry import asShape
from geoalchemy2.shape import from_shape
from geonature.utils.errors import (
    GeonatureApiError,
)


routes = Blueprint("gn_commons", __name__)

# import routes sub folder
from .validation.routes import *
from .medias.routes import *


@routes.route("/config", methods=["GET"])
def config_route():
    """
    Returns geonature configuration
    """
    return config_frontend


@routes.route("/modules", methods=["GET"])
@login_required
def list_modules():
    """
    Return the allowed modules of user from its cruved
    .. :quickref: Commons;

    """
    params = request.args
    q = TModules.query.options(joinedload(TModules.objects))
    exclude = current_app.config["DISABLED_MODULES"].copy()
    if "exclude" in params:
        exclude.extend(params.getlist("exclude"))
    q = q.filter(TModules.module_code.notin_(exclude))
    q = q.order_by(TModules.module_order.asc()).order_by(TModules.module_label.asc())
    modules = q.all()
    allowed_modules = []
    for module in modules:
        module_allowed = False
        # HACK : on a besoin d'avoir le module GeoNature en front pour l'URL de la doc
        if module.module_code == "GEONATURE":
            module_allowed = True
        module_dict = module.as_dict(fields=["objects"])
        # TODO : use has_any_permissions instead - must refactor the front
        module_dict["cruved"] = {
            action: get_scope(action, module_code=module.module_code, bypass_warning=True)
            for action in "CRUVED"
        }
        if any(module_dict["cruved"].values()):
            module_allowed = True
        if module.active_frontend:
            module_dict["module_url"] = "{}/#/{}".format(
                current_app.config["URL_APPLICATION"], module.module_path
            )
        else:
            module_dict["module_url"] = module.module_external_url
        module_dict["module_objects"] = {}
        # get cruved for each object
        for obj_dict in module_dict["objects"]:
            obj_code = obj_dict["code_object"]
            obj_dict["cruved"] = {
                action: get_scope(
                    action,
                    module_code=module.module_code,
                    object_code=obj_code,
                    bypass_warning=True,
                )
                for action in "CRUVED"
            }
            if any(obj_dict["cruved"].values()):
                module_allowed = True
            module_dict["module_objects"][obj_code] = obj_dict
        if module_allowed:
            allowed_modules.append(module_dict)
    return jsonify(allowed_modules)


@routes.route("/module/<module_code>", methods=["GET"])
def get_module(module_code):
    module = TModules.query.filter_by(module_code=module_code).first_or_404()
    return jsonify(module.as_dict())


@routes.route("/list/parameters", methods=["GET"])
@json_resp
def get_parameters_list():
    """
    Get all parameters from gn_commons.t_parameters

    .. :quickref: Commons;
    """
    q = DB.session.query(TParameters)
    data = q.all()

    return [d.as_dict() for d in data]


@routes.route("/parameters/<param_name>", methods=["GET"])
@routes.route("/parameters/<param_name>/<int:id_org>", methods=["GET"])
@json_resp
def get_one_parameter(param_name, id_org=None):
    q = DB.session.query(TParameters)
    q = q.filter(TParameters.parameter_name == param_name)
    if id_org:
        q = q.filter(TParameters.id_organism == id_org)

    data = q.all()
    return [d.as_dict() for d in data]


@routes.route("/additional_fields", methods=["GET"])
def get_additional_fields():
    params = request.args
    q = DB.session.query(TAdditionalFields).order_by(TAdditionalFields.field_order)
    if "id_dataset" in params:
        if params["id_dataset"] == "null":
            # ~ operator means NOT EXISTS
            q = q.filter(~TAdditionalFields.datasets.any())
        else:
            if len(params["id_dataset"].split(",")) > 1:
                ors = [
                    TAdditionalFields.datasets.any(id_dataset=id_dastaset)
                    for id_dastaset in params.split(",")
                ]
                q = q.filter(or_(*ors))
            else:
                q = q.filter(TAdditionalFields.datasets.any(id_dataset=params["id_dataset"]))
    if "module_code" in params:
        if len(params["module_code"].split(",")) > 1:
            ors = [
                TAdditionalFields.modules.any(module_code=module_code)
                for module_code in params["module_code"].split(",")
            ]

            q = q.filter(or_(*ors))
        else:
            q = q.filter(TAdditionalFields.modules.any(module_code=params["module_code"]))

    if "object_code" in params:
        if len(params["object_code"].split(",")) > 1:
            ors = [
                TAdditionalFields.objects.any(code_object=code_object)
                for code_object in params["object_code"].split(",")
            ]
            q = q.filter(or_(*ors))
        else:
            q = q.filter(TAdditionalFields.objects.any(code_object=params["object_code"]))
    return jsonify(
        [
            d.as_dict(
                fields=["bib_nomenclature_type", "modules", "objects", "datasets", "type_widget"]
            )
            for d in q.all()
        ]
    )


@routes.route("/t_mobile_apps", methods=["GET"])
@json_resp
def get_t_mobile_apps():
    """
    Get all mobile applications

    .. :quickref: Commons;

    :query str app_code: the app code
    :returns: Array<dict<TMobileApps>>
    """
    params = request.args
    q = DB.session.query(TMobileApps)
    if "app_code" in request.args:
        q = q.filter(TMobileApps.app_code.ilike(params["app_code"]))
    mobile_apps = []
    for app in q.all():
        app_dict = app.as_dict(exclude=["relative_path_apk"])
        app_dict["settings"] = {}
        #  if local
        if app.relative_path_apk:
            relative_apk_path = Path("mobile", app.relative_path_apk)
            app_dict["url_apk"] = url_for("media", filename=str(relative_apk_path), _external=True)
        relative_settings_path = Path(f"mobile/{app.app_code.lower()}/settings.json")
        app_dict["url_settings"] = url_for(
            "media", filename=relative_settings_path, _external=True
        )
        settings_file = Path(current_app.config["MEDIA_FOLDER"]) / relative_settings_path
        with settings_file.open() as f:
            app_dict["settings"] = json.load(f)
        mobile_apps.append(app_dict)
    if len(mobile_apps) == 1:
        return mobile_apps[0]
    return mobile_apps


# Table Location


@routes.route("/get_id_table_location/<string:schema_dot_table>", methods=["GET"])
@json_resp
# schema_dot_table gn_commons.t_modules
def api_get_id_table_location(schema_dot_table):
    schema_name = schema_dot_table.split(".")[0]
    table_name = schema_dot_table.split(".")[1]
    return get_table_location_id(schema_name, table_name)


##############################
# Gestion des lieux (places) #
##############################
@routes.route("/places", methods=["GET"])
@login_required
def list_places():
    places = TPlaces.query.filter_by(id_role=g.current_user.id_role).all()
    return jsonify([p.as_geofeature() for p in places])


@routes.route("/place", methods=["POST"])  #  XXX best practices recommend plural nouns
@routes.route("/places", methods=["POST"])
@login_required
def add_place():
    data = request.get_json()
    # FIXME check data validity!
    place_name = data["properties"]["place_name"]
    place_exists = TPlaces.query.filter(
        TPlaces.place_name == place_name, TPlaces.id_role == g.current_user.id_role
    ).exists()
    if db.session.query(place_exists).scalar():
        raise Conflict("Nom du lieu déjà existant")

    shape = asShape(data["geometry"])
    two_dimension_geom = remove_third_dimension(shape)
    place_geom = from_shape(two_dimension_geom, srid=4326)

    place = TPlaces(id_role=g.current_user.id_role, place_name=place_name, place_geom=place_geom)
    db.session.add(place)
    db.session.commit()

    return jsonify(place.as_geofeature())


@routes.route(
    "/place/<int:id_place>", methods=["DELETE"]
)  # XXX best practices recommend plural nouns
@routes.route("/places/<int:id_place>", methods=["DELETE"])
@login_required
def delete_place(id_place):
    place = TPlaces.query.get_or_404(id_place)
    if g.current_user.id_role != place.id_role:
        raise Forbidden("Vous n'êtes pas l'utilisateur propriétaire de ce lieu")
    db.session.delete(place)
    db.session.commit()
    return "", 204


##############################
