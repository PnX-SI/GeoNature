from typing import Tuple

from flask import Response
from flask.json import jsonify
from geonature.utils.env import DB
from sqlalchemy.dialects.postgresql import JSON
from sqlalchemy.orm import Query
from werkzeug.datastructures import MultiDict

from geonature.core.gn_synthese.models import SyntheseQuery


def get_limit_page(params: MultiDict) -> Tuple[int]:
    return int(params.pop("limit", 50)), int(params.pop("page", 1))


def get_sort(params: MultiDict, default_sort: str, default_direction) -> Tuple[str]:
    return params.pop("sort", default_sort), params.pop("sort_dir", default_direction)


def paginate(query: SyntheseQuery, limit: int, page: int) -> Response:
    result = query.paginate(page=page, error_out=False, per_page=limit)
    data = dict(items=result.items, total=result.total, limit=limit, page=page)

    return data


def filter_params(query: SyntheseQuery, params: MultiDict) -> SyntheseQuery:
    if len(params) != 0:
        query = query.filter_by_params(params)
    return query


def sort(query: SyntheseQuery, sort: str, sort_dir: str) -> SyntheseQuery:
    if sort_dir in ["desc", "asc"]:
        query = query.sort(label=sort, direction=sort_dir)
    return query
