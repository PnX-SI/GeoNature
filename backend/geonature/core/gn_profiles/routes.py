import json

from flask import Blueprint, request
from geojson import Feature
from sqlalchemy.sql import func
from utils_flask_sqla.response import json_resp

from geonature.core.gn_profiles.models import VmCorTaxonPhenology
from geonature.core.gn_profiles.models import VmValidProfiles
from geonature.core.gn_profiles.models import VConsistancyData
from geonature.core.taxonomie.models import Taxref

"""from contrib.occtax.backend.models import TRelevesOccurrence"""

from geonature.utils.env import DB

routes = Blueprint("gn_profiles", __name__)


@routes.route("/cor_taxon_phenology/<cd_ref>", methods=["GET"])
@json_resp
def get_phenology(cd_ref):
    query = DB.session.query(VmCorTaxonPhenology).filter(VmCorTaxonPhenology.cd_ref == cd_ref)
    print(query)
    data = query.all()
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


@routes.route("/get_observation_score", methods=["POST"])
@json_resp
def get_observation_score():
    """ TODO : A Adapter lors de la prochaine version de la table vm_cor_taxon_phenologie """

    filters = request.form

    q = DB.session.query(VmValidProfiles)

    result = {}

    """ Contrôle de la localisation """
    if "geom" in filters:
        q = q.filter(
            func.ST_Transform(VmValidProfiles.valid_distribution, 4326).ST_Intersects(
                func.ST_SetSRID(func.ST_GeomFromGeoJSON(filters["geom"]), 4326)
            )
        )
        if q.count() > 0:
            result["controle_geom"] = {
                "code_result": 1,
                "Commentaire": "Le taxon a déjà été observé dans ce secteur",
            }
        else:
            result["controle_geom"] = {
                "code_result": 0,
                "Commentaire": "Le taxon n'a jamais été observé dans ce secteur",
            }
    """ Contrôle de la localisation """

    """ Contrôle des dates """
    if "date_min" in filters:
        q = q.filter(VmValidProfiles.first_valid_data < filters["date_min"])

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
        q = q.filter(VmValidProfiles.altitude_min < filters["altitude_min"])

    if "altitude_max" in filters:
        q = q.filter(VmValidProfiles.altitude_max > filters["altitude_max"])

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
