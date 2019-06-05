import json
from flask import Blueprint, current_app, session, request
from sqlalchemy.sql import func
from geojson import FeatureCollection, Feature

from sqlalchemy.sql.expression import label, distinct

from geonature.utils.utilssqlalchemy import json_resp
from geonature.utils.env import DB

from .models import VSyntheseCommunes
from .models import VSyntheseCommunesINPN
from .models import VSynthese
from .models import VTaxonomie

# # import des fonctions utiles depuis le sous-module d'authentification
# from geonature.core.gn_permissions import decorators as permissions
# from geonature.core.gn_permissions.tools import get_or_fetch_user_cruved

blueprint = Blueprint("dashboard", __name__)

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
    if ('selectedRegne' in params) and (params['selectedRegne'] != ""):
        q = q.filter(VSynthese.regne == params['selectedRegne'])
    if ('selectedPhylum' in params) and (params['selectedPhylum'] != ""):
        q = q.filter(VSynthese.phylum == params['selectedPhylum'])
    if 'selectedClasse' in params and (params['selectedClasse'] != ""):
        q = q.filter(VSynthese.classe == params['selectedClasse'])
    if 'selectedOrdre' in params and (params['selectedOrdre'] != ""):
        q = q.filter(VSynthese.ordre == params['selectedOrdre'])
    if 'selectedFamille' in params and (params['selectedFamille'] != ""):
        q = q.filter(VSynthese.famille == params['selectedFamille'])
    if ('selectedGroup2INPN' in params) and (params['selectedGroup2INPN'] != ""):
        q = q.filter(VSynthese.group2_inpn == params['selectedGroup2INPN'])
    if ('selectedGroup1INPN' in params) and (params['selectedGroup1INPN'] != ""):
        q = q.filter(VSynthese.group1_inpn == params['selectedGroup1INPN'])  
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


# vm_synthese_communes
@blueprint.route("/communes", methods=["GET"])
@json_resp
def get_communes_stat():
    params = request.args
    q = DB.session.query(
        VSyntheseCommunes.area_name,
        VSyntheseCommunes.geom_area_4326,
        func.sum(VSyntheseCommunes.nb_obs),
        func.sum(VSyntheseCommunes.nb_taxons)
    ).group_by(VSyntheseCommunes.area_name, VSyntheseCommunes.geom_area_4326)
    # if ('yearMax' not in params) and ('yearMin' not in params) :
    #     q = q.filter(VSyntheseCommunes.year == None)
    if 'selectedYearRange' in params:
        q = q.filter(VSyntheseCommunes.year <= params['selectedYearRange'][5:9])
        q = q.filter(VSyntheseCommunes.year >= params['selectedYearRange'][0:4])
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
    if 'selectedClasse' in params and (params['selectedClasse'] != ""):
        q = q.filter(VSyntheseCommunes.classe == params['selectedClasse'])
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


# vm_synthese_communes_inpn
@blueprint.route("/communes_inpn", methods=["GET"])
@json_resp
def get_communes_inpn_stat():
    params = request.args
    q = DB.session.query(
        VSyntheseCommunesINPN.area_name,
        VSyntheseCommunesINPN.geom_area_4326,
        func.sum(VSyntheseCommunesINPN.nb_obs),
        func.sum(VSyntheseCommunesINPN.nb_taxons)
    ).group_by(VSyntheseCommunesINPN.area_name, VSyntheseCommunesINPN.geom_area_4326)
    if 'selectedYearRange' in params:
        q = q.filter(VSyntheseCommunesINPN.year <= params['selectedYearRange'][5:9])
        q = q.filter(VSyntheseCommunesINPN.year >= params['selectedYearRange'][0:4])
    if ('selectedGroup2INPN' in params) and (params['selectedGroup2INPN'] != ""):
        q = q.filter(VSyntheseCommunesINPN.group2_inpn == params['selectedGroup2INPN'])
    if ('selectedGroup1INPN' in params) and (params['selectedGroup1INPN'] != ""):
        q = q.filter(VSyntheseCommunesINPN.group1_inpn == params['selectedGroup1INPN'])
        q = q.filter(VSyntheseCommunesINPN.group2_inpn == None)    
    data = q.all()

    geojson_features = []
    for d in data:
        properties = {"nb_obs": int(d[2]), "nb_taxon": int(d[3]), "area_name": d[0]}
        geojson = json.loads(d[1])
        geojson["properties"] = properties
        geojson_features.append(geojson)
    return FeatureCollection(geojson_features)


# vm_synthese
@blueprint.route("/regne_data", methods=["GET"])
@json_resp
def get_regne_data():
    params = request.args
    q = DB.session.query(
        VSynthese.regne,
        func.count(VSynthese.id_synthese)
    ).group_by(VSynthese.regne)
    if 'selectedYearRange' in params:
        q = q.filter(func.date_part('year', VSynthese.date_min) <= params['selectedYearRange'][5:9])
        q = q.filter(func.date_part('year', VSynthese.date_max) >= params['selectedYearRange'][0:4])
    return q.all()


# vm_synthese
@blueprint.route("/phylum_data", methods=["GET"])
@json_resp
def get_phylum_data():
    params = request.args
    q = DB.session.query(
        VSynthese.phylum,
        func.count(VSynthese.id_synthese)
    ).group_by(VSynthese.phylum)
    if 'selectedYearRange' in params:
        q = q.filter(func.date_part('year', VSynthese.date_min) <= params['selectedYearRange'][5:9])
        q = q.filter(func.date_part('year', VSynthese.date_max) >= params['selectedYearRange'][0:4])
    return q.all()


# vm_synthese
@blueprint.route("/classe_data", methods=["GET"])
@json_resp
def get_classe_data():
    params = request.args
    q = DB.session.query(
        VSynthese.classe,
        func.count(VSynthese.id_synthese)
    ).group_by(VSynthese.classe)
    if 'selectedYearRange' in params:
        q = q.filter(func.date_part('year', VSynthese.date_min) <= params['selectedYearRange'][5:9])
        q = q.filter(func.date_part('year', VSynthese.date_max) >= params['selectedYearRange'][0:4])
    return q.all()


# vm_synthese
@blueprint.route("/group1_inpn_data", methods=["GET"])
@json_resp
def get_group1_inpn_data():
    params = request.args
    q = DB.session.query(
        VSynthese.group1_inpn,
        func.count(VSynthese.id_synthese)
    ).group_by(VSynthese.group1_inpn)
    if 'selectedYearRange' in params:
        q = q.filter(func.date_part('year', VSynthese.date_min) <= params['selectedYearRange'][5:9])
        q = q.filter(func.date_part('year', VSynthese.date_max) >= params['selectedYearRange'][0:4])
    return q.all()

# vm_synthese
@blueprint.route("/group2_inpn_data", methods=["GET"])
@json_resp
def get_group2_inpn_data():
    params = request.args
    q = DB.session.query(
        VSynthese.group2_inpn,
        func.count(VSynthese.id_synthese)
    ).group_by(VSynthese.group2_inpn)
    if 'selectedYearRange' in params:
        q = q.filter(func.date_part('year', VSynthese.date_min) <= params['selectedYearRange'][5:9])
        q = q.filter(func.date_part('year', VSynthese.date_max) >= params['selectedYearRange'][0:4])
    return q.all()


# vm_synthese
@blueprint.route("/years", methods=["GET"])
@json_resp
def get_years():
    params = request.args
    q = DB.session.query(
        func.min(func.date_part('year', VSynthese.date_min)),
        func.max(func.date_part('year', VSynthese.date_min))
    )
    return q.all()

# vm_taxonomie
@blueprint.route("/taxonomie", methods=["GET"])
@json_resp
def get_taxonomie():
    params = request.args
    q = DB.session.query(VTaxonomie.name_taxon).order_by(VTaxonomie.name_taxon)
    if 'taxLevel' in params:
        q = q.filter(VTaxonomie.level == params['taxLevel'])
    return q.all()
