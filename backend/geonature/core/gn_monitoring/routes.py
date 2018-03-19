import os
import logging

from flask import Blueprint, request, current_app, jsonify

from geonature.core.gn_monitoring.config_manager import generate_config

# from pypnusershub import routes as fnauth


routes = Blueprint('gn_monitoring', __name__)

# get the root logger
log = logging.getLogger()


@routes.route('/config', methods=['GET'])
def get_config():
    '''
        Retourne les fichiers de configuration en yml
        après les avoir parsé
    '''
    app_name = request.args.get('app', 'base_app')
    vue_name = request.args.getlist('vue')
    if not vue_name:
        vue_name = ['default']
    filename = '{}.yml'.format(os.path.abspath(
        os.path.join(
            current_app.config['BASE_DIR'], 'static',
            'configs', app_name, *vue_name
        )
    ))
    config_file = generate_config(filename)
    return jsonify(config_file)
