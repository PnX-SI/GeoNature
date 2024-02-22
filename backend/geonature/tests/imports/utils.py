from sqlalchemy import or_, select

from geonature.utils.env import db

from geonature.core.imports.models import ImportUserErrorType


def assert_import_errors(imprt, expected_errors, entity_code=None):
    """
    expected_errors must be a set of 4-elements tuples:
        (error_name: str, entity_code: str, error_column:str , error_rows: frozenset<int>)
    if entity_code is set, expected_errors must be a set of 3-elements tuples:
        (error_name: str, error_column:str , error_rows: frozenset<int>)
    """
    if entity_code is not None:
        expected_errors = {
            (error_name, entity_code, error_column, error_rows)
            for error_name, error_column, error_rows in expected_errors
        }
    errors = {
        (
            error.type.name,
            error.entity.code if error.entity else None,
            error.column,
            frozenset(error.rows or []),
        )
        for error in imprt.errors
    }
    assert errors == expected_errors
    expected_erroneous_rows = set()
    for error_type, _, _, rows in expected_errors:
        error_type = ImportUserErrorType.query.filter_by(name=error_type).one()
        if error_type.level == "ERROR":
            expected_erroneous_rows |= set(rows)
    if imprt.processed:
        assert set(imprt.erroneous_rows or []) == expected_erroneous_rows
    else:
        transient_table = imprt.destination.get_transient_table()
        stmt = (
            select([transient_table.c.line_no])
            .where(transient_table.c.id_import == imprt.id_import)
            .where(
                or_(*[transient_table.c[v] == False for v in imprt.destination.validity_columns])
            )
        )
        erroneous_rows = {line_no for line_no, in db.session.execute(stmt)}
        assert erroneous_rows == expected_erroneous_rows
