import os
import logging

from flask import Blueprint, request, current_app, jsonify

from sqlalchemy.sql import text

from geonature.utils.env import DB
from geonature.core.gn_monitoring.config_manager import generate_config
from geonature.utils.utilssqlalchemy import json_resp, GenericTable


# from pypnusershub import routes as fnauth


routes = Blueprint('gn_monitoring', __name__)

# get the root logger
log = logging.getLogger()


@routes.route('/config', methods=['GET'])
def get_config():
    '''
        Retourne les fichiers de configuration en toml
        après les avoir parsé
    '''
    app_name = request.args.get('app', 'base_app')
    vue_name = request.args.getlist('vue')
    if not vue_name:
        vue_name = ['default']
    filename = '{}.toml'.format(os.path.abspath(
        os.path.join(
            current_app.config['BASE_DIR'], 'static',
            'configs', app_name, *vue_name
        )
    ))
    config_file = generate_config(filename)
    return jsonify(config_file)


@routes.route('/genericview/<view_schema>/<view_name>', methods=['GET'])
@json_resp
def get_generic_view(view_schema, view_name):
    '''
        Service générique permettant de requeter une vue

        Paramètres :
            limit : nombre limit de résultats à retourner
            offset : numéro de page
            nom_colonne=val : Si nom_colonne fait partie des colonnes de la vue
                alors filtre nom_colonne=val
            ilike_nom_colonne=val : Si nom_colonne fait partie des colonnes de la vue
                et que la colonne est de type texte
                alors filtre nom_colonne ilike '%val%'
            filtre de date : @TODO
            filter numérique lower greater : @TODO
            order by : @TODO
    '''
    parameters = request.args

    limit = int(parameters.get('limit')) if parameters.get('limit') else 100
    page = int(parameters.get('offset')) if parameters.get('offset') else 0

    # Consctruction de la vue
    # @TODO créer un système de mise en cache des vues mappées
    view = GenericTable(view_name, view_schema)

    # Construction de la requête en fonction des filtres
    q = DB.session.query(view.tableDef)

    for f in parameters:
        if f in view.columns:
            q = q.filter(view.tableDef.columns[f] == parameters.get(f))

        if f.startswith('ilike_'):
            col = view.tableDef.columns[f[6:]]
            if col.type.__class__.__name__ == "TEXT":
                q = q.filter(col.ilike('%{}%'.format(parameters.get(f))))

    # Récupération des résulats
    data = q.limit(limit).offset(page * limit).all()

    return [view.serialize(d) for d in data]
