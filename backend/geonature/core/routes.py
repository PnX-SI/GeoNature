"""
    Définition de routes "génériques"
    c-a-d pouvant servir à tous module
"""

import os
import logging

from flask import Blueprint, request, current_app, jsonify

from geonature.utils.env import DB
from geonature.core.gn_monitoring.config_manager import generate_config

from geonature.core.gn_permissions import decorators as permissions

routes = Blueprint("core", __name__)

# get the root logger
log = logging.getLogger()


@routes.route("/config", methods=["GET"])
@permissions.check_cruved_scope("R", False, module_code="SUIVIS")
def get_config():
    """
    Parse and return configuration files as toml
    .. :quickref: Generic;
    """
    app_name = request.args.get("app", "base_app")
    vue_name = request.args.getlist("vue")

    base_path = os.path.abspath(os.path.join(current_app.static_folder, "configs"))
    conf_path = os.path.abspath(os.path.join(base_path, app_name, *vue_name))
    # test : file inside config folder
    if not conf_path.startswith(base_path):
        return "Not a valid config path", 404

    if not vue_name:
        vue_name = ["default"]
    filename = "{}.toml".format(conf_path)
    config_file = generate_config(filename)
    return jsonify(config_file)
