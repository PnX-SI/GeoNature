from typing import Dict

import numpy as np
import pandas as pd
import sqlalchemy as sa

from geonature.utils.env import db
from geonature.core.gn_meta.models import TDatasets

from geonature.core.imports.models import BibFields

from .utils import dfcheck


__all__ = ["check_required_values", "check_counts", "check_datasets"]


@dfcheck
def check_required_values(df, fields: Dict[str, BibFields]):
    for field_name, field in fields.items():
        if not field.mandatory:
            continue
        if field.source_column not in df:
            continue
            # XXX lever une erreur pour toutes les lignes si le champs n’est pas mappé
            # XXX rise errors for missing mandatory field from mapping?
            yield {
                "error_code": "MISSING_VALUE",
                "column": field_name,
                "invalid_rows": df,
            }
        invalid_rows = df[df[field.source_column].isna()]
        if len(invalid_rows):
            yield {
                "error_code": "MISSING_VALUE",
                "column": field_name,
                "invalid_rows": invalid_rows,
            }


def _check_ordering(df, min_field, max_field):
    ordered = df[min_field] <= df[max_field]
    ordered = ordered.fillna(False)
    invalid_rows = df[~ordered & df[min_field].notna() & df[max_field].notna()]
    yield {
        "invalid_rows": invalid_rows,
    }


@dfcheck
def check_counts(df, count_min_field, count_max_field, default_count=None):
    count_min_col = count_min_field.dest_field
    count_max_col = count_max_field.dest_field
    updated_cols = {count_max_col}
    if count_min_col in df:
        df[count_min_col] = df[count_min_col].where(
            df[count_min_col].notna(),
            other=default_count,
        )
        if count_max_col in df:
            yield from map(
                lambda error: {
                    "column": count_min_col,
                    "error_code": "COUNT_MIN_SUP_COUNT_MAX",
                    **error,
                },
                _check_ordering(df, count_min_col, count_max_col),
            )
            # Complete empty count_max cells
            df[count_max_col] = df[count_max_col].where(
                df[count_max_col].notna(),
                other=df[count_min_col],
            )
        else:
            df[count_max_col] = df[count_min_col]
        updated_cols.add(count_max_col)
    else:
        updated_cols.add(count_min_col)
        if count_max_col in df:
            df[count_max_col] = df[count_max_col].where(
                df[count_max_col].notna(),
                other=default_count,
            )
            df[count_min_col] = df[count_max_col]
        else:
            df[count_min_col] = default_count
            df[count_max_col] = default_count
    return updated_cols


@dfcheck
def check_datasets(imprt, df, uuid_field, id_field, module_code, object_code=None):
    updated_cols = set()
    uuid_col = uuid_field.dest_field
    id_col = id_field.dest_field

    if uuid_col in df:
        has_uuid_mask = df[uuid_col].notnull()
        uuid = df.loc[has_uuid_mask, uuid_col].unique().tolist()

        datasets = {
            ds.unique_dataset_id.hex: ds
            for ds in TDatasets.query.filter(TDatasets.unique_dataset_id.in_(uuid))
            .options(sa.orm.raiseload("*"))
            .all()
        }
        valid_ds_mask = df[uuid_col].isin(datasets.keys())
        invalid_ds_mask = has_uuid_mask & ~valid_ds_mask
        if invalid_ds_mask.any():
            yield {
                "error_code": "DATASET_NOT_FOUND",
                "column": uuid_field.name_field,
                "invalid_rows": df[invalid_ds_mask],
            }

        # Warning: we check only permissions of first author, but currently there it only one author per import.
        authorized_datasets = {
            ds.unique_dataset_id.hex: ds
            for ds in db.session.execute(
                TDatasets.filter_by_creatable(
                    user=imprt.authors[0], module_code=module_code, object_code=object_code
                )
                .where(TDatasets.unique_dataset_id.in_(uuid))
                .options(sa.orm.raiseload("*"))
            )
            .scalars()
            .all()
        }
        authorized_ds_mask = df[uuid_col].isin(authorized_datasets.keys())
        unauthorized_ds_mask = valid_ds_mask & ~authorized_ds_mask
        if unauthorized_ds_mask.any():
            yield {
                "error_code": "DATASET_NOT_AUTHORIZED",
                "column": uuid_field.name_field,
                "invalid_rows": df[unauthorized_ds_mask],
            }

        if authorized_ds_mask.any():
            df.loc[authorized_ds_mask, id_col] = df[authorized_ds_mask][uuid_col].apply(
                lambda uuid: authorized_datasets[uuid].id_dataset
            )
            updated_cols = {id_col}

    else:
        has_uuid_mask = pd.Series(False, index=df.index)

    if (~has_uuid_mask).any():
        # Set id_dataset from import for empty cells:
        df.loc[~has_uuid_mask, id_col] = imprt.id_dataset
        updated_cols = {id_col}

    return updated_cols
