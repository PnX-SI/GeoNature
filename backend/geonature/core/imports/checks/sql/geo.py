from sqlalchemy.sql.expression import select, update, join
import sqlalchemy as sa
from geoalchemy2.functions import (
    ST_Transform,
    ST_IsValid,
    ST_Centroid,
)
from geonature.utils.env import db

from geonature.core.imports.checks.sql.utils import report_erroneous_rows

from ref_geo.models import LAreas, BibAreasTypes


__all__ = [
    "set_geom_from_area_code",
    "convert_geom_columns",
    "check_is_valid_geography",
    "check_geography_outside",
]


def set_geom_from_area_code(
    imprt, entity, geom_4326_col, geom_local_col, source_column, area_type_filter
):  # XXX specific synthese
    transient_table = imprt.destination.get_transient_table()
    # Find area in CTE, then update corresponding column in statement
    cte = (
        select(
            transient_table.c.id_import,
            transient_table.c.line_no,
            LAreas.id_area,
            LAreas.geom,
            # TODO: add LAreas.geom_4326
        )
        .select_from(
            join(transient_table, LAreas, source_column == LAreas.area_code).join(BibAreasTypes)
        )
        .where(transient_table.c.id_import == imprt.id_import)
        .where(transient_table.c[entity.validity_column] == True)
        .where(transient_table.c[geom_4326_col] == None)  # geom_4326 & local should be aligned
        .where(area_type_filter)
        .cte("cte")
    )
    stmt = (
        update(transient_table)
        .values(
            {
                transient_table.c.id_area_attachment: cte.c.id_area,
                transient_table.c[geom_local_col]: cte.c.geom,
                transient_table.c[geom_4326_col]: ST_Transform(
                    cte.c.geom, 4326
                ),  # TODO: replace with cte.c.geom_4326
            }
        )
        .where(transient_table.c.id_import == cte.c.id_import)
        .where(transient_table.c.line_no == cte.c.line_no)
    )
    db.session.execute(stmt)


def convert_geom_columns(
    imprt,
    entity,
    geom_4326_field,
    geom_local_field,
    geom_point_field=None,
    codecommune_field=None,
    codemaille_field=None,
    codedepartement_field=None,
):
    local_srid = db.session.execute(sa.func.Find_SRID("ref_geo", "l_areas", "geom")).scalar()
    transient_table = imprt.destination.get_transient_table()
    if geom_4326_field is None:
        assert geom_local_field
        source_col = geom_local_field.dest_field
        dest_col = geom_4326_field.dest_field
        dest_srid = 4326
    else:
        assert geom_4326_field is not None
        source_col = geom_4326_field.dest_field
        dest_col = geom_local_field.dest_field
        dest_srid = local_srid
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

    for field, area_type_filter in [
        (codecommune_field, BibAreasTypes.type_code == "COM"),
        (codedepartement_field, BibAreasTypes.type_code == "DEP"),
        (codemaille_field, BibAreasTypes.type_code.in_(["M1", "M5", "M10"])),
    ]:
        if field is None:
            continue
        source_column = transient_table.c[field.source_field]
        # Set geom from area of the given type and with matching area_code:
        set_geom_from_area_code(
            imprt,
            entity,
            geom_4326_field.dest_field,
            geom_local_field.dest_field,
            source_column,
            area_type_filter,
        )
        # Mark rows with code specified but geom still empty as invalid:
        report_erroneous_rows(
            imprt,
            entity,
            error_type="INVALID_ATTACHMENT_CODE",
            error_column=field.name_field,
            whereclause=sa.and_(
                transient_table.c[geom_4326_field.dest_field] == None,
                transient_table.c[entity.validity_column] == True,
                source_column != None,
            ),
        )
    # Mark rows with no geometry as invalid:
    report_erroneous_rows(
        imprt,
        entity,
        error_type="NO-GEOM",
        error_column="Colonnes géométriques",
        whereclause=sa.and_(
            transient_table.c[geom_4326_field.dest_field] == None,
            transient_table.c[entity.validity_column] == True,
        ),
    )
    # Set the_geom_point:
    if geom_point_field is not None:
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
