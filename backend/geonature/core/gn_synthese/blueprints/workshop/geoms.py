import json
import logging

from flask import request, g, current_app, jsonify
from geojson import Feature, FeatureCollection
from sqlalchemy import func, select
from werkzeug.exceptions import BadRequest

from geonature.core.gn_permissions.decorators import permissions_required
from geonature.core.gn_synthese.models import VSyntheseForWebApp, CorAreaSynthese
from geonature.core.gn_synthese.utils.blurring import (
    split_blurring_precise_permissions,
    build_blurred_precise_geom_queries,
    build_allowed_geom_cte,
    build_synthese_obs_query,
)
from geonature.core.gn_synthese.utils.query_select_sqla import SyntheseQuery
from geonature.utils.env import db
from ref_geo.models import BibAreasTypes, LAreas


def _aggregate_by_area(observation_subquery, area_aggregation_type, blurring):
    """
    From a subquery, or cte aggregate with area of type area_aggregation_type.
    The subquery must contains id_synthese. size_hierarchy is needed only if blurring is activated.
    """
    agg_areas = (
        select(CorAreaSynthese.id_synthese, LAreas.id_area, LAreas.area_code, LAreas.area_name)
        .join(CorAreaSynthese, CorAreaSynthese.id_area == LAreas.id_area)
        .join(BibAreasTypes, BibAreasTypes.id_type == LAreas.id_type)
        .where(
            CorAreaSynthese.id_synthese == VSyntheseForWebApp.id_synthese,
            BibAreasTypes.type_code == area_aggregation_type,
        )
    )
    if blurring:
        # Do not select cells which size_hierarchy is bigger than AREA_AGGREGATION_TYPE
        # It means that we do not aggregate obs that have a blurring geometry greater in
        # size than the aggregation area
        agg_areas = agg_areas.where(
            observation_subquery.c.size_hierarchy <= BibAreasTypes.size_hierarchy
        )
    agg_areas = agg_areas.lateral("agg_areas")
    obs_query_aggregated_by_area = (
        select(
            func.ST_AsGeoJSON(LAreas.geom_4326).label("geojson"),
            agg_areas.c.id_area.label("id_area"),
            agg_areas.c.area_name.label("area_name"),
            agg_areas.c.area_code.label("area_code"),
            observation_subquery.c.id_synthese,
        )
        .select_from(
            observation_subquery.outerjoin(
                agg_areas, agg_areas.c.id_synthese == observation_subquery.c.id_synthese
            ).outerjoin(LAreas, LAreas.id_area == agg_areas.c.id_area)
        )
        .cte("OBSERVATIONS")
    )
    return obs_query_aggregated_by_area


def _build_base_obs_subquery(permissions, filters, limit):
    """
    Create a subquery using permissions and filters to get all syntheses id that corresponds to parameters.
    """
    blurring_permissions, precise_permissions = split_blurring_precise_permissions(permissions)
    if not blurring_permissions:
        # No need to apply blurring => same path as before blurring feature
        obs_query = (
            select(VSyntheseForWebApp.id_synthese)
            .where(VSyntheseForWebApp.the_geom_4326.isnot(None))
            .order_by(VSyntheseForWebApp.date_min.desc())
        )

        # Add filters to observations CTE query
        synthese_query_class = SyntheseQuery(
            VSyntheseForWebApp,
            obs_query,
            dict(filters),
        )
        synthese_query_class.apply_all_filters(g.current_user, permissions)
        obs_query = synthese_query_class.build_query()
        logging.getLogger().error("NOT BLURRED")

    else:
        # Build 2 queries that will be UNIONed
        blurred_geom_query, precise_geom_query = build_blurred_precise_geom_queries(
            filters, select_size_hierarchy=True
        )

        allowed_geom_cte = build_allowed_geom_cte(
            blurring_permissions=blurring_permissions,
            precise_permissions=precise_permissions,
            blurred_geom_query=blurred_geom_query,
            precise_geom_query=precise_geom_query,
            limit=limit,
        )

        obs_query = build_synthese_obs_query(
            observations=VSyntheseForWebApp.id_synthese,
            allowed_geom_cte=allowed_geom_cte,
            limit=limit,
        )
        obs_query = obs_query.add_columns(allowed_geom_cte.c.size_hierarchy.label("size_hierarchy"))
        logging.getLogger().error("BLURRED")
    return obs_query.subquery("obs")


def _geom_area_mode(filters, permissions, area_aggregation_type, limit):
    """
    Get the number of observation for each area of type area_aggregation_type
    """
    blurring_permissions, _ = split_blurring_precise_permissions(permissions)
    need_blurring = bool(blurring_permissions)
    obs_subquery = _build_base_obs_subquery(permissions, filters, limit)
    obs_query_aggregated_by_area = _aggregate_by_area(
        obs_subquery, area_aggregation_type, need_blurring
    )

    query = select(
        obs_query_aggregated_by_area.c.geojson,
        obs_query_aggregated_by_area.c.id_area,
        obs_query_aggregated_by_area.c.area_name,
        obs_query_aggregated_by_area.c.area_code,
        func.count(obs_query_aggregated_by_area.c.id_synthese).label("observations_count"),
    ).group_by(
        obs_query_aggregated_by_area.c.geojson,
        obs_query_aggregated_by_area.c.id_area,
        obs_query_aggregated_by_area.c.area_name,
        obs_query_aggregated_by_area.c.area_code,
    )

    results = db.session.execute(query)
    geojson_features = []
    for geom_as_geojson, id_area, area_name, area_code, observation_count in results.all():
        geojson_features.append(
            Feature(
                geometry=json.loads(geom_as_geojson) if geom_as_geojson else None,
                properties={
                    "id_area": id_area,
                    "area_name": area_name,
                    "area_code": area_code,
                    "observation_count": observation_count,
                },
            )
        )
    return jsonify(FeatureCollection(geojson_features))


@permissions_required("R", module_code="SYNTHESE")
def geoms(permissions):
    """
    This route is used to return all geom as filtered.
    return the geom of each areas. For each areas, we only return the number of entities. You must supply
    the area_aggregation_type

    :qparam str area_aggregation_type: Must be present

     For the other params see get_observations_for_web route
    """
    filters = request.json if request.is_json else {}
    if not isinstance(filters, dict):
        raise BadRequest("Bad filters")
    area_aggregation_type = filters.pop("area_aggregation_type", None)
    result_limit = filters.pop("limit", None)
    result_limit = (
        min(result_limit, current_app.config["SYNTHESE"]["NB_MAX_OBS_MAP"])
        if result_limit
        else current_app.config["SYNTHESE"]["NB_MAX_OBS_MAP"]
    )
    if not area_aggregation_type:
        raise BadRequest(f"geom is not supported without area_aggregation_type param")
    return _geom_area_mode(filters, permissions, area_aggregation_type, result_limit)
