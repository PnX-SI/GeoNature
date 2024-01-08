from functools import lru_cache

from flask import g
import sqlalchemy as sa
from sqlalchemy.orm import aliased
from pypnnomenclature.models import BibNomenclaturesTypes, TNomenclatures
from ref_geo.models import BibAreasTypes, LAreas

from geonature.core.gn_synthese.models import CorAreaSynthese, Synthese, VSyntheseForWebApp
from geonature.core.sensitivity.models import cor_sensitivity_area_type
from geonature.core.gn_synthese.utils.query_select_sqla import SyntheseQuery


def split_blurring_precise_permissions(permissions):
    """
    Return permissions respectively with and without sensitivity filter.
    """
    return [p for p in permissions if p.sensitivity_filter], [
        p for p in permissions if not p.sensitivity_filter
    ]


@lru_cache()  # to retrive non sensitive nomenclature only on first call
def build_sensitive_unsensitive_filters():
    """
    Return where clauses for sensitive and non-sensitive observations.
    """
    non_sensitive_nomenc = (
        TNomenclatures.query.with_entities(TNomenclatures.id_nomenclature)
        .filter(
            TNomenclatures.nomenclature_type.has(BibNomenclaturesTypes.mnemonique == "SENSIBILITE")
        )
        .filter(TNomenclatures.cd_nomenclature == "0")
        .one()
    )

    return (
        Synthese.id_nomenclature_sensitivity != non_sensitive_nomenc.id_nomenclature,
        Synthese.id_nomenclature_sensitivity == non_sensitive_nomenc.id_nomenclature,
    )


def build_blurred_precise_geom_queries(
    filters, where_clauses: list = [], select_size_hierarchy=False
):
    # Build 2 queries that will be UNIONed
    # The where_clauses list enables to add more conditions to the base query
    # Used in export query
    where_clauses.append(Synthese.the_geom_4326.isnot(None))

    # Query precise geom, for use with unsensitive observations
    # and sensitive observations with precise permission
    columns = [
        sa.literal(1).label("priority"),
        Synthese.id_synthese.label("id_synthese"),
        Synthese.the_geom_4326.label("geom"),
    ]
    # Size hierarchy can be used here to filter on it in
    # a mesh mode scenario.
    if select_size_hierarchy:
        # 0 since no blurring geometry is associated here and a point have a 0 size
        columns.append(sa.literal(0).label("size_hierarchy"))
    precise_geom_query = SyntheseQuery(
        Synthese,
        sa.select(*columns).where(sa.and_(*where_clauses)).order_by(Synthese.id_synthese.desc()),
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
    geom = LAreasAlias.geom.st_transform(4326).label("geom")
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
        columns.append(BibAreasTypes.size_hierarchy.label("size_hierarchy"))
    blurred_geom_query = SyntheseQuery(
        Synthese,
        sa.select(*columns)
        .where(
            cor_sensitivity_area_type.c.id_nomenclature_sensitivity
            == Synthese.id_nomenclature_sensitivity
        )
        .where(sa.and_(*where_clauses))
        .order_by(Synthese.id_synthese.desc()),
        filters=dict(filters),
        query_joins=sa.join(
            Synthese,
            CorAreaSyntheseAlias,
            CorAreaSyntheseAlias.id_synthese == Synthese.id_synthese,
        ),
        geom_column=LAreas.geom_4326,
    )
    # Joins here are needed to retrieve the blurred geometry
    blurred_geom_query.add_join(LAreasAlias, LAreasAlias.id_area, CorAreaSyntheseAlias.id_area)
    blurred_geom_query.add_join(
        BibAreasTypesAlias, BibAreasTypesAlias.id_type, LAreasAlias.id_type
    )
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
    blurring_permissions,
    precise_permissions,
    blurred_geom_query,
    precise_geom_query,
    limit,
):
    """ """
    # The goal is to separate the blurring and precise permissions.
    # But in sensitive permissions there can be unsensitive observations so we need
    # to split them.
    # sensitive_where_clause and unsensitive_where_clause represents this split
    # See https://github.com/PnX-SI/GeoNature/issues/2558

    sensitive_obs_filter, unsensitive_obs_filter = build_sensitive_unsensitive_filters()

    # Note: the used query is not important here, as it is only used to select the right Synthese model
    precise_perms_filter = precise_geom_query.build_permissions_filter(
        g.current_user,
        precise_permissions,
    )
    blurring_perms_filter = precise_geom_query.build_permissions_filter(
        g.current_user,
        blurring_permissions,
    )

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


def build_synthese_obs_query(observations, allowed_geom_cte, limit):
    # Final observation query
    # orderby priority as explained in build_allowed_geom_cte()
    obs_query = (
        sa.select(observations)
        .select_from(
            VSyntheseForWebApp.__table__.join(
                allowed_geom_cte, allowed_geom_cte.c.id_synthese == VSyntheseForWebApp.id_synthese
            )
        )
        .order_by(VSyntheseForWebApp.id_synthese, allowed_geom_cte.c.priority)
        .distinct(VSyntheseForWebApp.id_synthese)
        .limit(limit)
    )
    return obs_query
