import json
from flask import Blueprint, current_app, session, request
from sqlalchemy.sql import func
from geojson import FeatureCollection, Feature

from sqlalchemy.sql.expression import label, distinct

from geonature.utils.utilssqlalchemy import json_resp
from geonature.utils.env import DB

from .models import VSyntheseCommunes
from .models import VSynthese
from .models import VRegne
from .models import VPhylum

# # import des fonctions utiles depuis le sous-module d'authentification
# from geonature.core.gn_permissions import decorators as permissions
# from geonature.core.gn_permissions.tools import get_or_fetch_user_cruved

blueprint = Blueprint("dashboard", __name__)


# vm_synthese_communes
@blueprint.route("/communes", methods=["GET"])
@json_resp
def get_communes_stat():
    params = request.args
    q = DB.session.query(
        VSyntheseCommunes.area_name,
        VSyntheseCommunes.geom_area_4326,
        func.sum(VSyntheseCommunes.nb_obs),
        #VSyntheseCommunes.nb_obs,
        func.sum(VSyntheseCommunes.nb_taxons)
        #VSyntheseCommunes.nb_taxons)
    ).group_by(VSyntheseCommunes.area_name, VSyntheseCommunes.geom_area_4326)
    q = q.filter(VSyntheseCommunes.geom_area_4326 != None)
    # if ('yearMax' not in params) and ('yearMin' not in params) :
    #     q = q.filter(VSyntheseCommunes.year == None)
    if 'yearMax' in params:
        q = q.filter(VSyntheseCommunes.year <= params['yearMax'])
    if 'yearMin' in params:
        q = q.filter(VSyntheseCommunes.year >= params['yearMin'])
    # if 'regne' not in params:
    #     q = q.filter(VSyntheseCommunes.regne == None)
    if ('selectedRegne' in params) and (params['selectedRegne'] != ""):
        q = q.filter(VSyntheseCommunes.regne == params['selectedRegne'])
    # if 'phylum' not in params:
    #     q = q.filter(VSyntheseCommunes.phylum == None)
    if ('selectedPhylum' in params) and (params['selectedPhylum'] != ""):
        q = q.filter(VSyntheseCommunes.phylum == params['selectedPhylum'])
    # if 'classe' not in params:
    #     q = q.filter(VSyntheseCommunes.classe == None)
    if 'classe' in params:
        q = q.filter(VSyntheseCommunes.classe == params['classe'])
    # if 'ordre' not in params:
    #     q = q.filter(VSyntheseCommunes.ordre == None)
    # if 'ordre' in params:
    #     q = q.filter(VSyntheseCommunes.ordre == params['ordre'])
    # if 'famille' not in params:
    #     q = q.filter(VSyntheseCommunes.famille == None)
    # if 'famille' in params:
    #     q = q.filter(VSyntheseCommunes.famille == params['famille'])
    data = q.all()

    geojson_features = []
    for d in data:
        properties = {"nb_obs": int(d[2]), "nb_taxon": int(d[3]), "area_name": d[0]}
        geojson = json.loads(d[1])
        geojson["properties"] = properties
        geojson_features.append(geojson)
    return FeatureCollection(geojson_features)


# vm_synthese
@blueprint.route("/synthese", methods=["GET"])
@json_resp
def get_synthese_stat():
    params = request.args
    q = DB.session.query(
        label('year', func.date_part('year', VSynthese.date_min)),
        func.count(VSynthese.id_synthese),
        func.count(distinct(VSynthese.cd_ref))
    ).group_by('year')
    # if 'yearMax' in params:
    #     q = q.filter(VSyntheseCommunes.year <= params['yearMax'])
    # if 'yearMin' in params:
    #     q = q.filter(VSyntheseCommunes.year >= params['yearMin'])
    return q.all()

    # Si on veut afficher tous les champs de la vue 
    # data = DB.session.query(VSynthese).limit(10).all()

    # tab = []
    # for d in data:
    #     temp_dict = d.as_dict()
    #     print(temp_dict)
    #     tab.append(temp_dict)
    # return tab

    # return [d.as_dict() for d in data]


# vm_synthese
@blueprint.route("/regne_data", methods=["GET"])
@json_resp
def get_regne_data():
    params = request.args
    q = DB.session.query(
        VSynthese.regne,
        func.count(VSynthese.id_synthese)
    ).group_by(VSynthese.regne)
    if 'yearMax' in params:
        q = q.filter(func.date_part('year', VSynthese.date_min) <= params['yearMax'])
    if 'yearMin' in params:
        q = q.filter(func.date_part('year', VSynthese.date_max) >= params['yearMin'])
    return q.all()


# v_regnes
@blueprint.route("/regnes", methods=["GET"])
@json_resp
def get_regne_name():
    #params = request.args
    q = DB.session.query(VRegne.regne).order_by(VRegne.regne)
    q = q.filter(VRegne.regne != None)
    return q.all()

# v_phylum
@blueprint.route("/phylum", methods=["GET"])
@json_resp
def get_phylum_name():
    #params = request.args
    q = DB.session.query(VPhylum.phylum).order_by(VPhylum.phylum)
    q = q.filter(VPhylum.phylum != None)
    return q.all()
