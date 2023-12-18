from typing import Dict
import re
from uuid import UUID
from itertools import product
from datetime import datetime

import pandas as pd
from sqlalchemy.sql import sqltypes
from sqlalchemy.dialects.postgresql import UUID as UUIDType

from geonature.core.imports.models import BibFields
from .utils import dfcheck


def convert_to_datetime(value):
    value = value.strip()
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
            return datetime.strptime(value, fmt)
        except ValueError:
            continue
    return None


def convert_to_uuid(value, version=4):
    try:
        return UUID(str(value), version=version).hex
    except Exception:
        return None


def convert_to_integer(value):
    try:
        return int(value)
    except Exception:
        return None


def check_datetime_field(df, source_field, target_field, required):
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
            error_code="INVALID_DATE",
            invalid_rows=invalid_rows,
            comment="Les dates suivantes ne sont pas au bon format: {}".format(
                ", ".join(map(lambda x: str(x), values_error))
            ),
        )
    return {target_field}


def check_uuid_field(df, source_field, target_field, required):
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
            error_code="INVALID_UUID",
            invalid_rows=invalid_rows,
            comment="Les UUID suivantes ne sont pas au bon format: {}".format(
                ", ".join(map(lambda x: str(x), values_error))
            ),
        )
    return {target_field}


def check_integer_field(df, source_field, target_field, required):
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
            error_code="INVALID_INTEGER",
            invalid_rows=invalid_rows,
            comment="Les valeurs suivantes ne sont pas des nombres : {}".format(
                ", ".join(map(lambda x: str(x), values_error))
            ),
        )
    return {target_field}


def check_unicode_field(df, field, field_length):
    if field_length is None:
        return
    length = df[field].apply(lambda x: len(x) if pd.notnull(x) else x)
    invalid_rows = df[length > field_length]
    if len(invalid_rows) > 0:
        yield dict(
            error_code="INVALID_CHAR_LENGTH",
            invalid_rows=invalid_rows,
        )


def check_anytype_field(df, field_type, source_col, dest_col, required):
    updated_cols = set()
    if isinstance(field_type, sqltypes.DateTime):
        updated_cols |= yield from check_datetime_field(df, source_col, dest_col, required)
    elif isinstance(field_type, sqltypes.Integer):
        updated_cols |= yield from check_integer_field(df, source_col, dest_col, required)
    elif isinstance(field_type, UUIDType):
        updated_cols |= yield from check_uuid_field(df, source_col, dest_col, required)
    elif isinstance(field_type, sqltypes.String):
        yield from check_unicode_field(df, dest_col, field_length=field_type.length)
    else:
        raise Exception(
            "Unknown type {} for field {}".format(type(field_type), dest_col)
        )  # pragma: no cover
    return updated_cols


@dfcheck
def check_types(entity, df, fields: Dict[str, BibFields]):
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
        else:  # we may requires to convert some columns unused in final destination
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
