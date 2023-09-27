import json
import datetime
import math

from flask import Blueprint, request, jsonify
from flask.globals import current_app
from geoalchemy2.shape import to_shape
from geojson import Feature
from sqlalchemy.sql import func, text, select
from werkzeug.exceptions import BadRequest, NotFound, abort
from utils_flask_sqla.response import json_resp

from pypnnomenclature.models import TNomenclatures
from geonature.core.gn_profiles.models import (
    VmCorTaxonPhenology,
    VmValidProfiles,
    VConsistancyData,
)
import geonature.core.gn_profiles.tasks  # noqa: F401
from geonature.utils.env import DB

routes = Blueprint("gn_profiles", __name__, cli_group="profiles")


@routes.route("/cor_taxon_phenology/<int:cd_ref>", methods=["GET"])
@json_resp
def get_phenology(cd_ref):
    """
    .. :quickref: Profiles;

    Get phenoliques periods for a given taxon

    """
    filters = request.args
    query = DB.session.query(VmCorTaxonPhenology).filter(VmCorTaxonPhenology.cd_ref == cd_ref)
    if "id_nomenclature_life_stage" in filters:
        active_life_stage = DB.session.execute(
            select()
            .column(text("active_life_stage"))
            .select_from(func.gn_profiles.get_parameters(cd_ref))
        ).scalar()
        if active_life_stage:
            if filters["id_nomenclature_life_stage"].strip() == "null":
                query = query.filter(VmCorTaxonPhenology.id_nomenclature_life_stage == None)
            else:
                query = query.filter(
                    VmCorTaxonPhenology.id_nomenclature_life_stage
                    == filters["id_nomenclature_life_stage"]
                )
        else:
            query = query.filter(VmCorTaxonPhenology.id_nomenclature_life_stage == None)

    data = query.all()
    if data:
        return [row.as_dict() for row in data]
    return None


@routes.route("/valid_profile/<int:cd_ref>", methods=["GET"])
def get_profile(cd_ref):
    """
    .. :quickref: Profiles;

    Return the profile for a cd_ref
    """
    data = DB.session.query(
        func.st_asgeojson(func.st_transform(VmValidProfiles.valid_distribution, 4326)),
        VmValidProfiles,
    ).filter(VmValidProfiles.cd_ref == cd_ref)
    data = data.one_or_none()
    if data:
        return jsonify(Feature(geometry=json.loads(data[0]), properties=data[1].as_dict()))
    abort(404)


@routes.route("/consistancy_data/<id_synthese>", methods=["GET"])
def get_consistancy_data(id_synthese):
    """
    .. :quickref: Profiles;

    Return the validation score for a synthese data
    """
    data = VConsistancyData.query.get_or_404(id_synthese)
    return jsonify(data.as_dict())


@routes.route("/check_observation", methods=["POST"])
@json_resp
def get_observation_score():
    """
    .. :quickref: Profiles;

    Check an observation with the related profile
    Return alert when the observation do not match the profile
    """
    data = request.get_json()
    try:
        cd_ref = data["cd_ref"]
    except KeyError:
        raise BadRequest("No cd_ref provided")

    # Récupération du profil du cd_ref
    result = {}
    profile = (
        DB.session.query(VmValidProfiles).filter(VmValidProfiles.cd_ref == cd_ref).one_or_none()
    )
    if not profile:
        raise NotFound("No profile for this cd_ref")
    check_life_stage = profile.active_life_stage

    result = {
        "valid_distribution": True,
        "valid_altitude": True,
        "valid_phenology": True,
        "valid_life_stage": None,
        "life_stage_accepted": [],
        "errors": [],
        "profil": profile.as_dict(),
        "check_life_stage": check_life_stage,
    }

    # Calcul de la période correspondant à la date
    if data.get("date_min") and data.get("date_max"):
        date_min = datetime.datetime.strptime(data["date_min"], "%Y-%m-%d")
        date_max = datetime.datetime.strptime(data["date_max"], "%Y-%m-%d")
        # Calcul du numéro du jour pour les dates min et max
        doy_min = date_min.timetuple().tm_yday
        doy_max = date_max.timetuple().tm_yday
    else:
        raise BadRequest("Missing date min or date max")
    # Récupération des altitudes
    if data.get("altitude_min") and data.get("altitude_max"):
        altitude_min = data["altitude_min"]
        altitude_max = data["altitude_max"]
    else:
        raise BadRequest("Missing altitude_min or altitude_max")
    # Check de la répartition
    if "geom" in data:
        query = DB.session.query(
            func.ST_Contains(
                func.ST_Transform(profile.valid_distribution, 4326),
                func.ST_SetSRID(func.ST_GeomFromGeoJSON(json.dumps(data["geom"])), 4326),
            )
        )

        check_geom = query.one_or_none()
        if not check_geom:
            result["valid_distribution"] = False
            result["errors"].append(
                {"type": "geometry", "value": "Erreur lors du calcul de la géométrie valide"}
            )
        if check_geom[0] is False:
            result["valid_distribution"] = False
            result["errors"].append(
                {
                    "type": "geom",
                    "value": f"Le taxon n'a jamais été observé dans cette zone géographique",
                }
            )
        else:
            result["valid_distribution"] = True

        # check de la periode
        q_pheno = DB.session.query(VmCorTaxonPhenology.id_nomenclature_life_stage).distinct()
        q_pheno = q_pheno.filter(VmCorTaxonPhenology.cd_ref == cd_ref)
        q_pheno = q_pheno.filter(VmCorTaxonPhenology.doy_min <= doy_min).filter(
            VmCorTaxonPhenology.doy_max >= doy_max
        )

        period_result = q_pheno.all()
        if len(period_result) == 0:
            result["valid_phenology"] = False
            result["errors"].append(
                {"type": "period", "value": "Le taxon n'a jamais été observé à cette periode"}
            )

        # check de l'altitude
        if altitude_max > profile.altitude_max or altitude_min < profile.altitude_min:
            result["valid_altitude"] = False
            result["errors"].append(
                {
                    "type": "altitude",
                    "value": f"Le taxon n'a jamais été observé à cette altitude ({altitude_min}-{altitude_max}m)",
                }
            )
        # check de l'altitude pour la période donnée
        if len(period_result) > 0:
            peridod_and_altitude = q_pheno.filter(
                VmCorTaxonPhenology.calculated_altitude_min <= altitude_min
            )
            peridod_and_altitude = peridod_and_altitude.filter(
                VmCorTaxonPhenology.calculated_altitude_max >= altitude_max
            )
            peridod_and_altitude_r = peridod_and_altitude.all()
            if len(peridod_and_altitude_r) > 0:
                result["valid_altitude"] = True
                result["valid_phenology"] = True
                for row in peridod_and_altitude_r:
                    # Construction de la liste des stade de vie potentielle
                    if row.id_nomenclature_life_stage:
                        result["life_stage_accepted"].append(row.id_nomenclature_life_stage)
            else:
                result["valid_altitude"] = False
                result["valid_phenology"] = False
                if altitude_max <= profile.altitude_max and altitude_min >= altitude_min:
                    result["errors"].append(
                        {
                            "type": "period",
                            "value": f"Le taxon a déjà été observé à cette altitude ({altitude_min}-{altitude_max}m), mais pas à cette periode de l'année",
                        }
                    )
                if result["valid_phenology"]:
                    result["errors"].append(
                        {
                            "type": "period",
                            "value": f"Le taxon a déjà été observé à cette periode de l'année, mais pas à cette altitude ({altitude_min}-{altitude_max}m)",
                        }
                    )

        # check du stade de vie pour la periode donnée
        if check_life_stage and "life_stages" in data:
            if type(data["life_stages"]) is not list:
                raise BadRequest("life_stages must be a list")
            for life_stage in data["life_stages"]:
                life_stage_value = TNomenclatures.query.get(life_stage)
                q = q_pheno.filter(VmCorTaxonPhenology.id_nomenclature_life_stage == life_stage)
                r_life_stage = q.all()
                if len(r_life_stage) == 0:
                    result["valid_life_stage"] = False
                    result["valid_phenology"] = False
                    result["errors"].append(
                        {
                            "type": "life_stage",
                            "value": f"Le taxon n'a jamais été observé à cette periode pour le stade de vie {life_stage_value.label_default}",
                        }
                    )

                # check du stade de vie pour la période et l'altitude
                else:
                    if altitude_min and altitude_max:
                        q = q.filter(VmCorTaxonPhenology.calculated_altitude_min <= altitude_min)
                        q = q.filter(VmCorTaxonPhenology.calculated_altitude_max >= altitude_max)
                        r_life_stage_altitude = q.all()
                        if len(r_life_stage_altitude) == 0:
                            result["valid_life_stage"] = False
                            result["valid_altitude"] = False
                            result["valid_phenology"] = False
                            result["errors"].append(
                                {
                                    "type": "life_stage",
                                    "value": f"""
                                Le taxon n'a jamais été observé à cette periode et à cette altitude ({altitude_min}-{altitude_max}m)
                                pour le stade de vie {life_stage_value.label_default}""",
                                }
                            )
    return result


@routes.cli.command()
def update():
    DB.session.execute(func.gn_profiles.refresh_profiles())
    DB.session.commit()
