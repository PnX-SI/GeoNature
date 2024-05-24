from datetime import date

from flask import current_app
from sqlalchemy import func
from sqlalchemy.sql.expression import select, update, join
from sqlalchemy.sql import column
import sqlalchemy as sa

from geonature.utils.env import db

from geonature.core.imports.checks.sql.utils import get_duplicates_query, report_erroneous_rows

from apptax.taxonomie.models import Taxref, CorNomListe, BibNoms
from pypn_habref_api.models import Habref


def check_referential(imprt, entity, field, reference_field, error_type, reference_table=None):
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


def check_cd_nom(imprt, entity, field, list_id=None):
    # Filter out on a taxhub list if provided
    if list_id is not None:
        reference_table = join(Taxref, BibNoms).join(
            CorNomListe,
            sa.and_(BibNoms.id_nom == CorNomListe.id_nom, CorNomListe.id_liste == list_id),
        )
    else:
        reference_table = Taxref
    check_referential(
        imprt, entity, field, Taxref.cd_nom, "CD_NOM_NOT_FOUND", reference_table=reference_table
    )


def check_cd_hab(imprt, entity, field):
    check_referential(imprt, entity, field, Habref.cd_hab, "CD_HAB_NOT_FOUND")


def generate_altitudes(imprt, geom_local_field, alt_min_field, alt_max_field):
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


def check_duplicate_uuid(imprt, entity, uuid_field):
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
        error_type="DUPLICATE_UUID",
        error_column=uuid_field.name_field,
        whereclause=(transient_table.c.line_no == duplicates.c.lines),
    )


def check_existing_uuid(imprt, entity, uuid_field, whereclause=sa.true()):
    transient_table = imprt.destination.get_transient_table()
    dest_table = entity.get_destination_table()
    report_erroneous_rows(
        imprt,
        entity,
        error_type="EXISTING_UUID",
        error_column=uuid_field.name_field,
        whereclause=sa.and_(
            transient_table.c[uuid_field.dest_field] == dest_table.c[uuid_field.dest_field],
            whereclause,
        ),
    )


def generate_missing_uuid(imprt, entity, uuid_field):
    transient_table = imprt.destination.get_transient_table()
    stmt = (
        update(transient_table)
        .values(
            {
                transient_table.c[uuid_field.dest_field]: func.uuid_generate_v4(),
            }
        )
        .where(transient_table.c.id_import == imprt.id_import)
        .where(
            transient_table.c[uuid_field.source_field] == None,
        )
        .where(transient_table.c[uuid_field.dest_field] == None)
    )
    db.session.execute(stmt)


def check_duplicate_source_pk(imprt, entity, field):
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
        error_type="DUPLICATE_ENTITY_SOURCE_PK",
        error_column=field.name_field,
        whereclause=(transient_table.c.line_no == duplicates.c.lines),
    )


def check_dates(imprt, entity, date_min_field=None, date_max_field=None):
    transient_table = imprt.destination.get_transient_table()
    today = date.today()
    if date_min_field:
        date_min_dest_col = transient_table.c[date_min_field.dest_field]
        report_erroneous_rows(
            imprt,
            entity,
            error_type="DATE_MIN_TOO_HIGH",
            error_column=date_min_field.name_field,
            whereclause=(date_min_dest_col > today),
        )
        report_erroneous_rows(
            imprt,
            entity,
            error_type="DATE_MIN_TOO_LOW",
            error_column=date_min_field.name_field,
            whereclause=(date_min_dest_col < date(1900, 1, 1)),
        )
    if date_max_field:
        date_max_dest_col = transient_table.c[date_max_field.dest_field]
        report_erroneous_rows(
            imprt,
            entity,
            error_type="DATE_MAX_TOO_HIGH",
            error_column=date_max_field.name_field,
            whereclause=sa.and_(
                date_max_dest_col > today,
                date_min_dest_col <= today,
            ),
        )
        report_erroneous_rows(
            imprt,
            entity,
            error_type="DATE_MAX_TOO_LOW",
            error_column=date_max_field.name_field,
            whereclause=(date_max_dest_col < date(1900, 1, 1)),
        )
    if date_min_field and date_max_field:
        report_erroneous_rows(
            imprt,
            entity,
            error_type="DATE_MIN_SUP_DATE_MAX",
            error_column=date_min_field.name_field,
            whereclause=(date_min_dest_col > date_max_dest_col),
        )


def check_altitudes(imprt, entity, alti_min_field=None, alti_max_field=None):
    transient_table = imprt.destination.get_transient_table()
    if alti_min_field:
        alti_min_name_field = alti_min_field.name_field
        alti_min_dest_col = transient_table.c[alti_min_field.dest_field]
        report_erroneous_rows(
            imprt,
            entity,
            error_type="INVALID_INTEGER",
            error_column=alti_min_name_field,
            whereclause=(alti_min_dest_col < 0),
        )

    if alti_max_field:
        alti_max_name_field = alti_max_field.name_field
        alti_max_dest_col = transient_table.c[alti_max_field.dest_field]
        report_erroneous_rows(
            imprt,
            entity,
            error_type="INVALID_INTEGER",
            error_column=alti_max_name_field,
            whereclause=(alti_max_dest_col < 0),
        )

    if alti_min_field and alti_max_field:
        report_erroneous_rows(
            imprt,
            entity,
            error_type="ALTI_MIN_SUP_ALTI_MAX",
            error_column=alti_min_name_field,
            whereclause=(alti_min_dest_col > alti_max_dest_col),
        )


def check_depths(imprt, entity, depth_min_field=None, depth_max_field=None):
    transient_table = imprt.destination.get_transient_table()
    if depth_min_field:
        depth_min_name_field = depth_min_field.name_field
        depth_min_dest_col = transient_table.c[depth_min_field.dest_field]
        report_erroneous_rows(
            imprt,
            entity,
            error_type="INVALID_INTEGER",
            error_column=depth_min_name_field,
            whereclause=(depth_min_dest_col < 0),
        )

    if depth_max_field:
        depth_max_name_field = depth_max_field.name_field
        depth_max_dest_col = transient_table.c[depth_max_field.dest_field]
        report_erroneous_rows(
            imprt,
            entity,
            error_type="INVALID_INTEGER",
            error_column=depth_max_name_field,
            whereclause=(depth_max_dest_col < 0),
        )

    if depth_min_field and depth_max_field:
        report_erroneous_rows(
            imprt,
            entity,
            error_type="DEPTH_MIN_SUP_ALTI_MAX",  # Yes, there is a typo in db... Should be "DEPTH_MIN_SUP_DEPTH_MAX"
            error_column=depth_min_name_field,
            whereclause=(depth_min_dest_col > depth_max_dest_col),
        )


def check_digital_proof_urls(imprt, entity, digital_proof_field):
    transient_table = imprt.destination.get_transient_table()
    digital_proof_dest_col = transient_table.c[digital_proof_field.dest_field]
    report_erroneous_rows(
        imprt,
        entity,
        error_type="INVALID_URL_PROOF",
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
