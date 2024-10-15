import os
from io import BytesIO, TextIOWrapper
import csv
import json
from enum import IntEnum
from datetime import datetime, timedelta
from typing import IO, Any, Dict, Iterable, List, Optional, Set, Tuple

from flask import current_app, render_template
import sqlalchemy as sa
from sqlalchemy import func, select, delete
from chardet.universaldetector import UniversalDetector
from sqlalchemy.sql.expression import select, insert
import pandas as pd
import numpy as np
from sqlalchemy.dialects.postgresql import insert as pg_insert
from werkzeug.exceptions import BadRequest
from geonature.utils.env import db
from weasyprint import HTML

from geonature.utils.sentry import start_sentry_child
from geonature.core.imports.models import Entity, ImportUserError, BibFields, TImports


class ImportStep(IntEnum):
    UPLOAD = 1
    DECODE = 2
    LOAD = 3
    PREPARE = 4
    IMPORT = 5


generated_fields = {
    "datetime_min": "date_min",
    "datetime_max": "date_max",
}


def clean_import(imprt: TImports, step: ImportStep) -> None:
    """
    Clean an import at a specific step.

    Parameters
    ----------
    imprt : TImports
        The import to clean.
    step : ImportStep
        The step at which to clean the import.

    """
    imprt.task_id = None
    if step <= ImportStep.UPLOAD:
        # source_file will be necessary overwritten
        # source_count will be necessary overwritten
        pass
    if step <= ImportStep.DECODE:
        imprt.columns = None
    if step <= ImportStep.LOAD:
        transient_table = imprt.destination.get_transient_table()
        stmt = delete(transient_table).where(transient_table.c.id_import == imprt.id_import)
        with start_sentry_child(op="task", description="clean transient data"):
            db.session.execute(stmt)
        imprt.source_count = None
        imprt.loaded = False
    if step <= ImportStep.PREPARE:
        with start_sentry_child(op="task", description="clean errors"):
            ImportUserError.query.filter(ImportUserError.imprt == imprt).delete()
        imprt.erroneous_rows = None
        imprt.processed = False
    if step <= ImportStep.IMPORT:
        imprt.date_end_import = None
        imprt.import_count = None
        imprt.statistics = {}
        imprt.destination.actions.remove_data_from_destination(imprt)


def get_file_size(file_: IO) -> int:
    """
    Get the size of a file in bytes.

    Parameters
    ----------
    file_ : IO
        The file to get the size of.

    Returns
    -------
    int
        The size of the file in bytes.

    """
    current_position = file_.tell()
    file_.seek(0, os.SEEK_END)
    size = file_.tell()
    file_.seek(current_position)
    return size


def detect_encoding(file_: IO) -> str:
    """
    Detects the encoding of a file.

    Parameters
    ----------
    file_ : IO
        The file to detect the encoding of.

    Returns
    -------
    str
        The detected encoding. If no encoding is detected, then "UTF-8" is returned.

    """
    begin = datetime.now()
    max_duration = timedelta(
        seconds=current_app.config["IMPORT"]["MAX_ENCODING_DETECTION_DURATION"]
    )
    position = file_.tell()
    file_.seek(0)
    detector = UniversalDetector()
    for row in file_:
        detector.feed(row)
        if detector.done or (datetime.now() - begin) > max_duration:
            break
    detector.close()
    file_.seek(position)
    return detector.result["encoding"] or "UTF-8"


def detect_separator(file_: IO, encoding: str) -> Optional[str]:
    """
    Detects the delimiter used in a CSV file.

    Parameters
    ----------
    file_ : IO
        The file object to detect the delimiter of.
    encoding : str
        The encoding of the file.

    Returns
    -------
    Optional[str]
        The delimiter used in the file, or None if no delimiter is detected.

    Raises
    ------
    BadRequest
        If the file starts with no column names.

    """
    position = file_.tell()
    file_.seek(0)
    try:
        sample = file_.readline().decode(encoding)
    except UnicodeDecodeError:
        # encoding is likely to be detected encoding, so prompt to errors
        return None
    if sample == "\n":  # files that do not start with column names
        raise BadRequest("File must start with columns")
    dialect = csv.Sniffer().sniff(sample)
    file_.seek(position)
    return dialect.delimiter


def preprocess_value(dataframe: pd.DataFrame, field: BibFields, source_col: str) -> pd.Series:
    """
    Preprocesses values in a DataFrame depending if the field contains multiple values (e.g. additional_data) or not.

    Parameters
    ----------
    dataframe : pd.DataFrame
        The DataFrame to preprocess the value of.
    field : BibFields
        The field to preprocess.
    source_col : str
        The column to preprocess.

    Returns
    -------
    pd.Series
        The preprocessed value.

    """

    def build_additional_data(columns: dict):
        result = {}
        for key, value in columns.items():
            if value is None:
                continue
            try:
                value = json.loads(value)
                assert type(value) is dict
            except Exception:
                value = {key: value}
            result.update(value)
        return result

    if field.multi:
        assert type(source_col) is list
        col = dataframe[source_col].apply(build_additional_data, axis=1)
    else:
        col = dataframe[source_col]
    return col


def insert_import_data_in_transient_table(imprt: TImports) -> int:
    """
    Insert the data from the import file into the transient table.

    Parameters
    ----------
    imprt : TImports
        current import

    Returns
    -------
    int
        The last line number of the import file that was inserted.
    """
    transient_table = imprt.destination.get_transient_table()

    columns = imprt.columns
    fieldmapping, used_columns = build_fieldmapping(imprt, columns)
    extra_columns = set(columns) - set(used_columns)

    csvfile = TextIOWrapper(BytesIO(imprt.source_file), encoding=imprt.encoding)
    reader = pd.read_csv(
        csvfile,
        delimiter=imprt.separator,
        header=0,
        names=imprt.columns,
        index_col=False,
        dtype="str",
        na_filter=False,
        iterator=True,
        chunksize=10000,
    )
    for chunk in reader:
        chunk.replace({"": None}, inplace=True)
        data = {
            "id_import": np.full(len(chunk), imprt.id_import),
            "line_no": 1 + 1 + chunk.index,  # header + start line_no at 1 instead of 0
        }
        data.update(
            {
                dest_field: preprocess_value(chunk, source_field["field"], source_field["value"])
                for dest_field, source_field in fieldmapping.items()
            }
        )
        # XXX keep extra_fields in t_imports_synthese? or add config argument?
        if extra_columns and "extra_fields" in transient_table.c:
            data.update(
                {
                    "extra_fields": chunk[list(extra_columns)].apply(
                        lambda cols: {k: v for k, v in cols.items()}, axis=1
                    ),
                }
            )
        df = pd.DataFrame(data)

        imprt.destination.actions.preprocess_transient_data(imprt, df)

        records = df.to_dict(orient="records")
        db.session.execute(insert(transient_table).values(records))

    return 1 + chunk.index[-1]  # +1 because chunk.index start at 0


def build_fieldmapping(
    imprt: TImports, columns: Iterable[Any]
) -> Tuple[Dict[str, Dict[str, Any]], List[str]]:
    """
    Build a dictionary that maps the source column names to the corresponding field and values.

    Parameters
    ----------
    imprt : TImports
        The import to check.
    columns : Iterable[Any]
        The columns to map.

    Returns
    -------
    tuple
        A tuple containing a dictionary that maps the source column names to the corresponding field and values,
        and a list of the used columns.

    """
    fields = BibFields.query.filter_by(destination=imprt.destination, autogenerated=False).all()
    fieldmapping = {}
    used_columns = []

    for field in fields:
        if field.name_field in imprt.fieldmapping:
            if field.multi:
                correct = list(set(columns) & set(imprt.fieldmapping[field.name_field]))
                if len(correct) > 0:
                    fieldmapping[field.source_column] = {
                        "value": correct,
                        "field": field,
                    }
                    used_columns.extend(correct)
            else:
                if imprt.fieldmapping[field.name_field] in columns:
                    fieldmapping[field.source_column] = {
                        "value": imprt.fieldmapping[field.name_field],
                        "field": field,
                    }
                    used_columns.append(imprt.fieldmapping[field.name_field])
    return fieldmapping, used_columns


def load_transient_data_in_dataframe(
    imprt: TImports, entity: Entity, source_cols: list, offset: int = None, limit: int = None
):
    """
    Load data from the transient table into a pandas dataframe.

    Parameters
    ----------
    imprt : TImports
        The import to load.
    entity : Entity
        The entity to load.
    source_cols : list
        The columns to load from the transient table.
    offset : int, optional
        The number of rows to skip.
    limit : int, optional
        The maximum number of rows to load.

    Returns
    -------
    pandas.DataFrame
        The dataframe containing the loaded data.
    """
    transient_table = imprt.destination.get_transient_table()
    source_cols = ["id_import", "line_no", entity.validity_column] + source_cols
    stmt = (
        select([transient_table.c[col] for col in source_cols])
        .where(transient_table.c.id_import == imprt.id_import)
        .where(transient_table.c[entity.validity_column].isnot(None))
        .order_by(transient_table.c.line_no)
    )
    if offset is not None:
        stmt = stmt.offset(offset)
    if limit is not None:
        stmt = stmt.limit(limit)
    records = db.session.execute(stmt).fetchall()
    df = pd.DataFrame.from_records(
        records,
        columns=source_cols,
    ).astype("object")
    return df


def update_transient_data_from_dataframe(
    imprt: TImports, entity: Entity, updated_cols: Set[str], dataframe: pd.DataFrame
):
    """
    Update the transient table with the data from the dataframe.

    Parameters
    ----------
    imprt : TImports
        The import to update.
    entity : Entity
        The entity to update.
    updated_cols : list
        The columns to update.
    df : pandas.DataFrame
        The dataframe to use for the update.

    Notes
    -----
    The dataframe must have the columns 'id_import' and 'line_no'.
    """
    if not updated_cols:
        return
    transient_table = imprt.destination.get_transient_table()
    updated_cols = ["id_import", "line_no"] + list(updated_cols)
    dataframe.replace({np.nan: None}, inplace=True)
    records = dataframe[updated_cols].to_dict(orient="records")
    insert_stmt = pg_insert(transient_table)
    insert_stmt = insert_stmt.values(records).on_conflict_do_update(
        index_elements=updated_cols[:2],
        set_={col: insert_stmt.excluded[col] for col in updated_cols[2:]},
    )
    db.session.execute(insert_stmt)


def generate_pdf_from_template(template: str, data: Any) -> bytes:
    """
    Generate a PDF document from a template.

    Parameters
    ----------
    template : str
        The name of the template file to use.
    data : Any
        The data to pass to the template.

    Returns
    -------
    bytes
        The PDF document as bytes.
    """
    template_rendered = render_template(template, data=data)
    html_file = HTML(
        string=template_rendered,
        base_url=current_app.config["API_ENDPOINT"],
        encoding="utf-8",
    )
    return html_file.write_pdf()


def get_mapping_data(import_: TImports, entity: Entity):
    """
    Get the mapping data for a given import and entity.

    Parameters
    ----------
    import_ : TImports
        The import to get the mapping data for.
    entity : Entity
        The entity to get the mapping data for.

    Returns
    -------
    fields : dict
        A dictionary with the all fields associated with an entity (check gn_imports.bib_fields). This dictionary is keyed by the name field and valued by the corresponding BibField object.
    selected_fields : dict
        In the same format as fields, but only the fields contained in the mapping.
    source_cols : list
        List of fields to load in dataframe, mainly source column of non-nomenclature fields
    """
    fields = {ef.field.name_field: ef.field for ef in entity.fields}
    selected_fields = {
        field_name: fields[field_name]
        for field_name, source_field in import_.fieldmapping.items()
        if source_field in import_.columns and field_name in fields
    }
    source_cols = set()
    for field in selected_fields.values():
        # load source col of all non-nomenclature fields
        if field.mnemonique is None and field.source_field is not None:
            source_cols |= {field.source_field}
        # load source col of all mandatory fields
        if field.mandatory:
            source_cols |= {field.source_field}
        # load all selected field used in conditions
        conditions = set(field.mandatory_conditions or {}) | set(field.optional_conditions or {})
        if conditions:
            source_cols |= set(
                [selected_fields[f].source_field for f in conditions if f in selected_fields]
            )
    return fields, selected_fields, list(source_cols)


def get_required(import_: TImports, entity: Entity):
    fields, selected_fields, _ = get_mapping_data(import_, entity)
    required_columns = set([])
    for field, bib_field in fields.items():
        if bib_field.mandatory and field in selected_fields:
            required_columns.add(field)

    for field, bib_field in selected_fields.items():
        if all([field_name in selected_fields for field_name in bib_field.required_conditions]):
            required_columns.add(field)

    for field, bib_field in selected_fields.items():
        if all([field_name in selected_fields for field_name in bib_field.optional_conditions]):
            required_columns.remove(field)
    return required_columns


def compute_bounding_box(
    imprt: TImports,
    entity_code,
    geom_4326_field,
    *,
    transient_where_clause=None,
    destination_where_clause=None
):
    entity = Entity.query.filter_by(destination=imprt.destination, code=entity_code).one()
    if imprt.date_end_import:  # import finished, retrieve data from destination table
        destination_table = entity.get_destination_table()
        geom_field = destination_table.c[geom_4326_field]
        if (
            destination_where_clause is None
        ):  # assume there is an id_import column in the destination table
            where_clause = destination_table.c.id_import == imprt.id_import
        elif callable(destination_where_clause):
            where_clause = destination_where_clause(imprt, destination_table)
        else:
            where_clause = destination_where_clause
    elif imprt.processed:  # import controlled but not finished, retieve data from transient table
        transient_table = imprt.destination.get_transient_table()
        geom_field = transient_table.c[geom_4326_field]
        if transient_where_clause is None:
            where_clause = sa.and_(
                transient_table.c.id_import == imprt.id_import,
                transient_table.c[entity.validity_column] == True,
            )
        elif callable(transient_where_clause):
            where_clause = transient_where_clause(imprt, transient_table)
        else:
            where_clause = transient_where_clause
    else:  # import still in progress, checks have not been runned yet, no valid data available
        return None

    statement = select(func.ST_AsGeojson(func.ST_Extent(geom_field))).where(where_clause)

    # Execute the statement to eventually retrieve the valid bounding box
    (valid_bbox,) = db.session.execute(statement).fetchone()

    # Return the valid bounding box or None
    if valid_bbox:
        return json.loads(valid_bbox)
