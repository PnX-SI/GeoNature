import json
import datetime
import math

from flask import Blueprint, request
from geoalchemy2.shape import to_shape
from geojson import Feature
from sqlalchemy.sql import func, text
from utils_flask_sqla.response import json_resp

from geonature.core.gn_profiles.models import VmCorTaxonPhenology, VmValidProfiles, VConsistancyData
from geonature.core.taxonomie.models import Taxref
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
def get_observation_score():
    """ Récupération des valeurs du POST"""
    """filters = request.form"""
    filters = request.get_json()
    print(filters)

    if "cd_nom" in filters:
        """ Récupération du cd_ref """
        cd_ref = DB.session.query(Taxref).get(filters["cd_nom"]).cd_ref

        """ Récupération du paramètre "période" attribué au taxon """
        sql = text("""select temporal_precision_days from gn_profiles.get_parameters(:cd_nom)""")
        try:
            temporal_precision_days = (
                DB.engine.execute(sql, cd_nom=filters["cd_nom"]).fetchone().temporal_precision_days
            )
        except Exception as e:
            DB.session.rollback()
            raise

        """for row in result:
            temporal_precision_days = row[0]"""
    else:
        print("here i am")
        return None

    """ Calcul de la période correspondant à la date """
    if "date_min" in filters and "date_max" in filters:
        """ 1- Création de la date au premier janvier de l'années en cours"""
        current_year = datetime.datetime.now().year
        first_january = datetime.datetime(current_year, 1, 1)

        """ 2- Détermination de la période correspondant à date_min"""
        date_min = datetime.datetime.strptime(filters["date_min"], "%Y-%m-%d")
        min_day_of_year = abs((date_min - first_january).days) + 1
        min_periode = math.ceil(min_day_of_year / temporal_precision_days)

        """ 3- Détermination de la période correspondant à date_max"""
        date_max = datetime.datetime.strptime(filters["date_max"], "%Y-%m-%d")
        max_day_of_year = abs((date_max - first_january).days) + 1
        max_periode = math.ceil(max_day_of_year / temporal_precision_days)

    else:
        return None

    """ Récupération des altitudes """
    if "altitude_min" in filters and "altitude_max" in filters:
        altitude_min = filters["altitude_min"]
        altitude_max = filters["altitude_max"]
    else:
        return None

    result = {}
    """ Contrôle de la localisation """
    q_loc = DB.session.query(VmValidProfiles)
    q_loc = q_loc.filter(VmValidProfiles.cd_ref == cd_ref)

    if "geom" in filters:
        q_loc = q_loc.filter(
            func.ST_Transform(VmValidProfiles.valid_distribution, 4326).ST_Intersects(
                func.ST_SetSRID(func.ST_GeomFromGeoJSON(json.dumps(filters["geom"])), 4326)
            )
        )

        if q_loc.count() == 0:
            result["result"] = {
                "code_result": 0,
                "Commentaire": "Le taxon n'a jamais été observé dans cette zone",
            }
        else:
            """ Controle date et altitude """
            q_pheno = DB.session.query(VmCorTaxonPhenology.id_nomenclature_life_stage).distinct()
            q_pheno = q_pheno.filter(VmCorTaxonPhenology.cd_ref == cd_ref)
            q_pheno = q_pheno.filter(VmCorTaxonPhenology.period.between(min_periode, max_periode))
            q_pheno = q_pheno.filter(VmCorTaxonPhenology.calculated_altitude_min <= altitude_min)
            q_pheno = q_pheno.filter(VmCorTaxonPhenology.calculated_altitude_max >= altitude_max)

            if q_pheno.count() > 0:
                """Construction de la liste des stade de vie potentielle"""
                l_lifestage = []
                for row in q_pheno.all():
                    l_lifestage.append(row.id_nomenclature_life_stage)

                result["result"] = {
                    "code_result": 1,
                    "Commentaire": "Le taxon a déjà été observé à cette période et à cette altitude",
                    "l_ids_lifestage": l_lifestage,
                }
            else:
                result["result"] = {
                    "code_result": 0,
                    "Commentaire": "Le taxon n'a jamais été observé à cette période ou à cette altitude ou trop peu de données valides permettent de s'assurer de la conformité de cette observation",
                }
    else:
        return None

    return result