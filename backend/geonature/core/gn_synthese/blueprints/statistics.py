from flask import Blueprint, Response, g, jsonify, request
from geonature.core.gn_meta.models import TDatasets
from geonature.core.gn_permissions.decorators import (
    login_required,
    permissions_required,
)
from geonature.core.gn_synthese.models import Synthese
from geonature.core.gn_synthese.utils.query_select_sqla import SyntheseQuery
from geonature.utils.env import DB, db
from utils_flask_sqla.response import json_resp

import sqlalchemy as sa
from sqlalchemy import distinct, func, select
from werkzeug.exceptions import BadRequest

statistics_routes = Blueprint("synthese_statistics", __name__)

@statistics_routes.route("/taxa_count", methods=["GET"])
@login_required
@json_resp
def get_taxa_count():
    """
    Get taxa count in synthese filtering with generic parameters

    .. :quickref: Synthese;

    Parameters
    ----------
    id_dataset: `int` (query parameter)

    Returns
    -------
    count: `int`:
        the number of taxon
    """
    params = request.args

    query = (
        select(func.count(distinct(Synthese.cd_nom)))
        .select_from(Synthese)
        .where(Synthese.id_dataset == params["id_dataset"] if "id_dataset" in params else True)
    )
    return db.session.scalar(query)


@statistics_routes.route("/observation_count", methods=["GET"])
@login_required
@json_resp
def get_observation_count():
    """
    Get observations found in a given dataset

    .. :quickref: Synthese;

    Parameters
    ----------
    id_dataset: `int` (query parameter)

    Returns
    -------
    count: `int`:
        the number of observation

    """
    params = request.args

    query = select(func.count(Synthese.id_synthese)).select_from(Synthese)

    if "id_dataset" in params:
        query = query.where(Synthese.id_dataset == params["id_dataset"])

    return DB.session.execute(query).scalar_one()


@statistics_routes.route("/observations_bbox", methods=["GET"])
@login_required
def get_bbox():
    """
    Get bbox of observations

    .. :quickref: Synthese;

    Parameters
    -----------
    id_dataset: int: (query parameter)

    Returns
    -------
        bbox: `geojson`:
            the bounding box in geojson
    """
    params = request.args

    query = select(func.ST_AsGeoJSON(func.ST_Extent(Synthese.the_geom_4326)))

    if "id_dataset" in params:
        query = query.where(Synthese.id_dataset == params["id_dataset"])
    if "id_source" in params:
        query = query.where(Synthese.id_source == params["id_source"])
    data = db.session.execute(query).one()
    if data and data[0]:
        return Response(data[0], mimetype="application/json")
    return "", 204


@statistics_routes.route("/observation_count_per_column/<column>", methods=["GET"])
@login_required
def observation_count_per_column(column):
    """
    Get observations count group by a given column

    This function was used to count observations per dataset,
    but this usage have been replaced by
    TDatasets.synthese_records_count.
    Remove this function as it is very inefficient?
    """
    if column not in sa.inspect(Synthese).column_attrs:
        raise BadRequest(f"No column name {column} in Synthese")
    synthese_column = getattr(Synthese, column)
    stmt = (
        select(
            func.count(Synthese.id_synthese).label("count"),
            synthese_column.label(column),
        )
        .select_from(Synthese)
        .group_by(synthese_column)
    )
    return jsonify(DB.session.execute(stmt).fetchall())


@statistics_routes.route("/general_stats", methods=["GET"])
@permissions_required("R", module_code="SYNTHESE")
@json_resp
def general_stats(permissions):
    """Return stats about synthese.

    .. :quickref: Synthese;

        - nb of observations
        - nb of distinct species
        - nb of distinct observer
        - nb of datasets
    """
    nb_allowed_datasets = db.session.scalar(
        select(func.count("*"))
        .select_from(TDatasets)
        .where(TDatasets.filter_by_readable().whereclause)
    )
    query = select(
        func.count(Synthese.id_synthese),
        func.count(func.distinct(Synthese.cd_nom)),
        func.count(func.distinct(Synthese.observers)),
    )
    synthese_query_obj = SyntheseQuery(Synthese, query, {})
    synthese_query_obj.filter_query_with_cruved(g.current_user, permissions)
    result = DB.session.execute(synthese_query_obj.query)
    synthese_counts = result.fetchone()

    data = {
        "nb_data": synthese_counts[0],
        "nb_species": synthese_counts[1],
        "nb_observers": synthese_counts[2],
        "nb_dataset": nb_allowed_datasets,
    }
    return data
