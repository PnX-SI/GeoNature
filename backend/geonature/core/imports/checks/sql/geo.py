from geonature.core.imports.checks.errors import ImportCodeError
from geonature.core.imports.models import BibFields, Entity, TImports
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
    "check_is_valid_geometry",
    "check_geometry_outside",
]


def set_geom_point(
    imprt: TImports,
    entity: Entity,
    geom_4326_field: BibFields,
    geom_point_field: BibFields,
) -> None:
    """
    Set the_geom_point as the centroid of the geometry in the transient table of an import.

    Parameters
    ----------
    imprt : TImports
        The import to update.
    entity : Entity
        The entity to update.
    geom_4326_field : BibFields
        Field containing the geometry in the transient table.
    geom_point_field : BibFields
        Field to store the centroid of the geometry in the transient table.

    Returns
    -------
    None
    """
    transient_table = imprt.destination.get_transient_table()
    # Set the_geom_point:
    stmt = (
        update(transient_table)
        .where(
            transient_table.c.id_import == imprt.id_import,
            transient_table.c[entity.validity_column] == True,
        )
        .values(
            {
                geom_point_field.dest_field: ST_Centroid(
                    transient_table.c[geom_4326_field.dest_field]
                ),
            }
        )
    )
    db.session.execute(stmt)


def convert_geom_columns(
    imprt: TImports,
    entity: Entity,
    geom_4326_field: BibFields,
    geom_local_field: BibFields,
) -> None:
    """
    Convert the geometry from the file SRID to the local SRID in the transient table of an import.

    Parameters
    ----------
    imprt : TImports
        The import to update.
    entity : Entity
        The entity to update.
    geom_4326_field : BibFields
        Field representing the geometry in the transient table in SRID 4326.
    geom_local_field : BibFields
        Field representing the geometry in the transient table in the local SRID.
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
            .where(
                transient_table.c.id_import == imprt.id_import,
                transient_table.c[entity.validity_column] == True,
                transient_table.c[source_col] != None,
            )
            .values(
                {
                    dest_col: ST_Transform(transient_table.c[source_col], dest_srid),
                }
            )
        )
        db.session.execute(stmt)


def check_is_valid_geometry(
    imprt: TImports,
    entity: Entity,
    wkt_field: BibFields,
    geom_field: BibFields,
) -> None:
    """
    Check if the geometry is valid in the transient table of an import.

    Parameters
    ----------
    imprt : TImports
        The import to check.
    entity : Entity
        The entity to check.
    wkt_field : BibFields
        Field containing the source WKT of the geometry.
    geom_field : BibFields
        Field containing the geometry from the WKT in `wkt_field` to be validated.

    """
    # It is useless to check valid WKT when created from X/Y
    transient_table = imprt.destination.get_transient_table()
    where_clause = sa.and_(
        transient_table.c[wkt_field.source_field] != None,
        sa.not_(ST_IsValid(transient_table.c[geom_field.dest_field])),
    )
    report_erroneous_rows(
        imprt,
        entity,
        error_type=ImportCodeError.INVALID_GEOMETRY,
        error_column="WKT",
        whereclause=where_clause,
    )


def check_geometry_outside(
    imprt: TImports,
    entity: Entity,
    geom_local_field: BibFields,
    id_area: int,
) -> None:
    """
    For an import, check if one or more geometries in the transient table are outside a defined area.

    Parameters
    ----------
    imprt : TImports
        The import to check.
    entity : Entity
        The entity to check.
    geom_local_field : BibFields
        Field containing the geometry in the local SRID of the area.
    id_area : int
        The id of the area to check if the geometry is inside.

    """
    transient_table = imprt.destination.get_transient_table()
    area = db.session.execute(sa.select(LAreas).where(LAreas.id_area == id_area)).scalar_one()
    report_erroneous_rows(
        imprt,
        entity,
        error_type=ImportCodeError.GEOMETRY_OUTSIDE,
        error_column="Champs géométriques",
        whereclause=sa.and_(
            transient_table.c[entity.validity_column] == True,
            transient_table.c[geom_local_field.dest_field].ST_Disjoint(area.geom),
        ),
    )
