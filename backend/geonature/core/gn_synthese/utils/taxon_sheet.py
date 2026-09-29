from flask import g
import typing
from geonature.core.gn_permissions.tools import get_permissions
from geonature.utils.env import db
from ref_geo.models import LAreas, BibAreasTypes

from geonature.core.gn_synthese.models import Synthese
from sqlalchemy import select, desc, asc, column, func, and_, exists, or_, true
from apptax.taxonomie.models import Taxref, TaxrefTree
from geonature.core.gn_synthese.utils.query_select_sqla import SyntheseQuery
from sqlalchemy.orm import Query, aliased
from sqlalchemy.sql.selectable import Select
from werkzeug.exceptions import BadRequest
from flask_sqlalchemy.pagination import Pagination
from enum import Enum


class TaxonSheet:

    def __init__(self, cd_ref):
        self.cd_ref = cd_ref

    def has_instance_permission(self, permissions=[]):
        list_cd_nom = []
        for perm in permissions:
            if perm.taxons_filter:
                list_cd_nom.extend([t.cd_nom for t in perm.taxons_filter])

        child_taxon_cte = (
            select(TaxrefTree.cd_nom)
            .where(
                TaxrefTree.path.op("<@")(
                    select(func.array_agg(TaxrefTree.path))
                    .where(TaxrefTree.cd_nom.in_(list_cd_nom))
                    .scalar_subquery()
                )
            )
            .cte()
        )
        if len(list_cd_nom) > 0:
            is_authorized = db.session.scalar(
                exists(TaxrefTree)
                .select_from(TaxrefTree.__table__.join(child_taxon_cte, true()))
                .where(child_taxon_cte.c.cd_nom.in_([self.cd_ref]))
                .select()
            )
            return is_authorized

        return True


class TaxonSheetUtils:

    @staticmethod
    def get_cd_nom_list_from_cd_ref(cd_ref: int) -> typing.List[int]:
        return db.session.scalars(select(Taxref.cd_nom).where(Taxref.cd_ref == cd_ref))

    @staticmethod
    def get_synthese_query_with_permissions(
        current_user, permissions, query: Query
    ) -> SyntheseQuery:
        synthese_query_obj = SyntheseQuery(Synthese, query, {})
        synthese_query_obj.filter_query_with_permissions(current_user, permissions)
        if isinstance(query, Select):
            # For Core `select()`-based queries, permission joins accumulated in
            # `query_joins` (e.g. the taxonomic filter's join to TaxrefTree) are only
            # attached to the FROM clause by `build_query()`. Without this, TaxrefTree
            # is still referenced by the WHERE clause (taxonomic filter) but gets
            # implicitly added to FROM with no join condition, causing a cartesian
            # product. Legacy `Query` objects (used e.g. by taxon_observers) already
            # build their FROM/JOIN clauses eagerly and cannot call `select_from()`
            # after a criterion has been applied, so they keep the previous behavior.
            return synthese_query_obj.build_query()
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
        return (
            select(TaxrefTree.cd_nom)
            .where(
                TaxrefTree.path.op("<@")(
                    select(TaxrefTree.path).where(TaxrefTree.cd_nom == cd_ref).scalar_subquery()
                )
            )
            .alias("taxons")
        )
