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
        )
        columns["count_min_max"] = count_min_max
        param_column_list.remove("count_min_max")

    if "nom_vern_or_lb_nom" in param_column_list:
        nom_vern_or_lb_nom = sa.func.coalesce(
            sa.func.nullif(VSyntheseForWebApp.nom_vern, ""), VSyntheseForWebApp.lb_nom
        )
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

    blurring_permissions, precise_permissions = split_blurring_precise_permissions(permissions)

    columns = {col: getattr(VSyntheseForWebApp, col) for col in query_columns}
    columns.update(synthese_column_formatters(query_columns))

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
            if not colname == "geojson":
                cols.extend([colname, col_])

        columns = sa.func.json_build_object(
            "type",
            "FeatureCollection",
            "features",
            sa.func.json_agg(
                sa.func.json_build_object(
                    "type",
                    "Feature",
                    "geometry",
                    columns["geojson"],
                    "properties",
                    sa.func.json_build_object(*cols),
                )
            ),
        )
    else:
        columns = list(columns.values())

    #########################
    # CREATING THE QUERY
    #########################

    # NO BLURRING

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
            observations=columns,
            allowed_geom_cte=allowed_geom_cte,
            limit=limit,
        )
    else:
        obs_query = sa.select(columns).where(VSyntheseForWebApp.the_geom_4326.isnot(None))

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

    if page and per_page:
        return jsonify(db.paginate(select=obs_query, page=page, per_page=per_page, scalars=False))

    return db.session.execute(obs_query).all()
