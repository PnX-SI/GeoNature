from flask import Blueprint

from utils_flask_sqla.response import json_resp

from geonature.core.gn_profiles.models import VmCorTaxonPhenology
from geonature.core.gn_profiles.models import VmValidProfiles
from geonature.core.gn_profiles.models import VConsistancyData

from geonature.utils.env import DB

routes = Blueprint("gn_profiles", __name__)


@routes.route("/cor_taxon_phenology/<cd_ref>", methods=["GET"])
@json_resp
def get_phenology(cd_ref):
    data = DB.session.query(VmCorTaxonPhenology).get(cd_ref)
    if data:
        return data.as_dict()
    return None


@routes.route("/valid_profile/<cd_ref>", methods=["GET"])
@json_resp
def get_profile(cd_ref):
    data = DB.session.query(VmValidProfiles).get(cd_ref)
    if data:
        return data.as_geofeature("valid_distribution", "cd_ref", False)
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
