import typing
from geonature.utils.env import db
from ref_geo.models import LAreas, BibAreasTypes

from geonature.core.gn_synthese.models import Synthese
from sqlalchemy import select, desc, asc, column, func, and_
from apptax.taxonomie.models import Taxref, TaxrefTree
from geonature.core.gn_synthese.utils.query_select_sqla import SyntheseQuery
from sqlalchemy.orm import Query, aliased
from sqlalchemy.sql.selectable import Select
from werkzeug.exceptions import BadRequest
from flask_sqlalchemy.pagination import Pagination
from enum import Enum


class SortOrder(Enum):
    ASC = "asc"
    DESC = "desc"


class TaxonSheetUtils:

    @staticmethod
    def update_query_with_sorting(query: Query, sort_by: str, sort_order: SortOrder) -> Query:
        if sort_order == SortOrder.ASC:
            return query.order_by(asc(sort_by))

        return query.order_by(desc(sort_by))

    @staticmethod
    def paginate(query: Query, page: int, per_page: int) -> Pagination:
        return query.paginate(page=page, per_page=per_page, error_out=False)

    #
    @staticmethod
    def get_cd_nom_list_from_cd_ref(cd_ref: int) -> typing.List[int]:
        return db.session.scalars(select(Taxref.cd_nom).where(Taxref.cd_ref == cd_ref))

    @staticmethod
    def get_synthese_query_with_scope(current_user, scope: int, query: Query) -> SyntheseQuery:
        synthese_query_obj = SyntheseQuery(Synthese, query, {})
        synthese_query_obj.filter_query_with_cruved(current_user, scope)
        return synthese_query_obj.query

    @staticmethod
    def is_valid_area_type(area_type: str) -> bool:
        # Ensure area_type is valid
        valid_area_types = (
            db.session.query(BibAreasTypes.type_code)
            .distinct()
            .filter(BibAreasTypes.type_code == area_type)
            .scalar()
        )

        return valid_area_types

    @staticmethod
    def get_area_selectquery(area_type: str) -> Select:

        # selectquery to fetch areas based on area_type
        return (
            select(LAreas.id_area)
            .where(LAreas.id_type == BibAreasTypes.id_type, BibAreasTypes.type_code == area_type)
            .alias("areas")
        )

    @staticmethod
    def get_taxon_selectquery(cd_ref: int) -> Select:
        # selectquery to fetch taxon and sub taxa based on cd_ref
        current = aliased(TaxrefTree)
        return (
            select(Taxref.cd_nom)
            .join(TaxrefTree, TaxrefTree.cd_nom == Taxref.cd_nom)
            .join(
                current,
                and_(
                    current.cd_nom == cd_ref,
                    TaxrefTree.path.op("<@")(current.path),
                ),
            )
            .alias("taxons")
        )
