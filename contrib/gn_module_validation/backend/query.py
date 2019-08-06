from flask import current_app, request
from shapely.wkt import loads
from geoalchemy2.shape import from_shape
from sqlalchemy import func, or_, and_
from sqlalchemy.orm import aliased

from geonature.utils.env import DB
from geonature.utils.utilsgeometry import circle_from_point
from geonature.core.taxonomie.models import Taxref, CorTaxonAttribut, TaxrefLR
from geonature.core.gn_synthese.models import (
    Synthese,
    CorObserverSynthese,
    TSources,
    CorAreaSynthese,
)
from geonature.core.gn_meta.models import TDatasets, TAcquisitionFramework

from geonature.core.gn_synthese.utils.query import (
    filter_query_with_cruved,
    filter_taxonomy,
)


def filter_query_all_filters(model, q, filters, user):
    """
    Return a query filtered with the cruved and all
    the filters available in the synthese form
    parameters:
        - q (SQLAchemyQuery): an SQLAchemy query
        - filters (dict): a dict of filter
        - user (User): a user object from User
        - allowed datasets (List<int>): an array of ID dataset where the users have autorization

    """
    q = filter_query_with_cruved(model, q, user)

    if "observers" in filters:
        q = q.filter(model.observers.ilike("%" + filters.pop("observers")[0] + "%"))

    if "date_min" in filters:
        q = q.filter(model.date_min >= filters.pop("date_min")[0])

    if "date_max" in filters:
        q = q.filter(model.date_min <= filters.pop("date_max")[0])

    if "id_acquisition_frameworks" in filters:
        q = q.join(
            TAcquisitionFramework,
            model.id_acquisition_framework
            == TAcquisitionFramework.id_acquisition_framework,
        )
        q = q.filter(
            TAcquisitionFramework.id_acquisition_framework.in_(
                filters.pop("id_acquisition_frameworks")
            )
        )

    if "geoIntersection" in filters:
        # Insersect with the geom send from the map
        ors = []
        for str_wkt in filters["geoIntersection"]:
            # if the geom is a circle
            if "radius" in filters:
                radius = filters.pop("radius")[0]
                wkt = circle_from_point(loads(str_wkt), float(radius))
            else:
                wkt = loads(str_wkt)
            geom_wkb = from_shape(wkt, srid=4326)
            ors.append(model.the_geom_4326.ST_Intersects(geom_wkb))

        q = q.filter(or_(*ors))
        filters.pop("geoIntersection")

    if "period_start" in filters and "period_end" in filters:
        period_start = filters.pop("period_start")[0]
        period_end = filters.pop("period_end")[0]
        q = q.filter(
            or_(
                func.gn_commons.is_in_period(
                    func.date(model.date_min),
                    func.to_date(period_start, "DD-MM"),
                    func.to_date(period_end, "DD-MM"),
                ),
                func.gn_commons.is_in_period(
                    func.date(model.date_max),
                    func.to_date(period_start, "DD-MM"),
                    func.to_date(period_end, "DD-MM"),
                ),
            )
        )
    q, filters = filter_taxonomy(model, q, filters)

    # generic filters
    join_on_cor_area = False
    for colname, value in filters.items():
        if colname.startswith("area"):
            if not join_on_cor_area:
                q = q.join(
                    CorAreaSynthese, CorAreaSynthese.id_synthese == model.id_synthese
                )
            q = q.filter(CorAreaSynthese.id_area.in_(value))
            join_on_cor_area = True
        elif colname.startswith("modif_since_validation"):
            q = q.filter(model.meta_update_date > model.validation_date)
        else:
            col = getattr(model.__table__.columns, colname)
            q = q.filter(col.in_(value))
    return q
