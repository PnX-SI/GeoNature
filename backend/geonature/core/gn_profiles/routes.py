import json

from flask import Blueprint, request
from geoalchemy2.shape import to_shape
from geojson import Feature
from sqlalchemy.sql import func, text
from utils_flask_sqla.response import json_resp

from geonature.core.gn_profiles.models import VmCorTaxonPhenology, VmValidProfiles, VConsistancyData

from geonature.utils.env import DB

routes = Blueprint("gn_profiles", __name__)


@routes.route("/cor_taxon_phenology/<cd_ref>", methods=["GET"])
@json_resp
def get_phenology(cd_ref):
    filters=request.args
    # parameter=DB.session.query(func.gn_profiles.get_parameters(cd_ref)).one_or_none()

    query = DB.session.query(VmCorTaxonPhenology).filter(VmCorTaxonPhenology.cd_ref == cd_ref)
    if "id_nomenclature_life_stage" in filters:
        dbquery=text("SELECT active_life_stage FROM gn_profiles.get_parameters(:cd_ref)")
        parameter=DB.engine.execute(dbquery,cd_ref=cd_ref).fetchone()
        if parameter :
            if parameter[0] == False :
                query = query.filter(
                    VmCorTaxonPhenology.id_nomenclature_life_stage == None
                )
            else :
                if filters['id_nomenclature_life_stage'].strip() == 'null':
                    query = query.filter(
                        VmCorTaxonPhenology.id_nomenclature_life_stage == None
                    )
                else :
                    query = query.filter(
                        VmCorTaxonPhenology.id_nomenclature_life_stage == filters["id_nomenclature_life_stage"]
                    )

    print(query)
    data=query.all()
    if data:
        # result=[]
        # for row in data :
        #     result.append(row.as_dict())
        # return result
        return [row.as_dict() for row in data]
    return None


@routes.route("/valid_profile/<cd_ref>", methods=["GET"])
@json_resp
def get_profile(cd_ref):
    data = (
        DB.session.query(
            func.st_asgeojson(func.st_transform(VmValidProfiles.valid_distribution, 4326)),
            VmValidProfiles,
        )
        .filter(VmValidProfiles.cd_ref == cd_ref)
        .one_or_none()
    )
    if data:
        return Feature(geometry=json.loads(data[0]), properties=data[1].as_dict())
    return None

    # récupérer la query string
    # filters = request.args
    # query = DB.session.query(VmValidProfiles).filter(VmValidProfiles.cd_ref == cd_ref)

    # construire dynamiquement les filtres
    # if "alt_min" in filters:
    #     query = query.filter(VmValidProfiles.altitude_min >= filters["alt_min"])
    # columns = []
    # if "columns" in filters:
    #     columns = filters["columns"].split(",")
    # data = query.one()
    # if data:
    #     return data.as_geofeature("valid_distribution", "cd_ref", False, columns)
    # return None


@routes.route("/consistancy_data/<id_synthese>", methods=["GET"])
@json_resp
def get_consistancy_data(id_synthese):
    data = DB.session.query(VConsistancyData).get(id_synthese)
    if data:
        return data.as_dict()
    return None
def get_cor_taxon_phenology(cd_ref):
    q = DB.session.query(VmCorTaxonPhenology)
    data = q.get(cd_ref)
    return data.as_dict()


@routes.route("/profiles/<cd_ref>", methods=["GET"])
@json_resp
def get_profile(cd_ref):
    data = DB.session.query(VmValidProfiles).get(cd_ref)
    if data:
        return data.get_geofeature()
    return None
    
@routes.route("/get_observation_score/<cd_ref>", methods=["POST"])
@json_resp
def get_observation_score(cd_ref):
    """ TODO : A Adapter lors de la prochaine version de la table vm_cor_taxon_phenologie """

    filters = request.form

    profile = (
        DB.session.query(VmValidProfiles).filter(VmValidProfiles.cd_ref == cd_ref).one_or_none()
    )

    result = {}

    """ Contrôle de la localisation """
    if "geom" in filters:
        check_geom = DB.session.query(
            func.ST_Contains(
                func.ST_Transform(profile.valid_distribution, 4326),
                func.ST_SetSRID(func.ST_GeomFromGeoJSON(filters["geom"]), 4326),
            )
        ).one_or_none()

        if check_geom is None:
            result["controle_geom"] = {
                "code_result": 0,
                "Commentaire": "Il existe données valides pour ce taxon, mais il n'a jamais été observé dans cette zone.",
            }
    """ Contrôle de la localisation """

    """ Contrôle des dates """
    if "date_min" in filters:
        q = q.filter(VmValidProfiles.first_valid_data < filters["date_min"]).one_or_none()

    if "date_max" in filters:
        q = q.filter(VmValidProfiles.last_valid_data > filters["date_max"])

    if q.count() > 0:
        result["controle_date"] = {
            "code_result": 1,
            "Commentaire": "Dans ce secteur, le taxon a déjà été observé à cette période",
        }
    else:
        result["controle_date"] = {
            "code_result": 0,
            "Commentaire": "Dans ce secteur, le taxon n'a jamais été observé à cette période",
        }
    """ FIN Contrôle des dates """

    """ Contrôle de l'altitude """
    if "altitude_min" in filters:
        q = q.filter(VmValidProfiles.altitude_min < filters["altitude_min"]).one_or_none()

    if "altitude_max" in filters:
        q = q.filter(VmValidProfiles.altitude_max > filters["altitude_max"]).one_or_none()

    if q.count() > 0:
        result["controle_altitude"] = {
            "code_result": 1,
            "Commentaire": "Dans ce secteur et à cette période, le taxon a déjà été observé à cette altitude",
        }
    else:
        result["controle_altitude"] = {
            "code_result": 0,
            "Commentaire": "Dans ce secteur et à cette période, le taxon n'a jamais été observé à cette altitude",
        }
    """ FIN Contrôle l'altitude """

    """ TODO : Contrôler le stade de vie """
    return result
