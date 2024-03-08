from sqlalchemy.sql.expression import select, update, join
import sqlalchemy as sa
from geoalchemy2.functions import (
    ST_Transform,
    ST_IsValid,
    ST_Centroid,
)
from geonature.utils.env import db

from geonature.core.imports.checks.sql.utils import report_erroneous_rows

from ref_geo.models import LAreas


__all__ = [
    "set_geom_point",
    "convert_geom_columns",
    "check_is_valid_geography",
    "check_geography_outside",
]


def set_geom_point(imprt, entity, geom_4326_field, geom_point_field):
    transient_table = imprt.destination.get_transient_table()
    # Set the_geom_point:
    stmt = (
        update(transient_table)
        .where(transient_table.c.id_import == imprt.id_import)
        .where(transient_table.c[entity.validity_column] == True)
        .values(
            {
                geom_point_field.dest_field: ST_Centroid(
                    transient_table.c[geom_4326_field.dest_field]
                ),
            }
        )
    )
    db.session.execute(stmt)


def convert_geom_columns(imprt, entity, geom_4326_field, geom_local_field):
    """
    Set geom_local from geom_4326, or geom_4326 from geom_local.
    """
    file_srid = imprt.srid
    local_srid = db.session.execute(sa.func.Find_SRID("ref_geo", "l_areas", "geom")).scalar()
    dest_srid = None
    if file_srid == local_srid:
        # dataframe check defined geom_local, we must use it to define geom_4326
        source_col = geom_local_field.dest_field
        dest_col = geom_4326_field.dest_field
        dest_srid = 4326
    elif file_srid == 4326:
        # dataframe check defined geom_4326, we must use it to define geom_local
        source_col = geom_4326_field.dest_field
        dest_col = geom_local_field.dest_field
        dest_srid = local_srid
    else:
        # dataframe check has already defined geom_4326 and geom_local
        pass
    if dest_srid:
        transient_table = imprt.destination.get_transient_table()
        stmt = (
            update(transient_table)
            .where(transient_table.c.id_import == imprt.id_import)
            .where(transient_table.c[entity.validity_column] == True)
            .where(transient_table.c[source_col] != None)
            .values(
                {
                    dest_col: ST_Transform(transient_table.c[source_col], dest_srid),
                }
            )
        )
        db.session.execute(stmt)


def check_is_valid_geography(imprt, entity, wkt_field, geom_field):
    # It is useless to check valid WKT when created from X/Y
    transient_table = imprt.destination.get_transient_table()
    where_clause = sa.and_(
        transient_table.c[wkt_field.source_field] != None,
        sa.not_(ST_IsValid(transient_table.c[geom_field.dest_field])),
    )
    report_erroneous_rows(
        imprt,
        entity,
        error_type="INVALID_GEOMETRY",
        error_column="WKT",
        whereclause=where_clause,
    )


def check_geography_outside(imprt, entity, geom_local_field, id_area):
    transient_table = imprt.destination.get_transient_table()
    area = LAreas.query.filter(LAreas.id_area == id_area).one()
    report_erroneous_rows(
        imprt,
        entity,
        error_type="GEOMETRY_OUTSIDE",
        error_column="Champs géométriques",
        whereclause=sa.and_(
            transient_table.c[entity.validity_column] == True,
            transient_table.c[geom_local_field.dest_field].ST_Disjoint(area.geom),
        ),
    )
