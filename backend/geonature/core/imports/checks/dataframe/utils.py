from functools import wraps
from inspect import signature

from sqlalchemy import func
from sqlalchemy.orm.exc import NoResultFound
from sqlalchemy.dialects.postgresql import insert as pg_insert

from geonature.utils.env import db

from geonature.core.imports.models import ImportUserError, ImportUserErrorType
from geonature.core.imports.utils import generated_fields


def dfcheck(check_function):
    """
    Decorator for check functions.
    Check functions must yield errors, and return updated_cols
    (or None if no column have been modified).
    """

    parameters = signature(check_function).parameters
    pass_import = "imprt" in parameters
    pass_entity = "entity" in parameters

    @wraps(check_function)
    def wrapper(imprt, entity, df, *args, **kwargs):
        updated_cols = set()
        params = []
        if pass_import:
            params.append(imprt)
        if pass_entity:
            params.append(entity)
        errors = check_function(*params, df, *args, **kwargs)
        try:
            while True:
                error = next(errors)
                updated_cols |= report_error(imprt, entity, df, error) or set()
        except StopIteration as e:
            updated_cols |= e.value or set()
        return updated_cols

    return wrapper


def report_error(imprt, entity, df, error):
    if error["invalid_rows"].empty:
        return
    try:
        error_type = ImportUserErrorType.query.filter_by(name=error["error_code"]).one()
    except NoResultFound:
        raise Exception(f"Error code '{error['error_code']}' not found.")
    invalid_rows = error["invalid_rows"]
    df.loc[invalid_rows.index, entity.validity_column] = False
    # df['gn_invalid_reason'][invalid_rows.index.intersection(df['gn_invalid_reason'].isnull())] = \
    #        f'{error_type.name}'  # FIXME comment
    ordered_invalid_rows = sorted(invalid_rows["line_no"])
    column = generated_fields.get(error["column"], error["column"])
    column = imprt.fieldmapping.get(column, column)
    # If an error for same import, same column and of the same type already exists,
    # we concat existing erroneous rows with current rows.
    stmt = pg_insert(ImportUserError).values(
        {
            "id_import": imprt.id_import,
            "id_error": error_type.pk,
            "column_error": column,
            "id_rows": ordered_invalid_rows,
            "comment": error.get("comment"),
        }
    )
    stmt = stmt.on_conflict_do_update(
        constraint="t_user_errors_un",  # unique (import, error_type, column)
        set_={
            "id_rows": func.array_cat(ImportUserError.rows, stmt.excluded["id_rows"]),
        },
    )
    db.session.execute(stmt)
    return {entity.validity_column}
