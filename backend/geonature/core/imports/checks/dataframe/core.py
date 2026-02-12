from typing import Dict, Optional, Set
from functools import reduce

from geonature.core.imports.checks.errors import ImportCodeError
import numpy as np
import pandas as pd
import sqlalchemy as sa

from geonature.utils.env import db
from geonature.core.gn_meta.models import TDatasets

from geonature.core.imports.models import BibFields, TImports

from .utils import dataframe_check, error_replace
from .cast import is_valid_uuid

__all__ = ["check_required_values", "check_counts", "check_datasets"]


@dataframe_check
@error_replace(
    ImportCodeError.MISSING_VALUE,
    {"WKT", "longitude", "latitude"},
    ImportCodeError.NO_GEOM,
    "Champs géométriques",
)
def check_required_values(df: pd.DataFrame, fields: Dict[str, BibFields]):
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
    Field is mandatory if: ((field.mandatory AND NOT (ANY optional_cond is not NaN)) OR (ANY mandatory_cond is not NaN))
                       <=> ((field.mandatory AND       ALL optional_cond are NaN   ) OR (ANY mandatory_cond is not NaN))
    """

    for field_name, field in fields.items():
        # array of OR conditions
        mandatory_conditions = []

        if field.mandatory:
            cond = pd.Series(True, index=df.index)
            if field.optional_conditions:
                for opt_field_name in field.optional_conditions:
                    opt_field = fields[opt_field_name]
                    if opt_field.source_column not in df:
                        continue
                    cond = cond & df[opt_field.source_column].isna()
            mandatory_conditions.append(cond)

        if field.mandatory_conditions:
            for mand_field_name in field.mandatory_conditions:
                mand_field = fields[mand_field_name]
                if mand_field.source_column not in df:
                    continue
                mandatory_conditions.append(df[mand_field.source_column].notna())

        if mandatory_conditions:
            if field.source_column in df:
                empty_rows = df[field.source_column].isna()
            else:
                empty_rows = pd.Series(True, index=df.index)
            cond = reduce(lambda x, y: x | y, mandatory_conditions)  # OR on all conditions
            invalid_rows = df[empty_rows & cond]
            if len(invalid_rows):
                yield {
                    "error_code": ImportCodeError.MISSING_VALUE,
                    "column": field_name,
                    "invalid_rows": invalid_rows,
                }


def _check_ordering(df: pd.DataFrame, min_field: str, max_field: str):
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


@dataframe_check
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


@dataframe_check
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
    It also fill the id_field based on the content of uuid_field
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
    uuid_col = uuid_field.source_column
    if uuid_col not in df:
        return updated_cols
    uuid = df[uuid_col].unique().tolist()

    # check uuid format
    valid_uuid_mask = df[uuid_col].apply(lambda x: is_valid_uuid(x))
    invalid_uuid_mask = ~valid_uuid_mask
    if invalid_uuid_mask.any():
        yield {
            "error_code": ImportCodeError.INVALID_UUID,
            "column": uuid_field.name_field,
            "invalid_rows": df[invalid_uuid_mask],
        }

    filtered_ds_mask = valid_uuid_mask
    uuid = df[filtered_ds_mask][uuid_col].unique().tolist()

    # check dataset existance
    datasets = {
        str(ds.unique_dataset_id): ds
        for ds in TDatasets.query.filter(TDatasets.unique_dataset_id.in_(uuid))
        .options(sa.orm.joinedload(TDatasets.nomenclature_data_origin))
        .options(sa.orm.raiseload("*"))
        .all()
    }
    valid_ds_mask = df[uuid_col].isin(datasets.keys())
    invalid_ds_mask = ~valid_ds_mask & filtered_ds_mask
    if invalid_ds_mask.any():
        yield {
            "error_code": ImportCodeError.DATASET_NOT_FOUND,
            "column": uuid_field.name_field,
            "invalid_rows": df[invalid_ds_mask],
        }

    filtered_ds_mask = filtered_ds_mask & valid_ds_mask
    uuid = df[filtered_ds_mask][uuid_col].unique().tolist()

    # check dataset active status
    active_ds = [uuid for uuid, ds in datasets.items() if ds.active]
    active_ds_mask = df[uuid_col].isin(active_ds)
    inactive_ds_mask = ~active_ds_mask & filtered_ds_mask

    if inactive_ds_mask.any():
        yield {
            "error_code": ImportCodeError.DATASET_NOT_ACTIVE,
            "column": uuid_field.name_field,
            "invalid_rows": df[inactive_ds_mask],
        }
    filtered_ds_mask = filtered_ds_mask & active_ds_mask
    uuid = df[filtered_ds_mask][uuid_col].unique().tolist()

    # check dataset authorized
    # Warning: we check only permissions of first author, but currently there it only one author per import.
    authorized_datasets = {
        str(ds.unique_dataset_id): ds
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
    authorized_ds_mask = active_ds_mask & df[uuid_col].isin(authorized_datasets.keys())
    unauthorized_ds_mask = ~authorized_ds_mask & filtered_ds_mask
    if unauthorized_ds_mask.any():
        yield {
            "error_code": ImportCodeError.DATASET_NOT_AUTHORIZED,
            "column": uuid_field.name_field,
            "invalid_rows": df[unauthorized_ds_mask],
        }
    filtered_ds_mask = filtered_ds_mask & authorized_ds_mask

    # compute id_col based on uuid_col
    if filtered_ds_mask.any():
        id_col = id_field.dest_field
        df.loc[filtered_ds_mask, id_col] = df[filtered_ds_mask][uuid_col].apply(
            lambda uuid: authorized_datasets[uuid].id_dataset
        )
        updated_cols = {id_col}

    return updated_cols
