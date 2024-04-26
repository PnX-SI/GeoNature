import os
from io import BytesIO, TextIOWrapper
import csv
import json
from enum import IntEnum
from datetime import datetime, timedelta

from flask import current_app, render_template
from sqlalchemy import func, delete
from chardet.universaldetector import UniversalDetector
from sqlalchemy.sql.expression import select, insert
import pandas as pd
import numpy as np
from sqlalchemy.dialects.postgresql import insert as pg_insert
from werkzeug.exceptions import BadRequest
from geonature.utils.env import db
from weasyprint import HTML

from geonature.utils.sentry import start_sentry_child
from geonature.core.imports.models import ImportUserError, BibFields
from geonature.core.gn_commons.models.base import TModules
from geonature.core.gn_synthese.models import TSources

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


def clean_import(imprt, step: ImportStep):
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
        imprt.destination.remove_data_from_destination(imprt)


def get_file_size(f):
    current_position = f.tell()
    f.seek(0, os.SEEK_END)
    size = f.tell()
    f.seek(current_position)
    return size


def detect_encoding(f):
    begin = datetime.now()
    max_duration = timedelta(
        seconds=current_app.config["IMPORT"]["MAX_ENCODING_DETECTION_DURATION"]
    )
    position = f.tell()
    f.seek(0)
    detector = UniversalDetector()
    for row in f:
        detector.feed(row)
        if detector.done or (datetime.now() - begin) > max_duration:
            break
    detector.close()
    f.seek(position)
    return detector.result["encoding"] or "UTF-8"


def detect_separator(f, encoding):
    position = f.tell()
    f.seek(0)
    try:
        sample = f.readline().decode(encoding)
    except UnicodeDecodeError:
        # encoding is likely to be detected encoding, so prompt to errors
        return None
    if sample == "\n":  # files that do not start with column names
        raise BadRequest("File must start with columns")
    dialect = csv.Sniffer().sniff(sample)
    f.seek(position)
    return dialect.delimiter


def get_valid_bbox(imprt, entity, geom_4326_field):
    """Get the valid bounding box for a given import.
    Parameters
    ----------
    imprt : geonature.core.imports.models.TImports
        The import object.
    entity : geonature.core.imports.models.Entity
        The entity object (e.g.: observation, station...).
    geom_4326_field : geonature.core.imports.models.BibFields
        The field containing the geometry of the entity in the transient table.
    Returns
    -------
    dict or None
        The valid bounding box as a JSON object, or None if no valid bounding box.
    Raises
    ------
    NotImplementedError
        If the destination of the import is not implemented yet (e.g.: 'metadata'...)
    """
    # TODO: verify how to assert that an import has data in transient table or not and whether it is related to t_imports.date_end_import or t_imports.loaded fields
    if imprt.loaded == True:
        # Compute from entries in the transient table and related to the import
        transient_table = imprt.destination.get_transient_table()
        stmt = (
            select(func.ST_AsGeojson(func.ST_Extent(transient_table.c[geom_4326_field.dest_field])))
            .where(transient_table.c.id_import == imprt.id_import)
            .where(transient_table.c[entity.validity_column] == True)
        )
    else:
        # Compute from entries in the destination table and related to the import
        id_module_import = db.session.execute(
            select(TModules.id_module).where(TModules.module_code == "IMPORT")
        ).scalar()
        # TODO: build a destination-generic query using geom_4326_field.dest_field or another method to retrieve geom field from entity or destination
        #   Need to handle the filtering by id_import in a generic way, but the logic is different between Synthese (no id_import field, and join needed) and occhab (with id_import field)
        destination_table = entity.get_destination_table()
        stmt = None
        if imprt.destination.code == 'synthese':
            stmt = (
                select(
                    func.ST_AsGeojson(
                        func.ST_Extent(destination_table.c[geom_4326_field.dest_field])
                    )
                )
                .join(TSources)
                .where(TSources.id_module == id_module_import)
                .where(TSources.name_source == f"Import(id={imprt.id_import})")
            )
        elif imprt.destination.code == 'occhab':
            stmt = select(
                func.ST_AsGeojson(func.ST_Extent(destination_table.c[geom_4326_field.dest_field]))
            ).where(destination_table.c["id_import"] == imprt.id_import)
        else:
            raise NotImplementedError(f"function get_valid_bbox not implemented for an import with destination '{imprt.destination.code}'")

    (valid_bbox,) = db.session.execute(stmt).fetchone()


    if valid_bbox:
        return json.loads(valid_bbox)


def preprocess_value(df, field, source_col):
    if field.multi:
        assert type(source_col) is list
        col = df[source_col].apply(build_additional_data, axis=1)
    else:
        col = df[source_col]
    return col


def build_additional_data(columns):
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


def insert_import_data_in_transient_table(imprt):
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

        imprt.destination.preprocess_transient_data(imprt, df)

        records = df.to_dict(orient="records")
        db.session.execute(insert(transient_table).values(records))

    return 1 + chunk.index[-1]  # +1 because chunk.index start at 0


def build_fieldmapping(imprt, columns):
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


def load_transient_data_in_dataframe(imprt, entity, source_cols, offset=None, limit=None):
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


def update_transient_data_from_dataframe(imprt, entity, updated_cols, df):
    if not updated_cols:
        return
    transient_table = imprt.destination.get_transient_table()
    updated_cols = ["id_import", "line_no"] + list(updated_cols)
    df.replace({np.nan: None}, inplace=True)
    records = df[updated_cols].to_dict(orient="records")
    insert_stmt = pg_insert(transient_table)
    insert_stmt = insert_stmt.values(records).on_conflict_do_update(
        index_elements=updated_cols[:2],
        set_={col: insert_stmt.excluded[col] for col in updated_cols[2:]},
    )
    db.session.execute(insert_stmt)


def generate_pdf_from_template(template, data):
    template_rendered = render_template(template, data=data)
    html_file = HTML(
        string=template_rendered,
        base_url=current_app.config["API_ENDPOINT"],
        encoding="utf-8",
    )

    return html_file.write_pdf()
