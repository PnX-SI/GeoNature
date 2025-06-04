import json
from enum import Enum

from flask import request, g, current_app, jsonify
from geojson import Feature, FeatureCollection
from sqlalchemy import func, select
from werkzeug.exceptions import BadRequest

from geonature.core.gn_permissions.decorators import permissions_required
from geonature.core.gn_synthese.models import VSyntheseForWebApp, CorAreaSynthese
from geonature.core.gn_synthese.utils.blurring import split_blurring_precise_permissions
from geonature.core.gn_synthese.utils.query_select_sqla import SyntheseQuery
from geonature.utils.env import db
from ref_geo.models import BibAreasTypes, LAreas


class GeomMode(str, Enum):
    AREA = 'area'
    PRECISE = 'precise'
    AUTO = 'auto'


def _aggregate_by_area(observation_subquery, area_aggregation_type):
    """
    From a subquery, or cte aggregate with area of type area_aggregation_type
    """
    agg_areas = (
        select(CorAreaSynthese.id_synthese, LAreas.id_area)
        .join(CorAreaSynthese, CorAreaSynthese.id_area == LAreas.id_area)
        .join(BibAreasTypes, BibAreasTypes.id_type == LAreas.id_type)
        .where(
            CorAreaSynthese.id_synthese == VSyntheseForWebApp.id_synthese,
            BibAreasTypes.type_code == area_aggregation_type,
        )
    )
    agg_areas = agg_areas.lateral("agg_areas")
    obs_query_aggregated_by_area = (
        select(func.ST_AsGeoJSON(LAreas.geom_4326).label("geojson"), observation_subquery.c.id_synthese)
        .select_from(
            observation_subquery.outerjoin(
                agg_areas, agg_areas.c.id_synthese == observation_subquery.c.id_synthese
            ).outerjoin(LAreas, LAreas.id_area == agg_areas.c.id_area)
        )
        .cte("OBSERVATIONS")
    )
    return obs_query_aggregated_by_area


def _geom_area_mode(filters, permissions, area_aggregation_type):
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
        obs_query = obs_query.subquery("obs")
        obs_query_aggregated_by_area = _aggregate_by_area(obs_query, area_aggregation_type)

        query = select(obs_query_aggregated_by_area.c.geojson,
                       func.count(obs_query_aggregated_by_area.c.id_synthese).label("observations_count")).group_by(
            obs_query_aggregated_by_area.c.geojson)
    else:
        raise NotImplemented("Not implemented blurring permissions")
    results = db.session.execute(query)
    geojson_features = []
    for geom_as_geojson, observation_count in results.all():
        geojson_features.append(
            Feature(
                geometry=json.loads(geom_as_geojson) if geom_as_geojson else None,
                properties={"observation_count": observation_count},
            )
        )
    return jsonify(FeatureCollection(geojson_features))


@permissions_required("R", module_code="SYNTHESE")
def geoms(permissions):
    """
    This route is used to return all geom as filtered.
    Three mode exists for this route,
     - Precise return all geom as point;
     - Area return the geom of each areas. For each areas, we only return the number of entities. You must supply
     the area_aggregation_type if you use this mode
     - Auto can either return Precise or Area depending on the number of entities found. This route is the most
     optimised.

     :qparam str area_aggregation_type: Must be present if you want to use Area. Else is ignored.
     :qparam str geom_mode: The mode for the route

     For the other params see get_observations_for_web route
    """
    # TODO ET LA BBOX ?
    # AUTRES MODES
    # BLURRING
    # PERMISSIONS
    filters = request.json if request.is_json else {}
    if not isinstance(filters, dict):
        raise BadRequest("Bad filters")
    geom_mode_str = filters.pop("geom_mode", GeomMode.AUTO.value)
    try:
        geom_mode = GeomMode(geom_mode_str)
    except ValueError:
        raise BadRequest(f"geom mode {geom_mode_str} is not supported")
    if geom_mode == GeomMode.AREA:
        area_aggregation_type = filters.pop("area_aggregation_type", None)
        if not area_aggregation_type:
            raise BadRequest(f"geom mode {GeomMode.AREA} is not supported without area_aggregation_type param")

        return _geom_area_mode(filters, permissions, area_aggregation_type)
    raise NotImplemented("Mode not implemented yet")
