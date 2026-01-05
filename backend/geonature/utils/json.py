from packaging import version

from flask import g
from flask.json.provider import DefaultJSONProvider
from flask_sqlalchemy.pagination import Pagination
import sqlalchemy as sa

if version.parse(sa.__version__) >= version.parse("1.4"):
    from sqlalchemy.engine import Row
else:  # retro-compatibility SQLAlchemy 1.3
    from sqlalchemy.engine import RowProxy as Row


from contextlib import contextmanager


@contextmanager
def pagination_schema(schema):
    """
    Context manager to set the pagination schema for a given model.

    Parameters
    ----------
    schema : Model schema to use for pagination.

    Notes
    -----
    Usage:
        with pagination_schema(UserSchema):
            return jsonify(pagination)
    """
    g.pagination_schema = schema
    try:
        yield
    finally:
        g.pop("pagination_schema", None)


class MyJSONProvider(DefaultJSONProvider):
    @staticmethod
    def default(o):
        if isinstance(o, Row):
            return o._asdict()
        if isinstance(o, Pagination):
            if "pagination_schema" in g:
                items = g.pagination_schema.dump(o.items, many=True)
            else:
                items = [item.as_dict() for item in o.items]
            return {
                "items": items,
                "page": o.page,
                "per_page": o.per_page,
                "pages": o.pages,
                "total": o.total,
                "prev_num": o.prev_num,
                "next_num": o.next_num,
                "has_next": o.has_next,
                "has_prev": o.has_prev,
            }
        return DefaultJSONProvider.default(o)
