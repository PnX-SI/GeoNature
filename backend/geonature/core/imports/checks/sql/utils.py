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
import pandas as pd


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
        .distinct("lines")
        .alias("duplicates")
    )
    return duplicates


def report_erroneous_rows(
    imprt,
    entity,
    error_type,
    error_column,
    whereclause,
    error_comment=None,
    level_validity_mapping={"ERROR": False},
):
    """
    Report erroneous rows in a transient table and update validity of rows based on error level.

    This function reports errors found in imported data based on a WHERE clause, and updates the validity
    column of affected rows if the error level is specified in `level_validity_mapping`.
    By default, errors with the level "ERROR" mark the row as invalid.

    Parameters
    ----------
    imprt : TImport
        The current import object.
    entity : Entity
        The entity associated with the error. Must be defined if the error level is "ERROR".
    error_type : str
        Type of error to report. Must correspond to a record in `ImportUserErrorType`.
    error_column : str
        Name of the column where the error is detected. Can be mapped via `imprt.fieldmapping`.
    whereclause : sqlalchemy.sql.elements.ClauseElement
        SQL clause defining the rows affected by the error.
    error_comment : str, optional
        Optional comment to include extra explanation to describe the error in the current import context.
    level_validity_mapping : dict, optional
        Dictionary mapping error levels to validity values:
        - If the level is not in the dictionary, the row validity remains unchanged.
        - If the level is present, validity is set according to the associated value:
          - `False`: The row is marked as erroneous.
          - `None`: The row is marked as should not be imported.
        By default, only the level "ERROR" is mapped to `False`.

    Raises
    ------
    AssertionError
        If `entity` is not defined for an error of level "ERROR".

    Examples
    --------
    >>> # Example usage for reporting an "ERROR" level error
    >>> report_erroneous_rows(
    ...     imprt=my_import,
    ...     entity=my_entity,
    ...     error_type="MISSING_VALUE",
    ...     error_column="customer_name",
    ...     whereclause=(transient_table.c.customer_name == None),
    ...     error_comment="Customer name missing",
    ... )
    """

    transient_table = imprt.destination.get_transient_table()
    error_type = ImportUserErrorType.query.filter_by(name=error_type).one()
    error_column = generated_fields.get(error_column, error_column)
    error_column = imprt.fieldmapping.get(error_column, {}).get("column_src", error_column)
    if error_type.level in level_validity_mapping:
        assert entity is not None
        cte = (
            update(transient_table)
            .values(
                {
                    transient_table.c[entity.validity_column]: level_validity_mapping[
                        error_type.level
                    ],
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
        ImportUserError.comment: literal(error_comment).label("error_comment"),
    }

    if entity is not None:
        insert_args.update(
            {
                ImportUserError.id_entity: literal(entity.id_entity).label("id_entity"),
            }
        )

    # Create the final insert statement
    error_select = select(insert_args.values()).alias("error")
    stmt = insert(ImportUserError).from_select(
        names=insert_args.keys(),
        select=(select(error_select).where(error_select.c.rows != None)),
    )
    db.session.execute(stmt)


def print_transient_table(imprt, columns=None):
    trans_table = imprt.destination.get_transient_table()
    res = db.session.execute(
        sa.select(*([trans_table.c[col] for col in columns] if columns else [trans_table]))
        .where(imprt.id_import == trans_table.c.id_import)
        .order_by(trans_table.c.line_no)
    ).all()
    print(pd.DataFrame(res, columns=columns).to_string())
