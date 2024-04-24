from typing import Dict, Optional, Set

import numpy as np
import pandas as pd
import sqlalchemy as sa

from geonature.utils.env import db
from geonature.core.gn_meta.models import TDatasets

from geonature.core.imports.models import BibFields, TImports

from .utils import dfcheck


__all__ = ["check_required_values", "check_counts", "check_datasets"]


@dfcheck
def check_required_values(df, fields: Dict[str, BibFields]):
    """
    Check if required values are present in the dataframe.

    Parameters
    ----------
    df : pandas.DataFrame
        The dataframe to check.
    fields : Dict[str, BibFields]
        Dictionary of fields to check.

    Yields
    ------
    dict
        Dictionary containing the error code, the column name and the invalid rows.

    Notes
    -----
    If a field is not mandatory and it has mandatory conditions, it will not raise an error
    if any of the mandatory conditions are mapped.

    If a field is mandatory and it has optional conditions, it will not raise an error
    if any of the optional conditions is mapped.

    If a field is mandatory and it is not mapped, it will raise an error for all the rows.
    """

    for field_name, field in fields.items():
        if not field.mandatory:
            if field.mandatory_conditions:
                are_required_field_mapped = [
                    fields[field_req].source_column in df
                    for field_req in field.mandatory_conditions
                ]
                if not any(are_required_field_mapped):
                    continue
            continue

        if field.mandatory and field.optional_conditions:
            # If a required field is optional thanks to other columns mapped
            are_optional_field_mapped = [
                fields[field_opt].source_column in df for field_opt in field.optional_conditions
            ]
            if any(are_optional_field_mapped):
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
    """
    Check if the values in the `min_field` are lower or equal to the values
    in the `max_field` for all the rows of the dataframe `df`.

    Parameters
    ----------
    df : pandas.DataFrame
        The dataframe to check.
    min_field : str
        The name of the column containing the minimum values.
    max_field : str
        The name of the column containing the maximum values.

    Yields
    ------
    dict
        Dictionary containing the invalid rows.

    """
    ordered = df[min_field] <= df[max_field]
    ordered = ordered.fillna(False)
    invalid_rows = df[~ordered & df[min_field].notna() & df[max_field].notna()]
    yield {
        "invalid_rows": invalid_rows,
    }


@dfcheck
def check_counts(
    df: pd.DataFrame, count_min_field: str, count_max_field: str, default_count: int = None
):
    """
    Check if the value in the `count_min_field` is lower or equal to the value in the `count_max_field`

    | count_min_field | count_max_field |
    | --------------- | --------------- |
    | 0               | 2               | --> ok
    | 2               | 0               | --> provoke an error

    Parameters
    ----------
    df : pandas.DataFrame
        The dataframe to check.
    count_min_field : BibField
        The field containing the minimum count.
    count_max_field : BibField
        The field containing the maximum count.
    default_count : object, optional
        The default count to use if a count is missing, by default None.

    Yields
    ------
    dict
        Dictionary containing the error code, the column name and the invalid rows.

    Returns
    ------
    set
        Set of columns updated.

    """
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
def check_datasets(
    imprt: TImports,
    df: pd.DataFrame,
    uuid_field: BibFields,
    id_field: BibFields,
    module_code: str,
    object_code: Optional[str] = None,
) -> Set[str]:
    """
    Check if datasets exist and are authorized for the user and import.

    Parameters
    ----------
    imprt : TImports
        Import to check datasets for.
    df : pd.DataFrame
        Dataframe to check.
    uuid_field : BibFields
        Field containing dataset UUIDs.
    id_field : BibFields
        Field to fill with dataset IDs.
    module_code : str
        Module code to check datasets for.
    object_code : Optional[str], optional
        Object code to check datasets for, by default None.

    Yields
    ------
    dict
        Dictionary containing error code, column name and invalid rows.

    Returns
    ------
    Set[str]
        Set of columns updated.

    """
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
