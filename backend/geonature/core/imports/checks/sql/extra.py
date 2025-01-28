from datetime import date
from typing import Any, Optional

from flask import current_app
from geonature.core.imports.checks.errors import ImportCodeError
from geonature.core.imports.models import BibFields, Entity, TImports
from sqlalchemy import func
from sqlalchemy.sql.expression import select, update, join
from sqlalchemy.sql import column
from sqlalchemy.orm import aliased
import sqlalchemy as sa

from geonature.utils.env import db

from geonature.core.imports.checks.sql.utils import (
    get_duplicates_query,
    report_erroneous_rows,
)

from apptax.taxonomie.models import Taxref, cor_nom_liste
from pypn_habref_api.models import Habref


def check_referential(
    imprt: TImports,
    entity: Entity,
    field: BibFields,
    reference_field: sa.Column,
    error_type: str,
    reference_table: Optional[sa.Table] = None,
) -> None:
    """
    Check the referential integrity of a column in the transient table.

    Parameters
    ----------
    imprt : TImports
        The import to check.
    entity : Entity
        The entity to check.
    field : BibFields
        The field to check.
    reference_field : BibFields
        The reference field to check.
    error_type : str
        The type of error encountered.
    reference_table : Optional[sa.Table], optional
        The reference table to check. If not provided, it will be inferred from the reference_field.
    """
    transient_table = imprt.destination.get_transient_table()
    dest_field = transient_table.c[field.dest_field]
    if reference_table is None:
        reference_table = reference_field.class_
    # We outerjoin the referential, and select rows where there is a value in synthese field
    # but no value in referential, which means no value in the referential matched synthese field.
    cte = (
        select(transient_table.c.line_no)
        .select_from(
            join(
                transient_table,
                reference_table,
                dest_field == reference_field,
                isouter=True,
            )
        )
        .where(transient_table.c.id_import == imprt.id_import)
        .where(dest_field != None)
        .where(reference_field == None)
        .cte("invalid_ref")
    )
    report_erroneous_rows(
        imprt,
        entity,
        error_type=error_type,
        error_column=field.name_field,
        whereclause=transient_table.c.line_no == cte.c.line_no,
    )


def check_cd_nom(
    imprt: TImports, entity: Entity, field: BibFields, list_id: Optional[int] = None
) -> None:
    """
    Check the existence of a cd_nom in the Taxref referential.

    Parameters
    ----------
    imprt : TImports
        The import to check.
    entity : Entity
        The entity to check.
    field : BibFields
        The field to check.
    list_id : Optional[int], optional
        The list to filter on, by default None.

    """
    # Filter out on a taxhub list if provided
    if list_id is not None:
        reference_table = join(
            Taxref,
            cor_nom_liste,
            sa.and_(cor_nom_liste.c.id_liste == list_id, cor_nom_liste.c.cd_nom == Taxref.cd_nom),
        )
    else:
        reference_table = Taxref
    check_referential(
        imprt,
        entity,
        field,
        Taxref.cd_nom,
        ImportCodeError.CD_NOM_NOT_FOUND,
        reference_table=reference_table,
    )


def check_cd_hab(imprt: TImports, entity: Entity, field: BibFields) -> None:
    """
    Check the existence of a cd_hab in the Habref referential.

    Parameters
    ----------
    imprt : TImports
        The import to check.
    entity : Entity
        The entity to check.
    field : BibFields
        The field to check.

    """
    check_referential(imprt, entity, field, Habref.cd_hab, ImportCodeError.CD_HAB_NOT_FOUND)


def generate_altitudes(
    imprt: TImports,
    geom_local_field: BibFields,
    alt_min_field: BibFields,
    alt_max_field: BibFields,
) -> None:
    """
    Generate the altitudes based on geomatries, and given altitues in an import.

    Parameters
    ----------
    imprt : TImports
        The import to generate altitudes for.
    geom_local_field : BibFields
        The field representing the geometry in the destination import's transient table.
    alt_min_field : BibFields
        The field representing the minimum altitude in the destination import's transient table.
    alt_max_field : BibFields
        The field representing the maximum altitude in the destination import's transient table.

    """
    transient_table = imprt.destination.get_transient_table()
    geom_col = geom_local_field.dest_field
    altitudes = (
        select(
            column("altitude_min"),
            column("altitude_max"),
        )
        .select_from(func.ref_geo.fct_get_altitude_intersection(transient_table.c[geom_col]))
        .lateral("altitudes")
    )
    cte = (
        select(
            transient_table.c.id_import,
            transient_table.c.line_no,
            altitudes.c.altitude_min,
            altitudes.c.altitude_max,
        )
        .where(transient_table.c.id_import == imprt.id_import)
        .where(transient_table.c[geom_col] != None)
        .where(
            sa.or_(
                transient_table.c[alt_min_field.source_field] == None,
                transient_table.c[alt_max_field.source_field] == None,
            )
        )
        .cte("cte")
    )
    stmt = (
        update(transient_table)
        .where(transient_table.c.id_import == cte.c.id_import)
        .where(transient_table.c.line_no == cte.c.line_no)
        .values(
            {
                transient_table.c[alt_min_field.dest_field]: sa.case(
                    (
                        transient_table.c[alt_min_field.source_field] == None,
                        cte.c.altitude_min,
                    ),
                    else_=transient_table.c[alt_min_field.dest_field],
                ),
                transient_table.c[alt_max_field.dest_field]: sa.case(
                    (
                        transient_table.c[alt_max_field.source_field] == None,
                        cte.c.altitude_max,
                    ),
                    else_=transient_table.c[alt_max_field.dest_field],
                ),
            }
        )
    )
    db.session.execute(stmt)


def check_duplicate_uuid(imprt: TImports, entity: Entity, uuid_field: BibFields):
    """
    Check if there is already a record with the same uuid in the transient table. Include an error in the report for each entry with a uuid dupplicated.

    Parameters
    ----------
    imprt : Import
        The import to check.
    entity : Entity
        The entity to check.
    uuid_field : BibFields
        The field to check.
    """
    transient_table = imprt.destination.get_transient_table()
    uuid_col = transient_table.c[uuid_field.dest_field]
    duplicates = get_duplicates_query(
        imprt,
        uuid_col,
        whereclause=sa.and_(
            transient_table.c[entity.validity_column].isnot(None),
            uuid_col != None,
        ),
    )
    report_erroneous_rows(
        imprt,
        entity,
        error_type=ImportCodeError.DUPLICATE_UUID,
        error_column=uuid_field.name_field,
        whereclause=(transient_table.c.line_no == duplicates.c.lines),
    )


def check_existing_uuid(
    imprt: TImports,
    entity: Entity,
    uuid_field: BibFields,
    id_dataset_field: BibFields = None,
    skip=False,
):
    """
    Check if there is already a record with the same uuid in the destination table.
    Include an error in the report for each existing uuid in the destination table.
    Parameters
    ----------
    imprt : Import
        The import to check.
    entity : Entity
        The entity to check.
    uuid_field : BibFields
        The field to check
    id_dataset_field : BibFields
        if defnied, the uuid existence is checked for the given dataset. Otherwise, it is checked globally

    skip: Boolean
        Raise SKIP_EXISTING_UUID instead of EXISTING_UUID and set row validity to None (do not import)
    """
    transient_table = imprt.destination.get_transient_table()
    dest_table = entity.get_destination_table()
    error_type = "SKIP_EXISTING_UUID" if skip else "EXISTING_UUID"

    whereclause = sa.and_(
        transient_table.c[uuid_field.dest_field] == dest_table.c[uuid_field.dest_field],
        transient_table.c[entity.validity_column].is_(True),
    )

    if id_dataset_field:
        whereclause = whereclause & (
            transient_table.c[id_dataset_field.dest_field]
            == dest_table.c[id_dataset_field.dest_field]
        )

    report_erroneous_rows(
        imprt,
        entity,
        error_type=error_type,
        error_column=uuid_field.name_field,
        whereclause=whereclause,
        level_validity_mapping={"ERROR": False, "WARNING": None},
    )


def generate_missing_uuid_for_id_origin(
    imprt: TImports,
    uuid_field: BibFields,
    id_origin_field: BibFields,
):
    """
    Update records in the transient table where the uuid is None
    with a new UUID.
    Generate UUID in transient table when there are no UUID yet, but
    there are a id_origin.
    Ensure rows with same id_origin get the same UUID.

    Parameters
    ----------
    imprt : TImports
        The import to check.
    uuid_field : BibFields
        The field to check.
    id_origin_field : BibFields
        Field used to generate the UUID
    """
    transient_table = imprt.destination.get_transient_table()
    cte_generated_uuid = (
        sa.select(
            transient_table.c[id_origin_field.source_field].label("id_source"),
            func.uuid_generate_v4().label("uuid"),
        )
        .group_by(transient_table.c[id_origin_field.source_field])
        .cte("cte_generated_uuid")
    )

    stmt = (
        update(transient_table)
        .values(
            {
                transient_table.c[uuid_field.dest_field]: cte_generated_uuid.c.uuid,
            }
        )
        .where(
            transient_table.c.id_import == imprt.id_import,
            transient_table.c[id_origin_field.source_field] == cte_generated_uuid.c.id_source,
            transient_table.c[uuid_field.source_field].is_(None),
        )
    )
    db.session.execute(stmt)


def generate_missing_uuid(
    imprt: TImports,
    entity: Entity,
    uuid_field: BibFields,
    whereclause: Any = None,
):
    """
    Update records in the transient table where the UUID is None
    with a new UUID.

    Parameters
    ----------
    imprt : TImports
        The import to check.
    entity : Entity
        The entity to check.
    uuid_field : BibFields
        The field to check.
    """

    transient_table = imprt.destination.get_transient_table()
    stmt = (
        update(transient_table)
        .values(
            {
                transient_table.c[uuid_field.dest_field]: func.uuid_generate_v4(),
            }
        )
        .where(
            transient_table.c.id_import == imprt.id_import,
            transient_table.c[entity.validity_column].is_not(None),
            transient_table.c[uuid_field.source_field].is_(None),
        )
    )
    if whereclause is not None:
        stmt = stmt.where(whereclause)
    db.session.execute(stmt)


def check_duplicate_source_pk(
    imprt: TImports,
    entity: Entity,
    field: BibFields,
) -> None:
    """
    Check for duplicate source primary keys in the transient table of an import.

    Parameters
    ----------
    imprt : TImports
        The import to check.
    entity : Entity
        The entity to check.
    field : BibFields
        The field to check.
    """
    transient_table = imprt.destination.get_transient_table()
    dest_col = transient_table.c[field.dest_column]
    duplicates = get_duplicates_query(
        imprt,
        dest_col,
        whereclause=sa.and_(
            transient_table.c[entity.validity_column].isnot(None),
            dest_col != None,
        ),
    )
    report_erroneous_rows(
        imprt,
        entity,
        error_type=ImportCodeError.DUPLICATE_ENTITY_SOURCE_PK,
        error_column=field.name_field,
        whereclause=(transient_table.c.line_no == duplicates.c.lines),
    )


def check_dates(
    imprt: TImports,
    entity: Entity,
    date_min_field: BibFields = None,
    date_max_field: BibFields = None,
) -> None:
    """
    Check the validity of dates in the transient table of an import.

    Parameters
    ----------
    imprt : TImports
        The import to check.
    entity : TEntity
        The entity to check.
    date_min_field : BibFields, optional
        The field representing the minimum date.
    date_max_field : BibFields, optional
        The field representing the maximum date.

    """
    transient_table = imprt.destination.get_transient_table()
    today = date.today()
    if date_min_field:
        date_min_dest_col = transient_table.c[date_min_field.dest_field]
        report_erroneous_rows(
            imprt,
            entity,
            error_type=ImportCodeError.DATE_MIN_TOO_HIGH,
            error_column=date_min_field.name_field,
            whereclause=(date_min_dest_col > today),
        )
        report_erroneous_rows(
            imprt,
            entity,
            error_type=ImportCodeError.DATE_MIN_TOO_LOW,
            error_column=date_min_field.name_field,
            whereclause=(date_min_dest_col < date(1900, 1, 1)),
        )
    if date_max_field:
        date_max_dest_col = transient_table.c[date_max_field.dest_field]
        report_erroneous_rows(
            imprt,
            entity,
            error_type=ImportCodeError.DATE_MAX_TOO_HIGH,
            error_column=date_max_field.name_field,
            whereclause=sa.and_(
                date_max_dest_col > today,
                date_min_dest_col <= today,
            ),
        )
        report_erroneous_rows(
            imprt,
            entity,
            error_type=ImportCodeError.DATE_MAX_TOO_LOW,
            error_column=date_max_field.name_field,
            whereclause=(date_max_dest_col < date(1900, 1, 1)),
        )
    if date_min_field and date_max_field:
        report_erroneous_rows(
            imprt,
            entity,
            error_type=ImportCodeError.DATE_MIN_SUP_DATE_MAX,
            error_column=date_min_field.name_field,
            whereclause=(date_min_dest_col > date_max_dest_col),
        )


def check_altitudes(
    imprt: TImports,
    entity: Entity,
    alti_min_field: BibFields = None,
    alti_max_field: BibFields = None,
) -> None:
    """
    Check the validity of altitudes in the transient table of an import.

    Parameters
    ----------
    imprt : TImports
        The import to check.
    entity : TEntity
        The entity to check.
    alti_min_field : BibFields, optional
        The field representing the minimum altitude.
    alti_max_field : BibFields, optional
        The field representing the maximum altitude.

    """
    transient_table = imprt.destination.get_transient_table()
    if alti_min_field:
        alti_min_name_field = alti_min_field.name_field
        alti_min_dest_col = transient_table.c[alti_min_field.dest_field]

    if alti_max_field:
        alti_max_dest_col = transient_table.c[alti_max_field.dest_field]

    if alti_min_field and alti_max_field:
        report_erroneous_rows(
            imprt,
            entity,
            error_type=ImportCodeError.ALTI_MIN_SUP_ALTI_MAX,
            error_column=alti_min_name_field,
            whereclause=(alti_min_dest_col > alti_max_dest_col),
        )


def check_depths(
    imprt: TImports,
    entity: Entity,
    depth_min_field: BibFields = None,
    depth_max_field: BibFields = None,
) -> None:
    """
    Check the validity of depths in the transient table of an import.

    Parameters
    ----------
    imprt : TImports
        The import to check.
    entity : TEntity
        The entity to check.
    depth_min_field : BibFields, optional
        The field representing the minimum depth.
    depth_max_field : BibFields, optional
        The field representing the maximum depth.

    """
    transient_table = imprt.destination.get_transient_table()
    if depth_min_field:
        depth_min_name_field = depth_min_field.name_field
        depth_min_dest_col = transient_table.c[depth_min_field.dest_field]
        report_erroneous_rows(
            imprt,
            entity,
            error_type=ImportCodeError.INVALID_INTEGER,
            error_column=depth_min_name_field,
            whereclause=(depth_min_dest_col < 0),
        )

    if depth_max_field:
        depth_max_name_field = depth_max_field.name_field
        depth_max_dest_col = transient_table.c[depth_max_field.dest_field]
        report_erroneous_rows(
            imprt,
            entity,
            error_type=ImportCodeError.INVALID_INTEGER,
            error_column=depth_max_name_field,
            whereclause=(depth_max_dest_col < 0),
        )

    if depth_min_field and depth_max_field:
        report_erroneous_rows(
            imprt,
            entity,
            error_type=ImportCodeError.DEPTH_MIN_SUP_ALTI_MAX,  # Yes, there is a typo in db... Should be "DEPTH_MIN_SUP_DEPTH_MAX"
            error_column=depth_min_name_field,
            whereclause=(depth_min_dest_col > depth_max_dest_col),
        )


def check_digital_proof_urls(imprt, entity, digital_proof_field):
    """
    Checks for valid URLs in a given column of a transient table.

    Parameters
    ----------
    imprt : TImports
        The import to check.
    entity : TEntity
        The entity to check.
    digital_proof_field : TField
        The field containing the URLs to check.
    """
    transient_table = imprt.destination.get_transient_table()
    digital_proof_dest_col = transient_table.c[digital_proof_field.dest_field]
    report_erroneous_rows(
        imprt,
        entity,
        error_type=ImportCodeError.INVALID_URL_PROOF,
        error_column=digital_proof_field.name_field,
        whereclause=(
            sa.and_(
                digital_proof_dest_col is not None,
                digital_proof_dest_col.op("!~")(
                    r"^(?:(?:https?|ftp):\/\/)?[\w.-]+(?:\.[\w\.-]+)+[\w\-\._~:/?#[\]@!\$&'\(\)\*\+,;=.]+$"
                ),
            )
        ),
    )


def check_entity_data_consistency(imprt, entity, fields, grouping_field):
    """
    Checks for rows with the same uuid, but different contents,
    in the same entity. Used mainely for parent entities.
    Parameters
    ----------
    imprt : TImports
        The import to check.
    entity : Entity
        The entity to check.
    fields : BibFields
        The fields to check.
    grouping_field : BibFields
        The field to group identical rows.
    """
    transient_table = imprt.destination.get_transient_table()
    grouping_col = transient_table.c[grouping_field.source_field]

    # get duplicates rows in the transient_table
    duplicates = get_duplicates_query(
        imprt,
        grouping_col,
        whereclause=sa.and_(
            transient_table.c[entity.validity_column].is_not(None),
            grouping_col != None,
        ),
    )

    columns = [getattr(transient_table.c, field.source_field) for field in fields.values()]

    # hash the content of the entity to check for differences without
    # comparing each columns
    hashedRows = (
        select(
            transient_table.c.line_no.label("lines"),
            grouping_col.label("grouping_col"),
            func.md5(func.concat(*columns)).label("hashed"),
        )
        .where(transient_table.c.line_no == duplicates.c.lines)
        .where(transient_table.c.id_import == imprt.id_import)
        .alias("hashedRows")
    )

    # get the rows with differences

    erroneous = (
        select(hashedRows.c.grouping_col.label("grouping_col"))
        .group_by(hashedRows.c.grouping_col)
        .having(func.count(func.distinct(hashedRows.c.hashed)) > 1)
    ).cte()

    # note: rows are unidentified (None) instead of being marked as invalid (False) in order to avoid running checks
    report_erroneous_rows(
        imprt,
        entity,
        error_type=ImportCodeError.INCOHERENT_DATA,
        error_column=grouping_field.name_field,  # FIXME
        whereclause=(grouping_col == erroneous.c.grouping_col),
        level_validity_mapping={"ERROR": None},
    )


def disable_duplicated_rows(imprt, entity, fields, grouping_field):
    """
    When several rows have the same value in grouping field (typically UUID) field,
    first one is untouched but following rows have validity set to None (do not import).
    """
    transient_table = imprt.destination.get_transient_table()
    grouping_col = transient_table.c[grouping_field.source_field]

    duplicates = (
        select(
            transient_table.c.line_no,
            func.row_number()
            .over(partition_by=grouping_col, order_by=transient_table.c.line_no)
            .label("row_number"),
        )
        .where(transient_table.c.id_import == imprt.id_import)
        .where(grouping_col.isnot(None))
        .where(transient_table.c[entity.validity_column].is_(True))
        .cte()
    )

    db.session.execute(
        sa.update(transient_table)
        .where(transient_table.c.id_import == imprt.id_import)
        .where(transient_table.c.line_no == duplicates.c.line_no)
        .where(duplicates.c.row_number > 1)  # keep first row
        .values({entity.validity_column: None})
    )
