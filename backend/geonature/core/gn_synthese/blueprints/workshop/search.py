from flask import request, current_app, jsonify, g
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
from pypnusershub.db.models import User
import sqlalchemy as sa
from geonature.utils.env import db
from geonature.core.gn_permissions.tools import get_permissions
from geonature.core.gn_permissions.decorators import permissions_required
from utils_flask_sqla.db import ordered


def synthese_column_formatters(param_column_list):
    columns = {}
    if "count_min_max" in param_column_list:
        count_min_max = sa.case(
            (
                VSyntheseForWebApp.count_min != VSyntheseForWebApp.count_max,
                sa.func.concat(VSyntheseForWebApp.count_min, " - ", VSyntheseForWebApp.count_max),
            ),
            (
                VSyntheseForWebApp.count_min != None,
                sa.func.concat(VSyntheseForWebApp.count_min),
            ),
            else_="",
        ).label("count_min_max")
        columns["count_min_max"] = count_min_max
        param_column_list.remove("count_min_max")

    if "nom_vern_or_lb_nom" in param_column_list:
        nom_vern_or_lb_nom = sa.func.coalesce(
            sa.func.nullif(VSyntheseForWebApp.nom_vern, ""), VSyntheseForWebApp.lb_nom
        ).label("nom_vern_or_lb_nom")
        columns["nom_vern_or_lb_nom"] = nom_vern_or_lb_nom
        param_column_list.remove("nom_vern_or_lb_nom")
    return columns


@permissions_required("R", module_code="SYNTHESE")
def observations(permissions):
    parameters = request.json or {}
    per_page = parameters.pop("per_page", None)
    page = parameters.pop("page", None)
    limit = parameters.pop("limit", None)
    with_geom = parameters.pop("with_geom", True)
    format = parameters.pop("format", "json")
    query_columns = parameters.pop("columns", MANDATORY_COLUMNS)
    order_by = parameters.pop("order_by", "date_min")  # Par défaut, on ordonne par date_min

    blurring_permissions, precise_permissions = split_blurring_precise_permissions(permissions)

    columns = synthese_column_formatters(query_columns)
    columns.update({col: getattr(VSyntheseForWebApp, col) for col in query_columns})

    if with_geom or format == "geojson":
        columns.update(
            {
                "geojson": sa.func.st_asgeojson(VSyntheseForWebApp.the_geom_4326)
                .cast(sa.JSON)
                .label("geojson")
            }
        )

    if format == "geojson":
        cols = []
        for colname, col_ in columns.items():
            if colname != "geojson":
                cols.extend([colname, col_])

    #########################
    # CREATING THE QUERY
    #########################

    if blurring_permissions:
        blurred_geom_query, precise_geom_query = build_blurred_precise_geom_queries(
            parameters, select_size_hierarchy=False
        )

        allowed_geom_cte = build_allowed_geom_cte(
            blurring_permissions=blurring_permissions,
            precise_permissions=precise_permissions,
            blurred_geom_query=blurred_geom_query,
            precise_geom_query=precise_geom_query,
            limit=limit,
        )

        obs_query = build_synthese_obs_query(
            observations=list(columns.values()),
            allowed_geom_cte=allowed_geom_cte,
            limit=limit,
        )
    else:
        obs_query = sa.select(list(columns.values())).where(
            VSyntheseForWebApp.the_geom_4326.isnot(None)
        )

        if limit:
            obs_query = obs_query.limit(limit)

    # Add filters to observations CTE query
    synthese_query_class = SyntheseQuery(
        VSyntheseForWebApp,
        obs_query,
        parameters,
    )
    synthese_query_class.apply_all_filters(g.current_user, permissions)
    obs_query = synthese_query_class.build_query()

    # Utilisez la colonne spécifiée par l'utilisateur pour ordonner les résultats

    obs_query = ordered(obs_query, VSyntheseForWebApp)

    if page and per_page:
        paginated_query = db.paginate(select=obs_query, page=page, per_page=per_page, scalars=False)
        if format == "geojson":
            features = [
                {
                    "type": "Feature",
                    "geometry": item.geojson,
                    "properties": {col: getattr(item, col) for col in cols[::2]},
                }
                for item in paginated_query.items
            ]
            return jsonify(
                {
                    "items": {"type": "FeatureCollection", "features": features},
                    "total": paginated_query.total,
                    "page": paginated_query.page,
                    "per_page": paginated_query.per_page,
                    "pages": paginated_query.pages,
                    "total": paginated_query.total,
                    "prev_num": paginated_query.prev_num,
                    "next_num": paginated_query.next_num,
                }
            )
        return jsonify(paginated_query)

    obj_query = db.session.execute(obs_query)
    if format == "geojson":
        features = [
            {
                "type": "Feature",
                "geometry": item.geojson,
                "properties": {col: getattr(item, col) for col in cols[::2]},
            }
            for item in obj_query.all()
        ]
        return jsonify({"type": "FeatureCollection", "features": features})

    return jsonify([dict(row) for row in obj_query.mappings()])
