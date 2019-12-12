"""
    Route permettant de manipuler les fichiers
    contenus dans gn_media
"""

from flask import Blueprint, request, current_app

from geonature.core.gn_commons.repositories import TMediaRepository
from geonature.core.gn_commons.models import TModules, TParameters
from geonature.utils.env import DB
from utils_flask_sqla.response import json_resp
from geonature.core.gn_permissions import decorators as permissions
from geonature.core.gn_permissions.tools import cruved_scope_for_user_in_module

routes = Blueprint("gn_commons", __name__)


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
                module["module_url"] = "{}/#/{}".format(
                    current_app.config["URL_APPLICATION"], mod.module_path
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


@routes.route("/media/<int:id_media>", methods=["GET"])
@json_resp
def get_media(id_media):
    """
        Retourne un media
        .. :quickref: Commons;
    """
    m = TMediaRepository(id_media=id_media).media
    if m:
        return m.as_dict()


@routes.route("/media", methods=["POST", "PUT"])
@routes.route("/media/<int:id_media>", methods=["POST", "PUT"])
@json_resp
def insert_or_update_media(id_media=None):
    """
        Insertion ou mise à jour d'un média
        avec prise en compte des fichiers joints

        .. :quickref: Commons;
    """
    if request.files:
        file = request.files["file"]
    else:
        file = None

    data = {}
    if request.form:
        formData = dict(request.form)
        for key in formData:
            data[key] = formData[key]
            if data[key] == 'true':
                data[key] = True
            if data[key] == 'false':
                data[key] = False
    else:
        data = request.get_json(silent=True)

    m = TMediaRepository(
        data=data, file=file, id_media=id_media
    ).create_or_update_media()
    return m.as_dict()


@routes.route("/media/<int:id_media>", methods=["DELETE"])
@json_resp
def delete_media(id_media):
    """
        Suppression d'un media

        .. :quickref: Commons;
    """
    TMediaRepository(id_media=id_media).delete()
    return {"resp": "media {} deleted".format(id_media)}


# Parameters


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
