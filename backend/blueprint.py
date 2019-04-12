import json
from flask import Blueprint, current_app, session
from sqlalchemy.sql import func
from geojson import FeatureCollection, Feature

from geonature.utils.utilssqlalchemy import json_resp
from geonature.utils.env import DB

from .models import VSyntheseCommunes

# # import des fonctions utiles depuis le sous-module d'authentification
# from geonature.core.gn_permissions import decorators as permissions
# from geonature.core.gn_permissions.tools import get_or_fetch_user_cruved

blueprint = Blueprint("dashboard", __name__)


# Exemple d'une route simple
@blueprint.route("/communes", methods=["GET"])
@json_resp
def get_communes_stat():
    q = DB.session.query(
        VSyntheseCommunes.area_name,
        VSyntheseCommunes.geom_area_4326,
        func.sum(VSyntheseCommunes.nb_obs),
        func.sum(VSyntheseCommunes.nb_taxons),
    ).group_by(VSyntheseCommunes.area_name, VSyntheseCommunes.geom_area_4326)
    data = q.all()

    geojson_features = []
    for d in data:
        properties = {"nb_obs": int(d[2]), "nb_taxon": int(d[3]), "area_name": d[0]}
        geojson = json.loads(d[1])
        geojson["properties"] = properties
        geojson_features.append(geojson)
    return FeatureCollection(geojson_features)
