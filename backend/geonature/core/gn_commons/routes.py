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

from shapely.geometry import shape
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

    exclude = current_app.config["DISABLED_MODULES"].copy()
    if "exclude" in params:
        exclude.extend(params.getlist("exclude"))

    query = (
        db.select(TModules)
        .options(joinedload(TModules.objects))
        .where(TModules.module_code.notin_(exclude))
        .order_by(TModules.module_order.asc())
        .order_by(TModules.module_label.asc())
    )
    modules = db.session.scalars(query).unique().all()

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
    module = db.one_or_404(db.select(TModules).filter_by(module_code=module_code))
    return jsonify(module.as_dict())


@routes.route("/list/parameters", methods=["GET"])
@json_resp
def get_parameters_list():
    """
    Get all parameters from gn_commons.t_parameters

    .. :quickref: Commons;
    """
    return [d.as_dict() for d in db.session.scalars(db.select(TParameters)).all()]


@routes.route("/parameters/<param_name>", methods=["GET"])
@routes.route("/parameters/<param_name>/<int:id_org>", methods=["GET"])
@json_resp
def get_one_parameter(param_name, id_org=None):
    data = DB.session.scalars(
        db.select(TParameters)
        .where(TParameters.parameter_name == param_name)
        .where(TParameters.id_organism == id_org if id_org else True)
    ).one()
    return [data.as_dict()]


@routes.route("/additional_fields", methods=["GET"])
def get_additional_fields():
    params = request.args

    query = db.select(TAdditionalFields).order_by(TAdditionalFields.field_order)
    parse_param_value = lambda param: param.split(",") if len(param.split(",")) > 1 else param
    params = {
        param_key: parse_param_value(param_values) for param_key, param_values in params.items()
    }

    if "id_dataset" in params:
        id_dataset = params["id_dataset"]
        if id_dataset == "null":
            # ~ operator means NOT EXISTS
            query = query.where(~TAdditionalFields.datasets.any())
        elif isinstance(id_dataset, list) and len(id_dataset) > 1:
            query = query.where(
                or_(
                    *[
                        TAdditionalFields.datasets.any(id_dataset=id_dastaset_i)
                        for id_dastaset_i in id_dataset
                    ]
                )
            )
        else:
            query = query.where(TAdditionalFields.datasets.any(id_dataset=id_dataset))

    if "module_code" in params:
        module_code = params["module_code"]
        if isinstance(module_code, list) and len(module_code) > 1:
            query = query.where(
                *[
                    TAdditionalFields.modules.any(module_code=module_code_i)
                    for module_code_i in module_code
                ]
            )
        else:
            query = query.where(TAdditionalFields.modules.any(module_code=module_code))

    if "object_code" in params:
        object_code = params["object_code"]
        if isinstance(object_code, list) and len(object_code) > 1:
            query = query.where(
                *[
                    TAdditionalFields.objects.any(code_object=object_code_i)
                    for object_code_i in object_code
                ]
            )
        else:
            query = query.where(TAdditionalFields.objects.any(code_object=object_code))

    return jsonify(
        [
            d.as_dict(
                fields=["bib_nomenclature_type", "modules", "objects", "datasets", "type_widget"]
            )
            for d in db.session.scalars(query).all()
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
    query = db.select(TMobileApps)
    if "app_code" in request.args:
        query = query.where(TMobileApps.app_code.ilike(request.args["app_code"]))

    data = db.session.scalars(query).all()
    mobile_apps = []
    for app in data:
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
    places = db.session.scalars(
        db.select(TPlaces)
        .filter_by(id_role=g.current_user.id_role)
        .order_by(TPlaces.place_name.asc())
    ).all()
    return jsonify([p.as_geofeature() for p in places])


@routes.route("/place", methods=["POST"])  #  XXX best practices recommend plural nouns
@routes.route("/places", methods=["POST"])
@login_required
def add_place():
    data = request.get_json()
    # FIXME check data validity!
    place_name = data["properties"]["place_name"]
    place_exists = (
        db.select(TPlaces).where(
            TPlaces.place_name == place_name, TPlaces.id_role == g.current_user.id_role
        )
    ).exists()
    if db.session.query(place_exists).scalar():
        raise Conflict("Nom du lieu déjà existant")

    new_shape = shape(data["geometry"])
    two_dimension_geom = remove_third_dimension(new_shape)
    place_geom = from_shape(two_dimension_geom, srid=4326)

    place = TPlaces(id_role=g.current_user.id_role, place_name=place_name, place_geom=place_geom)
    db.session.add(place)
    db.session.commit()

    return jsonify(place.as_geofeature())


@routes.route("/place/<int:id_place>", methods=["DELETE"])
@routes.route("/places/<int:id_place>", methods=["DELETE"])
@login_required
def delete_place(id_place):
    place = db.get_or_404(TPlaces, id_place)
    if g.current_user.id_role != place.id_role:
        raise Forbidden("Vous n'êtes pas l'utilisateur propriétaire de ce lieu")
    db.session.delete(place)
    db.session.commit()
    return "", 204


##############################
