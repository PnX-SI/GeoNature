from functools import wraps
from inspect import signature

from sqlalchemy import func
from sqlalchemy.orm.exc import NoResultFound
from sqlalchemy.dialects.postgresql import insert as pg_insert

from geonature.utils.env import db

from geonature.core.imports.models import ImportUserError, ImportUserErrorType, TImports
from geonature.core.imports.utils import generated_fields


def dataframe_check(check_function):
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


def error_replace(old_code, old_columns, new_code, new_column=None):
    """
    For rows which trigger old_code error on all old_columns, these errors are replaced
    by new_code error on new_column.
    Usage example:
        @dataframe_check
        @error_replace(ImportCodeError.MISSING_VALUE, {"WKT","latitude","longitude"}, ImportCodeError.NO_GEOM, "Champs géométriques")
        def check_required_values:
            …
        => MISSING_VALUE on WKT, latitude and longitude are replaced by NO-GEOM on "Champs géométrique"
    If new_code is None, error is deleted
    """

    def _error_replace(check_function):
        @wraps(check_function)
        def __error_replace(*args, **kwargs):
            matching_errors = []
            errors_gen = check_function(*args, **kwargs)
            try:
                while True:
                    error = next(errors_gen)
                    if error["error_code"] != old_code:
                        yield error
                        continue
                    if error["column"] not in old_columns:
                        yield error
                        continue
                    matching_errors.append(error)
            except StopIteration as e:
                if matching_errors:
                    matching_indexes = list(
                        map(lambda e: set(e["invalid_rows"].index), matching_errors)
                    )
                    commons_indexes = set.intersection(*matching_indexes)
                    if commons_indexes and new_code is not None:
                        # Yield replacing error
                        yield {
                            "error_code": new_code,
                            "column": new_column,
                            "invalid_rows": matching_errors[0]["invalid_rows"].loc[
                                list(commons_indexes)
                            ],
                        }
                    for error in matching_errors:
                        indexes = set(error["invalid_rows"].index) - commons_indexes
                        if indexes:
                            # Yield old error but without rows where new error have been yield
                            yield {
                                "error_code": error["error_code"],
                                "column": error["column"],
                                "invalid_rows": error["invalid_rows"].loc[list(indexes)],
                            }
                return e.value

        return __error_replace

    return _error_replace


def report_error(imprt: TImports, entity, df, error):
    """
    Reports an error found in the dataframe, updates the validity column and insert
    the error in the `t_user_errors` table.

    Parameters
    ----------
    imprt : Import
        The import entity.
    entity : Entity
        The entity to check.
    df : pandas.DataFrame
        The dataframe containing the data.
    error : dict
        The error to report. It should have the following keys:
        - invalid_rows : DataFrame
            The rows with errors.
        - error_code : str
            The name of the error code.
        - column : str
            The column with errors.
        - comment : str, optional
            A comment to add to the error.

    Returns
    -------
    set
        set containing the name of the entity validity column.

    Raises
    ------
    Exception
        If the error code is not found.
    """
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
    try:
        ordered_invalid_rows = sorted(invalid_rows["line_no"])
    except:
        ordered_invalid_rows = []
    column = generated_fields.get(error["column"], error["column"])
    column = imprt.fieldmapping.get(column, {}).get("column_src", column)
    # If an error for same import, same column and of the same type already exists,
    # we concat existing erroneous rows with current rows.
    stmt = pg_insert(ImportUserError).values(
        {
            "id_import": imprt.id_import,
            "id_error": error_type.pk,
            "id_entity": entity.id_entity,
            "column_error": column,
            "id_rows": ordered_invalid_rows,
            "comment": error.get("comment"),
        }
    )
    stmt = stmt.on_conflict_do_update(
        index_elements=("id_import", "id_entity", "id_error", "column_error"),
        index_where=ImportUserError.id_entity.isnot(None),
        set_={
            "id_rows": func.array_cat(ImportUserError.rows, stmt.excluded["id_rows"]),
        },
    )
    db.session.execute(stmt)
    return {entity.validity_column}
