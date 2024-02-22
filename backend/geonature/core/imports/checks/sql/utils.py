from sqlalchemy import func
from sqlalchemy.sql.expression import select, update, insert, literal
import sqlalchemy as sa
from sqlalchemy.dialects.postgresql import array_agg, aggregate_order_by

from geonature.utils.env import db

from geonature.core.imports.models import (
    ImportUserError,
    ImportUserErrorType,
)
from geonature.core.imports.utils import generated_fields


__all__ = ["get_duplicates_query", "report_erroneous_rows"]


def get_duplicates_query(imprt, dest_field, whereclause=sa.true()):
    transient_table = imprt.destination.get_transient_table()
    whereclause = sa.and_(
        transient_table.c.id_import == imprt.id_import,
        whereclause,
    )
    partitions = (
        select(
            array_agg(transient_table.c.line_no)
            .over(
                partition_by=dest_field,
            )
            .label("duplicate_lines")
        )
        .where(whereclause)
        .alias("partitions")
    )
    duplicates = (
        select([func.unnest(partitions.c.duplicate_lines).label("lines")])
        .where(func.array_length(partitions.c.duplicate_lines, 1) > 1)
        .alias("duplicates")
    )
    return duplicates


def report_erroneous_rows(imprt, entity, error_type, error_column, whereclause):
    """
    This function report errors where whereclause in true.
    But the function also set validity column to False for errors with ERROR level.
    Warning: level of error "ERROR", the entity must be defined
    """
    transient_table = imprt.destination.get_transient_table()
    error_type = ImportUserErrorType.query.filter_by(name=error_type).one()
    error_column = generated_fields.get(error_column, error_column)
    error_column = imprt.fieldmapping.get(error_column, error_column)
    if error_type.level == "ERROR":
        assert entity is not None
        cte = (
            update(transient_table)
            .values(
                {
                    transient_table.c[entity.validity_column]: False,
                }
            )
            .where(transient_table.c.id_import == imprt.id_import)
            .where(whereclause)
            .returning(transient_table.c.line_no)
            .cte("cte")
        )
    else:
        cte = (
            select(transient_table.c.line_no)
            .where(transient_table.c.id_import == imprt.id_import)
            .where(whereclause)
            .cte("cte")
        )

    insert_args = {
        ImportUserError.id_import: literal(imprt.id_import).label("id_import"),
        ImportUserError.id_type: literal(error_type.pk).label("id_type"),
        ImportUserError.rows: array_agg(aggregate_order_by(cte.c.line_no, cte.c.line_no)).label(
            "rows"
        ),
        ImportUserError.column: literal(error_column).label("error_column"),
    }

    if entity is not None:
        ImportUserError.id_entity: literal(entity.id_entity).label("id_entity")

    # Create the final insert statement
    error_select = select(insert_args.values()).alias("error")
    stmt = insert(ImportUserError).from_select(
        names=insert_args.keys(),
        select=(select(error_select).where(error_select.c.rows != None)),
    )
    db.session.execute(stmt)
