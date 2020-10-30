import json

from flask import Blueprint, request
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
