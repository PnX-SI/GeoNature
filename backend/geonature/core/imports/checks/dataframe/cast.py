from typing import Any, Dict, Iterator, Optional, Set
import re
from uuid import UUID
from itertools import product
from datetime import datetime

from geonature.core.imports.checks.errors import ImportCodeError
import numpy as np
import pandas as pd
from sqlalchemy.sql import sqltypes
from sqlalchemy.dialects.postgresql import UUID as UUIDType

from geonature.core.imports.models import BibFields, Entity
from .utils import dataframe_check


def convert_to_datetime(value_raw):
    """
    Try to convert a date string to a datetime object.
    If the input string does not match any of compatible formats, it will return
    None.

    Parameters
    ----------
    value_raw : str
        The input string to convert

    Returns
    -------
    converted_date : datetime or None
        The converted datetime object or None if the conversion failed
    """
    converted_date: datetime = None

    value = value_raw.strip()
    value = re.sub("[ ]+", " ", value)
    value = re.sub("[/.:]", "-", value)
    date_formats = [
        "%Y-%m-%d",
        "%d-%m-%Y",
    ]
    time_formats = [
        None,
        "%H",
        "%H-%M",
        "%H-%M-%S",
        "%H-%M-%S-%f",
        "%Hh",
        "%Hh%M",
        "%Hh%Mm",
        "%Hh%Mm%Ss",
    ]
    for date_format, time_format in product(date_formats, time_formats):
        fmt = (date_format + " " + time_format) if time_format else date_format
        try:
            converted_date = datetime.strptime(value, fmt)
            break  # If successful conversion, will stop the loop
        except ValueError:
            continue

    if not converted_date:
        try:
            converted_date = datetime.fromisoformat(value_raw)
        except:
            pass

    return converted_date


def convert_to_uuid(value):
    try:
        UUID(str(value))
        return str(value)
    except ValueError:
        return None


def is_valid_uuid(value):
    try:
        uuid_obj = UUID(value)
    except Exception as e:
        return False
    return str(uuid_obj) == value


def convert_to_integer(value):
    try:
        return int(value)
    except ValueError:
        return None


def check_datetime_field(
    df: pd.DataFrame, source_field: str, target_field: str, required: bool
) -> Set[str]:
    """
    Check if a column is a datetime and convert it to datetime type.

    Parameters
    ----------
    df : pandas.DataFrame
        The dataframe to check.
    source_field : str
        The name of the column to check.
    target_field : str
        The name of the column where to store the result.
    required : bool
        Whether the column is mandatory or not.

    Yields
    ------
    dict
        A dictionary containing an error code, the column name, and the invalid rows.

    Returns
    -------
    set
        Set containing the name of the target field.

    Notes
    -----
    The error codes are:
        - INVALID_DATE: the value is not of datetime type.
    """
    datetime_col = df[source_field].apply(lambda x: convert_to_datetime(x) if pd.notnull(x) else x)
    if required:
        invalid_rows = df[datetime_col.isna()]
    else:
        # invalid rows are NaN rows which were not already set to NaN
        invalid_rows = df[datetime_col.isna() & df[source_field].notna()]
    df[target_field] = datetime_col
    values_error = invalid_rows[source_field]
    if len(invalid_rows) > 0:
        yield dict(
            error_code=ImportCodeError.INVALID_DATE,
            invalid_rows=invalid_rows,
            comment="Les dates suivantes ne sont pas au bon format: {}".format(
                ", ".join(map(lambda x: str(x), values_error))
            ),
        )
    return {target_field}


def check_uuid_field(
    df: pd.DataFrame, source_field: str, target_field: str, required: bool
) -> Set[str]:
    """
    Check if a column is a UUID and convert it to UUID type.

    Parameters
    ----------
    df : pandas.DataFrame
        The dataframe to check.
    source_field : str
        The name of the column to check.
    target_field : str
        The name of the column where to store the result.
    required : bool
        Whether the column is mandatory or not.

    Yields
    ------
    dict
        A dictionary containing an error code, the column name, and the invalid rows.

    Returns
    -------
    set
        Set containing the name of the target field.

    Notes
    -----
    The error codes are:
        - INVALID_UUID: the value is not a valid UUID.
    """
    uuid_col = df[source_field].apply(lambda x: convert_to_uuid(x) if pd.notnull(x) else x)
    if required:
        invalid_rows = df[uuid_col.isna()]
    else:
        # invalid rows are NaN rows which were not already set to NaN
        invalid_rows = df[uuid_col.isna() & df[source_field].notna()]
    df[target_field] = uuid_col
    values_error = invalid_rows[source_field]
    if len(invalid_rows) > 0:
        yield dict(
            error_code=ImportCodeError.INVALID_UUID,
            invalid_rows=invalid_rows,
            comment="Les UUID suivantes ne sont pas au bon format: {}".format(
                ", ".join(map(lambda x: str(x), values_error))
            ),
        )
    return {target_field}


def check_integer_field(
    df: pd.DataFrame, source_field: str, target_field: str, required: bool
) -> Set[str]:
    """
    Check if a column is an integer and convert it to integer type.

    Parameters
    ----------
    df : pandas.DataFrame
        The dataframe to check.
    source_field : str
        The name of the column to check.
    target_field : str
        The name of the column where to store the result.
    required : bool
        Whether the column is mandatory or not.

    Yields
    ------
    dict
        A dictionary containing an error code, the column name, and the invalid rows.

    Returns
    -------
    set
        Set containing the name of the target field.

    Notes
    -----
    The error codes are:
        - INVALID_INTEGER: the value is not of integer type.
    """
    integer_col = df[source_field].apply(lambda x: convert_to_integer(x) if pd.notnull(x) else x)
    if required:
        invalid_rows = df[integer_col.isna()]
    else:
        # invalid rows are NaN rows which were not already set to NaN
        invalid_rows = df[integer_col.isna() & df[source_field].notna()]
    df[target_field] = integer_col
    values_error = invalid_rows[source_field]
    if len(invalid_rows) > 0:
        yield dict(
            error_code=ImportCodeError.INVALID_INTEGER,
            invalid_rows=invalid_rows,
            comment="Les valeurs suivantes ne sont pas des entiers : {}".format(
                ", ".join(map(lambda x: str(x), values_error))
            ),
        )
    return {target_field}


def check_numeric_field(
    df: pd.DataFrame, source_field: str, target_field: str, required: bool
) -> Set[str]:
    """
    Check if column string values are numerics and convert it to numeric type.

    Parameters
    ----------
    df : pandas.DataFrame
        The dataframe to check.
    source_field : str
        The name of the column to check.
    target_field : str
        The name of the column where to store the result.
    required : bool
        Whether the column is mandatory or not.

    Yields
    ------
    dict
        A dictionary containing an error code, the column name, and the invalid rows.

    Returns
    -------
    set
        Set containing the name of the target field.

    Notes
    -----
    The error codes are:
        - INVALID_NUMERIC: the value is not of numeric type.
    """

    def to_numeric(x):
        try:
            return float(x)
        except:
            return None

    numeric_col = df[source_field].apply(lambda x: to_numeric(x) if pd.notnull(x) else x)
    if required:
        invalid_rows = df[numeric_col.isna()]
    else:
        # invalid rows are NaN rows which were not already set to NaN
        invalid_rows = df[numeric_col.isna() & df[source_field].notna()]
    df[target_field] = numeric_col
    values_error = invalid_rows[source_field]
    if len(invalid_rows) > 0:
        yield dict(
            error_code=ImportCodeError.INVALID_NUMERIC,
            invalid_rows=invalid_rows,
            comment="Les valeurs suivantes ne sont pas des nombres : {}".format(
                ", ".join(map(lambda x: str(x), values_error))
            ),
        )
    return {target_field}


def check_array_int_field(
    df: pd.DataFrame, source_field: str, target_field: str, required: bool
) -> Set[str]:
    """
    Check if column values are arrays (list/tuple) of integers.

    Parameters
    ----------
    df : pandas.DataFrame
        The dataframe to check.
    source_field : str
        The name of the column to check.
    target_field : str
        The name of the column where to store the result.
    required : bool
        Whether the column is mandatory or not.

    Yields
    ------
    dict
        A dictionary containing an error code, the column name, and the invalid rows.

    Returns
    -------
    set
        Set containing the name of the target field.

    Notes
    -----
    The error codes are:
        - INVALID_ARRAY: the value is not an array of integers.
    """

    def to_int_array(x):
        # Si x est un ndarray, on le convertit en liste
        if isinstance(x, np.ndarray):
            x = x.tolist()

        # Si c'est une valeur manquante (scalar NaN/None), on la renvoie telle quelle
        if not isinstance(x, (list, tuple)) and pd.isna(x):
            return x

        # Si c'est une liste ou tuple, on vérifie que tous les éléments sont des int
        if isinstance(x, (list, tuple)) and all(isinstance(elem, int) for elem in x):
            return list(x)

        # Sinon conversion impossible → None
        return None

    # Application sur la colonne sans condition externe
    array_col = df[source_field].apply(to_int_array)

    # Définition des lignes invalides
    if required:
        # Si le champ est obligatoire, toutes les valeurs non converties (None ou NaN) sont considérées comme invalides
        invalid_rows = df[array_col.isna()]
    else:
        # Sinon, seules les valeurs non nulles mais non converties sont considérées comme invalides
        invalid_rows = df[array_col.isna() & df[source_field].notna()]

    # Stockage du résultat dans la colonne cible
    df[target_field] = array_col
    print("array_col", array_col)

    # Préparation du message d'erreur en listant les valeurs problématiques
    values_error = invalid_rows[source_field]
    if len(invalid_rows) > 0:
        yield dict(
            error_code=ImportCodeError.UNKNOWN_ERROR,
            invalid_rows=invalid_rows,
            comment="Les valeurs suivantes ne sont pas des tableaux d'entiers : {}".format(
                ", ".join(map(lambda x: str(x), values_error))
            ),
        )

    return {target_field}


def check_unicode_field(
    df: pd.DataFrame, source_col: str, dest_col: str, field_length: Optional[int]
) -> Iterator[Dict[str, Any]]:
    """
    Check if column values have the right length.

    Parameters
    ----------
    df : pandas.DataFrame
        The dataframe to check.
    field : str
        The name of the column to check.
    field_length : Optional[int]
        The maximum length of the column.

    Yields
    ------
    dict
        A dictionary containing an error code, the column name, and the invalid rows.
    Notes
    -----
    The error codes are:
        - INVALID_CHAR_LENGTH: the string is too long.
    """
    df[dest_col] = df[source_col]
    if field_length is None:
        return {dest_col}
    length = df[source_col].apply(lambda x: len(x) if pd.notnull(x) else x)
    invalid_rows = df[length > field_length]
    if len(invalid_rows) > 0:
        yield dict(
            error_code=ImportCodeError.INVALID_CHAR_LENGTH,
            invalid_rows=invalid_rows,
        )
    return {dest_col}


def check_boolean_field(df, source_col, dest_col, required):
    """
    Check a boolean field in a dataframe.

    Parameters
    ----------
    df : pandas.DataFrame
        The dataframe to check.
    source_col : str
        The name of the column to check.
    dest_col : str
        The name of the column where to store the result.
    required : bool
        Whether the column is mandatory or not.

    Yields
    ------
    dict
        A dictionary containing an error code and the rows with errors.

    Notes
    -----
    The error codes are:
        - MISSING_VALUE: the value is mandatory but it's missing (null).
        - INVALID_BOOL: the value is not a boolean.

    """
    df[dest_col] = df[source_col].apply(int).apply(bool)

    if required:  # FIXME: to remove as done in check_required_value
        invalid_mask = df[dest_col].apply(lambda x: type(x) != bool and pd.isnull(x))
        yield dict(error_code=ImportCodeError.MISSING_VALUE, invalid_rows=df[invalid_mask])
    else:
        invalid_mask = df[dest_col].apply(lambda x: type(x) != bool and (not pd.isnull(x)))
        if invalid_mask.sum() > 0:
            yield dict(error_code=ImportCodeError.INVALID_BOOL, invalid_rows=df[invalid_mask])
    return {dest_col}


def check_anytype_field(
    df: pd.DataFrame,
    field_type: sqltypes.TypeEngine,
    source_col: str,
    dest_col: str,
    required: bool,
) -> Set[str]:
    """
    Check a field in a dataframe according to its type.

    Parameters
    ----------
    df : pandas.DataFrame
        The dataframe to check.
    field_type : sqlalchemy.TypeEngine
        The type of the column to check.
    source_col : str
        The name of the column to check.
    dest_col : str
        The name of the column where to store the result.
    required : bool
        Whether the column is mandatory or not.

    Yields
    ------
    dict
        A dictionary containing an error code and the rows with errors.

    Returns
    -------
    set
        Set containing the name of columns updated in the dataframe.
    """
    updated_cols = set()
    if isinstance(field_type, sqltypes.DateTime):
        updated_cols |= yield from check_datetime_field(df, source_col, dest_col, required)
    if isinstance(field_type, sqltypes.Date):
        updated_cols |= yield from check_datetime_field(df, source_col, dest_col, required)
    elif isinstance(field_type, sqltypes.Integer):
        updated_cols |= yield from check_integer_field(df, source_col, dest_col, required)
    elif isinstance(field_type, UUIDType):
        updated_cols |= yield from check_uuid_field(df, source_col, dest_col, required)
    elif isinstance(field_type, sqltypes.String):
        updated_cols |= yield from check_unicode_field(
            df, source_col, dest_col, field_length=field_type.length
        )
    elif isinstance(field_type, sqltypes.Boolean):
        updated_cols |= yield from check_boolean_field(df, source_col, dest_col, required)
    elif isinstance(field_type, sqltypes.Numeric):
        updated_cols |= yield from check_numeric_field(df, source_col, dest_col, required)
    elif isinstance(field_type, sqltypes.ARRAY) and isinstance(
        field_type.item_type, sqltypes.Integer
    ):
        updated_cols |= yield from check_array_int_field(df, source_col, dest_col, required)
    else:
        raise Exception(
            "Unknown type {} for field {}".format(type(field_type), dest_col)
        )  # pragma: no cover
    return updated_cols


@dataframe_check
def check_types(entity: Entity, df: pd.DataFrame, fields: Dict[str, BibFields]) -> Set[str]:
    """
    Check the types of columns in a dataframe based on the provided fields.

    Parameters
    ----------
    entity : Entity
        The entity to check.
    df : pd.DataFrame
        The dataframe to check.
    fields : Dict[str, BibFields]
        A dictionary mapping column names to their corresponding BibFields.

    Returns
    -------
    Set[str]
        Set containing the names of updated columns.
    """
    updated_cols = set()
    destination_table = entity.get_destination_table()
    transient_table = entity.destination.get_transient_table()
    for name, field in fields.items():
        if not field.dest_field:
            continue
        if field.source_column not in df:
            continue
        if field.mnemonique:  # set from content mapping
            continue
        assert entity in [ef.entity for ef in field.entities]  # FIXME
        if field.dest_field in destination_table.c:
            field_type = destination_table.c[field.dest_field].type
        else:  # we may require to convert some columns unused in final destination
            field_type = transient_table.c[field.dest_field].type
        updated_cols |= yield from map(
            lambda error: {"column": name, **error},
            check_anytype_field(
                df,
                field_type=field_type,
                source_col=field.source_column,
                dest_col=field.dest_field,
                required=False,
            ),
        )
    return updated_cols
