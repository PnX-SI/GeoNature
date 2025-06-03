from flask import request, current_app, jsonify
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


def synthese_column_formatters(param_column_list):
    columns = []
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
        columns += [count_min_max]
        param_column_list.remove("count_min_max")

    if "nom_vern_or_lb_nom" in param_column_list:
        nom_vern_or_lb_nom = sa.func.coalesce(
            sa.func.nullif(VSyntheseForWebApp.nom_vern, ""), VSyntheseForWebApp.lb_nom
        )
        columns += [nom_vern_or_lb_nom]
        param_column_list.remove("nom_vern_or_lb_nom")
    return columns


def observations():

    parameters = request.json or {}

    per_page = parameters.pop("per_page", None)
    page = parameters.pop("page", None)
    limit = parameters.pop("limit", None)
    with_geom = parameters.pop("with_geom", True)
    format = parameters.pop("format", "json")

    #
    current_user = db.session.get(User, 3)
    permissions = get_permissions("R", current_user.id_role, module_code="SYNTHESE")
    blurring_permissions, precise_permissions = split_blurring_precise_permissions(permissions)
    ##################################################
    ## Retrieve columns returned by the Synthese query
    ##################################################

    columns = [getattr(VSyntheseForWebApp, col) for col in MANDATORY_COLUMNS]

    # Column declared in the configuration
    configured_columns = (
        current_app.config["SYNTHESE"]["LIST_COLUMNS_FRONTEND"]
        + current_app.config["SYNTHESE"]["ADDITIONAL_COLUMNS_FRONTEND"]
    )
    param_column_list = {col["prop"] for col in configured_columns}

    columns.extend(synthese_column_formatters(param_column_list))
    columns += [getattr(VSyntheseForWebApp, column) for column in param_column_list]

    if with_geom:
        columns.append(sa.func.st_asgeojson(VSyntheseForWebApp.the_geom_4326).label("geojson"))

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
        obs_query = (
            sa.select(columns)
            .where(VSyntheseForWebApp.the_geom_4326.isnot(None))
            .order_by(VSyntheseForWebApp.date_min.desc())
        )

    if limit:
        obs_query = obs_query.limit(limit)

    # Add filters to observations CTE query
    synthese_query_class = SyntheseQuery(
        VSyntheseForWebApp,
        obs_query,
        parameters,
    )
    synthese_query_class.apply_all_filters(current_user, permissions)
    obs_query = synthese_query_class.build_query()

    if page and per_page:
        db.paginate(select=obs_query, page=page, per_page=per_page)

    return db.session.execute(obs_query).all()
