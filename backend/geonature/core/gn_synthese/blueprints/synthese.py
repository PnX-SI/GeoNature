import json

from flask import (
    Blueprint,
    request,
    current_app,
    jsonify,
    g,
)
from werkzeug.exceptions import Forbidden, NotFound, BadRequest
from sqlalchemy import func, select, case, join, and_
from sqlalchemy.orm import joinedload, lazyload, selectinload, contains_eager
from geojson import FeatureCollection, Feature

from sqlalchemy.orm import aliased, with_expression
from sqlalchemy.exc import NoResultFound

import geonature.core.gn_synthese.module  # Don't delete !
from geonature.utils.env import db, DB
from geonature.core.gn_synthese.schemas import SyntheseSchema
from geonature.core.gn_synthese.synthese_config import MANDATORY_COLUMNS
from geonature.core.gn_synthese.synthese_config import MANDATORY_COLUMNS
from geonature.core.gn_synthese.models import (
    CorAreaSynthese,
    Synthese,
    VSyntheseForWebApp,
    TReport,
)
from geonature.core.gn_synthese.utils.blurring import (
    build_allowed_geom_cte,
    build_blurred_precise_geom_queries,
    build_synthese_obs_query,
    split_blurring_precise_permissions,
)
from geonature.core.gn_synthese.utils.query_select_sqla import SyntheseQuery
from geonature.core.gn_permissions.decorators import permissions_required
from geonature.core.sensitivity.models import cor_sensitivity_area_type

from ref_geo.models import LAreas, BibAreasTypes


synthese_routes = Blueprint("synthese", __name__)


@synthese_routes.route("/for_web", methods=["GET", "POST"])
@permissions_required("R", module_code="SYNTHESE")
def get_observations_for_web(permissions):
    """Optimized route to serve data for the frontend with all filters.

    .. :quickref: Synthese; Get filtered observations

    Query filtered by any filter, returning all the fields of the
    view v_synthese_for_export::

        properties = {
            "id": r["id_synthese"],
            "date_min": str(r["date_min"]),
            "cd_nom": r["cd_nom"],
            "nom_vern_or_lb_nom": r["nom_vern"] if r["nom_vern"] else r["lb_nom"],
            "lb_nom": r["lb_nom"],
            "dataset_name": r["dataset_name"],
            "observers": r["observers"],
            "url_source": r["url_source"],
            "unique_id_sinp": r["unique_id_sinp"],
            "entity_source_pk_value": r["entity_source_pk_value"],
        }
        geojson = json.loads(r["st_asgeojson"])
        geojson["properties"] = properties

    :qparam str limit: Limit number of synthese returned. Defaults to NB_MAX_OBS_MAP.
    :qparam str cd_ref_parent: filtre tous les taxons enfants d'un TAXREF cd_ref.
    :qparam str cd_ref: Filter by TAXREF cd_ref attribute
    :qparam str taxonomy_group2_inpn: Filter by TAXREF group2_inpn attribute
    :qparam str taxonomy_id_hab: Filter by TAXREF id_habitat attribute
    :qparam str taxhub_attribut*: filtre générique TAXREF en fonction de l'attribut et de la valeur.
    :qparam str *_red_lists: filtre générique de listes rouges. Filtre sur les valeurs. Voir config.
    :qparam str *_protection_status: filtre générique de statuts (BdC Statuts). Filtre sur les types. Voir config.
    :qparam str observers: Filter on observer
    :qparam str id_organism: Filter on organism
    :qparam str date_min: Start date
    :qparam str date_max: End date
    :qparam str id_acquisition_framework: *tbd*
    :qparam str geoIntersection: Intersect with the geom send from the map
    :qparam str period_start: *tbd*
    :qparam str period_end: *tbd*
    :qparam str area*: Generic filter on area
    :qparam str *: Generic filter, given by colname & value
    :>jsonarr array data: Array of synthese with geojson key, see above
    :>jsonarr int nb_total: Number of observations
    :>jsonarr bool nb_obs_limited: Is number of observations capped
    """
    filters = request.json if request.is_json else {}
    if not isinstance(filters, dict):
        raise BadRequest("Bad filters")

    result_limit = request.args.get(
        "limit", current_app.config["SYNTHESE"]["NB_MAX_OBS_MAP"], type=int
    )

    output_format = request.args.get("format", "ungrouped_geom")
    if output_format not in ["ungrouped_geom", "grouped_geom", "grouped_geom_by_areas"]:
        raise BadRequest(f"Bad format '{output_format}'")

    # Get Column Frontend parameter to return only the needed columns
    param_column_list = {
        col["prop"]
        for col in current_app.config["SYNTHESE"]["LIST_COLUMNS_FRONTEND"]
        + current_app.config["SYNTHESE"]["ADDITIONAL_COLUMNS_FRONTEND"]
    }
    # Init with compulsory columns
    columns = []
    for col in MANDATORY_COLUMNS:
        columns.extend([col, getattr(VSyntheseForWebApp, col)])

    if "count_min_max" in param_column_list:
        count_min_max = case(
            (
                VSyntheseForWebApp.count_min != VSyntheseForWebApp.count_max,
                func.concat(VSyntheseForWebApp.count_min, " - ", VSyntheseForWebApp.count_max),
            ),
            (
                VSyntheseForWebApp.count_min != None,
                func.concat(VSyntheseForWebApp.count_min),
            ),
            else_="",
        )
        columns += ["count_min_max", count_min_max]
        param_column_list.remove("count_min_max")

    if "nom_vern_or_lb_nom" in param_column_list:
        nom_vern_or_lb_nom = func.coalesce(
            func.nullif(VSyntheseForWebApp.nom_vern, ""), VSyntheseForWebApp.lb_nom
        )
        columns += ["nom_vern_or_lb_nom", nom_vern_or_lb_nom]
        param_column_list.remove("nom_vern_or_lb_nom")

    for column in param_column_list:
        columns += [column, getattr(VSyntheseForWebApp, column)]

    observations = func.json_build_object(*columns).label("obs_as_json")

    # Need to check if there are blurring permissions so that the blurring process
    # does not affect the performance if there is no blurring permissions
    blurring_permissions, precise_permissions = split_blurring_precise_permissions(permissions)
    if not blurring_permissions:
        # No need to apply blurring => same path as before blurring feature
        obs_query = (
            select(observations)
            .where(VSyntheseForWebApp.the_geom_4326.isnot(None))
            .order_by(VSyntheseForWebApp.date_min.desc())
            .limit(result_limit)
        )

        # Add filters to observations CTE query
        synthese_query_class = SyntheseQuery(
            VSyntheseForWebApp,
            obs_query,
            dict(filters),
        )
        synthese_query_class.apply_all_filters(g.current_user, permissions)
        obs_query = synthese_query_class.build_query()
        geojson_column = VSyntheseForWebApp.st_asgeojson
    else:
        # Build 2 queries that will be UNIONed
        # Select size hierarchy if mesh mode is selected
        select_size_hierarchy = output_format == "grouped_geom_by_areas"
        blurred_geom_query, precise_geom_query = build_blurred_precise_geom_queries(
            filters, select_size_hierarchy=select_size_hierarchy
        )

        allowed_geom_cte = build_allowed_geom_cte(
            blurring_permissions=blurring_permissions,
            precise_permissions=precise_permissions,
            blurred_geom_query=blurred_geom_query,
            precise_geom_query=precise_geom_query,
            limit=result_limit,
        )

        obs_query = build_synthese_obs_query(
            observations=observations,
            allowed_geom_cte=allowed_geom_cte,
            limit=result_limit,
        )
        geojson_column = func.st_asgeojson(allowed_geom_cte.c.geom)

    if output_format == "grouped_geom_by_areas":
        obs_query = obs_query.add_columns(VSyntheseForWebApp.id_synthese)
        # Need to select the size_hierarchy to use is after (only if blurring permissions are found)
        if blurring_permissions:
            obs_query = obs_query.add_columns(
                allowed_geom_cte.c.size_hierarchy.label("size_hierarchy")
            )
        obs_query = obs_query.cte("OBS")

        agg_areas = (
            select(CorAreaSynthese.id_synthese, LAreas.id_area)
            .join(CorAreaSynthese, CorAreaSynthese.id_area == LAreas.id_area)
            .join(BibAreasTypes, BibAreasTypes.id_type == LAreas.id_type)
            .where(
                CorAreaSynthese.id_synthese == obs_query.c.id_synthese,
                BibAreasTypes.type_code == current_app.config["SYNTHESE"]["AREA_AGGREGATION_TYPE"],
            )
        )

        if blurring_permissions:
            # Do not select cells which size_hierarchy is bigger than AREA_AGGREGATION_TYPE
            # It means that we do not aggregate obs that have a blurring geometry greater in
            # size than the aggregation area
            agg_areas = agg_areas.where(obs_query.c.size_hierarchy <= BibAreasTypes.size_hierarchy)
        agg_areas = agg_areas.lateral("agg_areas")
        obs_query = (
            select(func.ST_AsGeoJSON(LAreas.geom_4326).label("geojson"), obs_query.c.obs_as_json)
            .select_from(
                obs_query.outerjoin(
                    agg_areas, agg_areas.c.id_synthese == obs_query.c.id_synthese
                ).outerjoin(LAreas, LAreas.id_area == agg_areas.c.id_area)
            )
            .cte("OBSERVATIONS")
        )
    else:
        obs_query = obs_query.add_columns(geojson_column.label("geojson")).cte("OBSERVATIONS")

    if output_format == "ungrouped_geom":
        query = select(obs_query.c.geojson, obs_query.c.obs_as_json)
    else:
        # Group geometries with main query
        grouped_properties = func.json_build_object(
            "observations", func.json_agg(obs_query.c.obs_as_json).label("observations")
        )
        query = select(obs_query.c.geojson, grouped_properties).group_by(obs_query.c.geojson)

    results = DB.session.execute(query)

    # Build final GeoJson
    geojson_features = []
    for geom_as_geojson, properties in results:
        geojson_features.append(
            Feature(
                geometry=json.loads(geom_as_geojson) if geom_as_geojson else None,
                properties=properties,
            )
        )
    return jsonify(FeatureCollection(geojson_features))


@synthese_routes.route("/vsynthese/<id_synthese>", methods=["GET"])
@permissions_required("R", module_code="SYNTHESE")
def get_one_synthese(permissions, id_synthese):
    """Get one synthese record for web app with all decoded nomenclature"""
    synthese_query = Synthese.join_nomenclatures().options(
        joinedload("dataset").options(
            selectinload("acquisition_framework").options(
                joinedload("creator"),
                joinedload("nomenclature_territorial_level"),
                joinedload("nomenclature_financing_type"),
            ),
        ),
        # Used to check the sensitivity after
        joinedload("nomenclature_sensitivity"),
    )
    ##################

    fields = [
        "dataset",
        "dataset.acquisition_framework",
        "dataset.acquisition_framework.bibliographical_references",
        "dataset.acquisition_framework.cor_af_actor",
        "dataset.acquisition_framework.cor_objectifs",
        "dataset.acquisition_framework.cor_territories",
        "dataset.acquisition_framework.cor_volets_sinp",
        "dataset.acquisition_framework.creator",
        "dataset.acquisition_framework.nomenclature_territorial_level",
        "dataset.acquisition_framework.nomenclature_financing_type",
        "dataset.cor_dataset_actor",
        "dataset.cor_dataset_actor.role",
        "dataset.cor_dataset_actor.organism",
        "dataset.cor_territories",
        "dataset.nomenclature_source_status",
        "dataset.nomenclature_resource_type",
        "dataset.nomenclature_dataset_objectif",
        "dataset.nomenclature_data_type",
        "dataset.nomenclature_data_origin",
        "dataset.nomenclature_collecting_method",
        "dataset.creator",
        "dataset.modules",
        "validations",
        "validations.validation_label",
        "validations.validator_role",
        "cor_observers",
        "cor_observers.organisme",
        "source",
        "habitat",
        "medias",
        "areas",
        "areas.area_type",
    ]

    # get reports info only if activated by admin config
    if "SYNTHESE" in current_app.config["SYNTHESE"]["ALERT_MODULES"]:
        fields.append("reports.report_type.type")
        synthese_query = synthese_query.options(
            lazyload(Synthese.reports).joinedload(TReport.report_type)
        )

    try:
        synthese = (
            db.session.execute(synthese_query.filter_by(id_synthese=id_synthese))
            .unique()
            .scalar_one()
        )
    except NoResultFound:
        raise NotFound()
    if not synthese.has_instance_permission(permissions=permissions):
        raise Forbidden()

    _, precise_permissions = split_blurring_precise_permissions(permissions)

    # If blurring permissions and obs sensitive.
    if (
        not synthese.has_instance_permission(precise_permissions)
        and synthese.nomenclature_sensitivity.cd_nomenclature != "0"
    ):
        # Use a cte to have the areas associated with the current id_synthese
        cte = select(CorAreaSynthese).where(CorAreaSynthese.id_synthese == id_synthese).cte()
        # Blurred area of the observation
        BlurredObsArea = aliased(LAreas)
        # Blurred area type of the observation
        BlurredObsAreaType = aliased(BibAreasTypes)
        # Types "larger" or equal in area hierarchy size that the blurred area type
        BlurredAreaTypes = aliased(BibAreasTypes)
        # Areas associates with the BlurredAreaTypes
        BlurredAreas = aliased(LAreas)

        # Inner join that retrieve the blurred area of the obs and the bigger areas
        # used for "Zonages" in Synthese. Need to have size_hierarchy from ref_geo
        inner = (
            join(CorAreaSynthese, BlurredObsArea)
            .join(BlurredObsAreaType)
            .join(
                cor_sensitivity_area_type,
                cor_sensitivity_area_type.c.id_area_type == BlurredObsAreaType.id_type,
            )
            .join(
                BlurredAreaTypes,
                BlurredAreaTypes.size_hierarchy >= BlurredObsAreaType.size_hierarchy,
            )
            .join(BlurredAreas, BlurredAreaTypes.id_type == BlurredAreas.id_type)
            .join(cte, cte.c.id_area == BlurredAreas.id_area)
        )

        # Outer join to join CorAreaSynthese taking into account the sensitivity
        outer = (
            inner,
            and_(
                Synthese.id_synthese == CorAreaSynthese.id_synthese,
                Synthese.id_nomenclature_sensitivity
                == cor_sensitivity_area_type.c.id_nomenclature_sensitivity,
            ),
        )

        synthese_query = (
            synthese_query.outerjoin(*outer)
            # contains_eager: to populate Synthese.areas directly
            .options(contains_eager(Synthese.areas.of_type(BlurredAreas)))
            .options(
                with_expression(
                    Synthese.the_geom_authorized,
                    func.coalesce(BlurredObsArea.geom_4326, Synthese.the_geom_4326),
                )
            )
            .order_by(BlurredAreaTypes.size_hierarchy)
        )
    else:
        synthese_query = synthese_query.options(
            lazyload("areas").options(
                joinedload("area_type"),
            ),
            with_expression(Synthese.the_geom_authorized, Synthese.the_geom_4326),
        )

    synthese = (
        db.session.execute(synthese_query.filter(Synthese.id_synthese == id_synthese))
        .unique()
        .scalar_one()
    )

    synthese_schema = SyntheseSchema(
        only=Synthese.nomenclature_fields + fields,
        exclude=["areas.geom"],
        as_geojson=True,
        feature_geometry="the_geom_authorized",
    )
    return synthese_schema.dump(synthese)
