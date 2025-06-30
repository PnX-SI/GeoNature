from functools import lru_cache
from typing import Dict, List, Tuple

from apptax.taxonomie.models import TaxrefTree
from flask import g
import sqlalchemy as sa
from sqlalchemy.orm import aliased
from sqlalchemy.sql.expression import CTE, Select
from pypnnomenclature.models import BibNomenclaturesTypes, TNomenclatures
from ref_geo.models import BibAreasTypes, LAreas

from geonature.core.gn_synthese.models import CorAreaSynthese, Synthese, VSyntheseForWebApp
from geonature.core.sensitivity.models import cor_sensitivity_area_type
from geonature.core.gn_synthese.utils.query_select_sqla import SyntheseQuery
from geonature.core.gn_permissions.models import Permission

from geonature.utils.env import db


def split_blurring_precise_permissions(
    permissions: List[Permission],
) -> Tuple[List[Permission], List[Permission]]:
    """
    Split permissions into two lists based on sensitivity filters.

    Parameters
    ----------
    permissions : List[Permission]
        List of permissions to be split.

    Returns
    -------
    Tuple[List[Permission], List[Permission]]
        A tuple containing two lists:
            - The first list contains permissions with sensitivity filters.
            - The second list contains permissions without sensitivity filters.
    """
    return [
        blurred_permission
        for blurred_permission in permissions
        if blurred_permission.sensitivity_filter
    ], [
        precise_permission
        for precise_permission in permissions
        if not precise_permission.sensitivity_filter
    ]


@lru_cache()  # to retrive non sensitive nomenclature only on first call
def build_sensitive_unsensitive_filters() -> Tuple:
    """
    Return where clauses for sensitive and non-sensitive observations.

    Returns
    -------
    Tuple[sa.Column, sa.Column]
        A tuple containing two SQLAlchemy where clauses:
            - The first clause is for sensitive observations.
            - The second clause is for non-sensitive observations.

    """
    non_sensitive_nomenc = db.session.scalar(
        sa.select(TNomenclatures.id_nomenclature).where(
            TNomenclatures.nomenclature_type.has(BibNomenclaturesTypes.mnemonique == "SENSIBILITE"),
            TNomenclatures.cd_nomenclature == "0",
        )
    )

    return (
        Synthese.id_nomenclature_sensitivity != non_sensitive_nomenc,
        Synthese.id_nomenclature_sensitivity == non_sensitive_nomenc,
    )


def build_blurred_precise_geom_queries(
    filters: Dict[str, any],
    where_clauses: list = [],  # Optional. A list of additional WHERE  clause conditions for the base query.
    select_size_hierarchy: bool = False,  # Optional. Include size hierarchy in the result set.
) -> Tuple[SyntheseQuery, SyntheseQuery]:
    """
    Builds two SQLAlchemy queries that will be UNIONed. These queries are used for
    the export of geometries in a sensitive or non-sensitive context.

    The provided `where_clauses` list enables adding additional conditions
    to the base query.

    Parameters
    ----------
    filters: (Dict[str, any])
        A dictionary containing filteringriteria retrieved from the HTTP query.
    where_clauses: (list, optional)
        Additional WHERE clause conditions for the base query. Defaults to [].
    select_size_hierarchy: (bool, optional)
        Include the size hierarchy column in the generated queries (used in the grid mode). Defaults to False.

    Returns
    -------
        Tuple[SyntheseQuery, SyntheseQuery]
            A tuple containing two `SyntheseQuery` objects representing the blurred and precise geometries queries.

    """

    # Build 2 queries that will be UNIONed
    # The where_clauses list enables to add more conditions to the base query
    # Used in export query
    if not where_clauses:
        where_clauses = []
    where_clauses.append(Synthese.the_geom_4326.isnot(None))

    # Query precise geom, for use with unsensitive observations
    # and sensitive observations with precise permission
    columns = [
        sa.literal(1).label("priority"),
        Synthese.id_synthese.label("id_synthese"),
        Synthese.the_geom_4326.label("geom"),
    ]
    # Size hierarchy can be used here to filter on it in
    # a grid mode scenario.
    if select_size_hierarchy:
        # 0 since no blurring geometry is associated here and a point have a 0 size
        columns.append(sa.literal(0).label("size_hierarchy"))
    precise_geom_query = SyntheseQuery(
        Synthese,
        sa.select(*columns).where(sa.and_(*where_clauses)).order_by(Synthese.date_min.desc()),
        filters=dict(filters),  # not to edit the actual filter object
    )

    # In both queries, we applied all filters so that we do not need to query the
    # whole synthese table
    precise_geom_query.filter_taxonomy()
    precise_geom_query.filter_other_filters(g.current_user)
    precise_geom_query.build_query()

    # Query blurred geom, for use with sensitive observations
    CorAreaSyntheseAlias = aliased(CorAreaSynthese)
    LAreasAlias = aliased(LAreas)
    BibAreasTypesAlias = aliased(BibAreasTypes)

    geom = LAreasAlias.geom_4326.label("geom")
    # In SyntheseQuery below :
    # - query_joins parameter is needed to bypass
    #   "self.query_joins is not None" condition in the build_query() method below
    # - priority is used to prevail non blurred geom over blurred geom if the user
    #   can access to the non blurred geom
    # - orderby needed to match the non blurred and the blurred observations
    columns = [
        sa.literal(2).label("priority"),
        Synthese.id_synthese.label("id_synthese"),
        geom,
    ]
    # size hierarchy is the size of the joined blurring area
    if select_size_hierarchy:
        columns.append(BibAreasTypesAlias.size_hierarchy.label("size_hierarchy"))
    blurred_geom_query = SyntheseQuery(
        Synthese,
        sa.select(*columns)
        .where(
            cor_sensitivity_area_type.c.id_nomenclature_sensitivity
            == Synthese.id_nomenclature_sensitivity
        )
        .where(sa.and_(*where_clauses))
        .order_by(Synthese.date_min.desc()),
        filters=dict(filters),
        query_joins=sa.join(
            Synthese,
            CorAreaSyntheseAlias,
            CorAreaSyntheseAlias.id_synthese == Synthese.id_synthese,
        ),
        geom_column=LAreasAlias.geom_4326,
    )
    # Joins here are needed to retrieve the blurred geometry
    blurred_geom_query.add_join(LAreasAlias, LAreasAlias.id_area, CorAreaSyntheseAlias.id_area)
    blurred_geom_query.add_join(BibAreasTypesAlias, BibAreasTypesAlias.id_type, LAreasAlias.id_type)
    blurred_geom_query.add_join(
        cor_sensitivity_area_type,
        cor_sensitivity_area_type.c.id_area_type,
        BibAreasTypesAlias.id_type,
    )
    # Same for the first query => apply filter to avoid querying the whole table
    blurred_geom_query.filter_taxonomy()
    blurred_geom_query.filter_other_filters(g.current_user)
    blurred_geom_query.build_query()

    return blurred_geom_query, precise_geom_query


def build_allowed_geom_cte(
    blurring_permissions: List[Permission],
    precise_permissions: List[Permission],
    blurred_geom_query: SyntheseQuery,
    precise_geom_query: SyntheseQuery,
    limit: int,
) -> Select:
    """
    Apply permissions filters and sensitivity filters to separate blurring and precise permissions.

    This method ensures that sensitive and non-sensitive observations are correctly filtered based on the provided permissions.

    The goal is to separate the blurring and precise permissions.
    But in sensitive permissions there can be unsensitive observations so we need
    to split them.
    sensitive_where_clause and unsensitive_where_clause represents this split


    Parameters
    ----------
    blurring_permissions : List[Permission]
        list contains permissions with a sensitivity scope filter
    precise_permissions : List[Permission]
        list that contains permissions without sensitivity scope
    blurred_geom_query : SyntheseQuery
        SyntheseQuery object used to fetch sensitive observations
    precise_geom_query : SyntheseQuery
        SyntheseQuery object used to fetch unsensitive observations
    limit : int
        limit of observations returned

    Returns
    -------
    Select
        Union between blurred obs and non-blurred obs

    Notes
    -----
    See https://github.com/PnX-SI/GeoNature/issues/2558 for more informations
    """

    #

    sensitive_obs_filter, unsensitive_obs_filter = build_sensitive_unsensitive_filters()

    # Note: the used query is not important here, as it is only used to select the right Synthese model
    precise_perms_filter = precise_geom_query.build_permissions_filter(
        g.current_user,
        precise_permissions,
    )

    blurring_perms_filter = blurred_geom_query.build_permissions_filter(
        g.current_user,
        blurring_permissions,
    )

    # Apply missing join for taxonomic/geo permission filters
    precise_geom_query.build_permissions_filter(g.current_user, blurring_permissions)
    precise_geom_query.build_query()
    blurred_geom_query.build_query()

    # Access precise geom for obs with precise perm and for unsensitive obs with blurring perm
    precise_geom_query = precise_geom_query.query.where(
        sa.or_(
            precise_perms_filter,
            sa.and_(
                blurring_perms_filter,
                unsensitive_obs_filter,
            ),
        )
    ).limit(limit)
    # Access blurred geom for sensitive obs with blurring perms
    blurred_geom_query = blurred_geom_query.query.where(
        sa.and_(
            blurring_perms_filter,
            sensitive_obs_filter,
        )
    ).limit(limit)

    return precise_geom_query.union(blurred_geom_query).cte("allowed_geom")


def build_synthese_obs_query(
    observations_columns: List[sa.Column], allowed_geom_cte: CTE, limit: int
) -> Select:
    """
    $Generate the final query used to fetch observations when a user has a sensitivity filter in one of their permissions.

    Parameters
    ----------
    observations : List[sa.Column]
        list of fields of the Synthese returned by the query
    allowed_geom_cte : CTE
        CTE that contains all available observations
    limit : int
        number of observations limit

    Returns
    -------
    Select
        Final query
    """
    # Final observation query
    # orderby priority as explained in build_allowed_geom_cte()
    query = (
        sa.select(observations_columns)
        .select_from(
            VSyntheseForWebApp.__table__.join(
                allowed_geom_cte, allowed_geom_cte.c.id_synthese == VSyntheseForWebApp.id_synthese
            )
        )
        .order_by(
            VSyntheseForWebApp.date_min.desc(),
            VSyntheseForWebApp.id_synthese.desc(),
            allowed_geom_cte.c.priority,
        )
        .distinct(VSyntheseForWebApp.date_min, VSyntheseForWebApp.id_synthese)
        .limit(limit)
    )
    return query
