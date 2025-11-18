from sqlalchemy import desc, asc
from sqlalchemy.orm import Query
from flask_sqlalchemy.pagination import Pagination
from enum import Enum


class PaginationSortingUtils:

    class SortOrder(Enum):
        ASC = "asc"
        DESC = "desc"

    @staticmethod
    def update_query_with_sorting(query: Query, sort_by: str, sort_order: SortOrder) -> Query:
        if sort_order == PaginationSortingUtils.SortOrder.ASC:
            return query.order_by(asc(sort_by))

        return query.order_by(desc(sort_by))

    @staticmethod
    def paginate(query: Query, page: int, per_page: int) -> Pagination:
        return query.paginate(page=page, per_page=per_page, error_out=False)
