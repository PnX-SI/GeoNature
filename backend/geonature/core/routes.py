"""
    Définition de routes "génériques"
    c-a-d pouvant servir à tous module
"""

import os
import logging

from flask import Blueprint, request, current_app, jsonify
from geojson import FeatureCollection
from utils_flask_sqla.response import json_resp

from geonature.utils.env import DB
from geonature.core.gn_monitoring.config_manager import generate_config
from geonature.utils.utilssqlalchemy import GenericQuery, testDataType
from geonature.utils.errors import GeonatureApiError


# from pypnusershub import routes as fnauth


routes = Blueprint("core", __name__)

# get the root logger
log = logging.getLogger()


@routes.route("/config", methods=["GET"])
def get_config():
    """
    Parse and return configuration files as toml
    .. :quickref: Generic;
    """
    app_name = request.args.get("app", "base_app")
    vue_name = request.args.getlist("vue")
    if not vue_name:
        vue_name = ["default"]
    filename = "{}.toml".format(
        os.path.abspath(
            os.path.join(
                current_app.config["BASE_DIR"], "static", "configs", app_name, *vue_name
            )
        )
    )
    config_file = generate_config(filename)
    return jsonify(config_file)


@routes.route("/genericview/<view_schema>/<view_name>", methods=["GET"])
@json_resp
def get_generic_view(view_schema, view_name):
    """
        Service générique permettant de requeter une vue
        .. :quickref: Generic;

        Parameters
        ----------
        limit : nombre limit de résultats à retourner
        offset : numéro de page
        geometry_field : nom de la colonne contenant la géométrie
            Si elle est spécifiée les données seront retournés en geojson
        FILTRES :
            nom_col=val: Si nom_col fait partie des colonnes
                de la vue alors filtre nom_col=val
            ilikenom_col=val: Si nom_col fait partie des colonnes
                de la vue et que la colonne est de type texte
                alors filtre nom_col ilike '%val%'
            filter_d_up_nom_col=val: Si nom_col fait partie des colonnes
                de la vue et que la colonne est de type date
                alors filtre nom_col >= val
            filter_d_lo_nom_col=val: Si nom_col fait partie des colonnes
                de la vue et que la colonne est de type date
                alors filtre nom_col <= val
            filter_d_eq_nom_col=val: Si nom_col fait partie des colonnes
                de la vue et que la colonne est de type date
                alors filtre nom_col == val
            filter_n_up_nom_col=val: Si nom_col fait partie des colonnes
                de la vue et que la colonne est de type numérique
                alors filtre nom_col >= val
            filter_n_lo_nom_col=val: Si nom_col fait partie des colonnes
                de la vue et que la colonne est de type numérique
                alors filtre nom_col <= val
        ORDONNANCEMENT :
            orderby: char
                Nom du champ sur lequel baser l'ordonnancement
            order: char (asc|desc)
                Sens de l'ordonnancement

        Returns
        -------
        json
        {
            'total': Nombre total de résultat,
            'total_filtered': Nombre total de résultat après filtration,
            'page': Numéro de la page retournée,
            'limit': Nombre de résultats,
            'items': données au format Json ou GeoJson
        }


            order by : @TODO
    """
    parameters = request.args

    limit = int(parameters.get("limit")) if parameters.get("limit") else 100
    page = int(parameters.get("offset")) if parameters.get("offset") else 0

    # Construction de la vue
    # @TODO créer un système de mise en cache des vues mappées
    geom = parameters.get("geometry_field", None)

    results = GenericQuery(
        DB.session, view_name, view_schema, geom, parameters, limit, page
    ).return_query()

    return results
