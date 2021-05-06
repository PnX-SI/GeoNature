import json
from operator import or_

from flask import Blueprint, request, current_app
import requests

from utils_flask_sqla.response import json_resp
from utils_flask_sqla_geo.utilsgeometry import remove_third_dimension

from geonature.core.gn_commons.models import (
    TModules, TParameters, TMobileApps, TPlaces, TAdditionalFields,
)
from geonature.core.gn_commons.repositories import TMediaRepository
from geonature.core.gn_commons.repositories import get_table_location_id
from geonature.core.gn_permissions.models import TObjects
from geonature.utils.env import DB, BACKEND_DIR
from geonature.core.gn_permissions import decorators as permissions
from geonature.core.gn_permissions.tools import cruved_scope_for_user_in_module
from shapely.geometry import asShape
from geoalchemy2.shape import from_shape
from geonature.utils.errors import (
    GeonatureApiError,
)


routes = Blueprint("gn_commons", __name__)

# import routes sub folder
from .validation.routes import *
from .medias.routes import *


@routes.route("/modules", methods=["GET"])
@permissions.check_cruved_scope("R", True)
@json_resp
def get_modules(info_role):
    """
    Return the allowed modules of user from its cruved
    .. :quickref: Commons;

    """
    params = request.args
    q = DB.session.query(TModules)
    if "exclude" in params:
        q = q.filter(TModules.module_code.notin_(params.getlist("exclude")))
    q = q.order_by(TModules.module_order.asc()).order_by(TModules.module_label.asc())
    modules = q.all()
    allowed_modules = []
    for mod in modules:
        app_cruved = cruved_scope_for_user_in_module(
            id_role=info_role.id_role, module_code=mod.module_code
        )[0]
        if app_cruved["R"] != "0":
            module = mod.as_dict()
            module["cruved"] = app_cruved
            if mod.active_frontend:
                # try to get module url from conf for new modules
                if module['module_code'] in current_app.config:
                    module_url = current_app.config[module['module_code']].get('MODULE_URL', mod.module_path)
                else:
                    # fallback for legacy modules
                    module_url = mod.module_path
                module["module_url"] = "{}/#/{}".format(
                    current_app.config["URL_APPLICATION"], module_url
                )
            else:
                module["module_url"] = mod.module_external_url
            allowed_modules.append(module)
    return allowed_modules


@routes.route("/module/<module_code>", methods=["GET"])
@json_resp
def get_module(module_code):
    module = DB.session.query(TModules).filter_by(module_code=module_code).one()
    return module.as_dict()


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
@json_resp
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
                    TAdditionalFields.datasets.any(id_dataset=id_dastaset) for id_dastaset in params.split(',')
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
                TAdditionalFields.objects.any(code_object=code_object) for code_object in params["object_code"].split(",")
                ]
            q = q.filter(or_(*ors))
        else:
            q = q.filter(TAdditionalFields.objects.any(code_object=params["object_code"]))
    print(q)
    return [d.as_dict(True, depth=1) for d in q.all()]



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
    for d in q.all():
        one_app = d.as_dict()
        one_app["settings"] = {}
        #  if local
        if one_app["url_apk"] is None or len(one_app["url_apk"]) == 0:
            try:
                url_apk = "{}/{}".format(
                    current_app.config["API_ENDPOINT"], one_app["relative_path_apk"]
                )
                one_app["url_apk"] = url_apk
                dir_app = "/".join(str(BACKEND_DIR / one_app["relative_path_apk"]).split("/")[:-1])
                settings_file = "{}/settings.json".format(dir_app)
                with open(settings_file) as f:
                    one_app["settings"] = json.load(f)
            except Exception as e:
                raise e

        else:
            #  get config
            dir_app = "/".join(one_app["url_apk"].split("/")[:-1])
            settings_path = "{}/settings.json".format(dir_app)
            resp = requests.get(
                "https://docs.google.com/uc?export=download&id=1hIvdYeBd9NinV7CNcFjWXnBPpImKmYf3"
            )
            try:
                assert resp.status_code == 200
            except AssertionError:
                raise GeonatureApiError(
                    "Impossible to get the settings file at {}".format(settings_path)
                )
            one_app["settings"] = json.loads(resp.content)
        one_app.pop("relative_path_apk")
        mobile_apps.append(one_app)

        # mobile_apps.append(app)
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


#######################################################################################
# ----------------Geofit additional code  routes.py
#######################################################################################
#######################################################################################
# recuperer les lieux
@routes.route("/places", methods=["GET"])
@permissions.check_cruved_scope("R", True)
@json_resp
def get_places(info_role):
    id_role = info_role.id_role
    data = DB.session.query(TPlaces).filter(TPlaces.id_role == id_role).all()
    return [n.as_geofeature("place_geom", "id_place") for n in data]


#######################################################################################
# supprimer un lieu
@routes.route("/place/<int:id_place>", methods=["DELETE"])
@permissions.check_cruved_scope("D", True)
@json_resp
def del_one_place(id_place, info_role):
    place = DB.session.query(TPlaces).filter(TPlaces.id_place == id_place).one_or_none()
    if not place:
        return None
    if info_role.id_role == place.id_role:
        DB.session.query(TPlaces).filter(TPlaces.id_place == id_place).delete()
        DB.session.commit()
        return {"message": "suppression du lieu avec succès", "status": "success"}
    return {
        "message": "Vous n'êtes pas l'utilisateur propriétaire de ce lieu",
        "status": "error",
    }


#######################################################################################
# ajouter un lieu
@routes.route("/place", methods=["POST"])
@permissions.check_cruved_scope("C", True)
@json_resp
def add_one_place(info_role):
    user_id = info_role.id_role

    data = request.get_json()
    place_name = data["properties"]["placeName"]
    place_exists = (
        DB.session.query(TPlaces)
        .filter(TPlaces.place_name == place_name, TPlaces.id_role == user_id)
        .scalar()
    )
    if place_exists:
        return {"message": "Nom du lieu déjà existant", "status": "error"}

    shape = asShape(data["geometry"])
    two_dimension_geom = remove_third_dimension(shape)
    place_geom = from_shape(two_dimension_geom, srid=4326)

    place = TPlaces(id_role=user_id, place_name=place_name, place_geom=place_geom)
    DB.session.add(place)
    DB.session.commit()

    return {"message": "Ajout du lieu avec succés", "status": "success"}


#######################################################################################
#######################################################################################
