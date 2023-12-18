from sqlalchemy.sql.expression import select, update
from sqlalchemy.sql import column
import sqlalchemy as sa

from geonature.utils.env import db

from geonature.core.imports.models import TImports
from geonature.core.imports.checks.sql.utils import report_erroneous_rows

from pypnnomenclature.models import TNomenclatures, BibNomenclaturesTypes


__all__ = [
    "do_nomenclatures_mapping",
    "check_nomenclature_exist_proof",
    "check_nomenclature_blurring",
    "check_nomenclature_source_status",
]


def do_nomenclatures_mapping(imprt, entity, fields, fill_with_defaults=False):
    # see https://github.com/PnX-SI/gn_module_import/issues/68#issuecomment-1384267087
    # for explanation on empty fields and default nomenclature handling.
    transient_table = imprt.destination.get_transient_table()
    # Set nomenclatures using content mapping
    for field in filter(lambda field: field.mnemonique != None, fields.values()):
        source_col = transient_table.c[field.source_field]
        dest_col = transient_table.c[field.dest_field]
        # This CTE return the list of source value / cd_nomenclature for a given nomenclature type
        cte = (
            select(
                sa.func.nullif(column("key"), "").label("value"),  # replace "" by NULL
                column("value").label("cd_nomenclature"),
            )
            .select_from(sa.func.JSON_EACH_TEXT(TImports.contentmapping[field.mnemonique]))
            .where(TImports.id_import == imprt.id_import)
            .cte("cte")
        )
        # This statement join the cte results with nomenclatures
        # in order to set the id_nomenclature
        stmt = (
            update(transient_table)
            .where(transient_table.c.id_import == imprt.id_import)
            .where(source_col.isnot_distinct_from(cte.c.value))  # to ensure NULL == NULL is True
            .where(TNomenclatures.cd_nomenclature == cte.c.cd_nomenclature)
            .where(BibNomenclaturesTypes.mnemonique == field.mnemonique)
            .where(TNomenclatures.id_type == BibNomenclaturesTypes.id_type)
            .values({field.dest_field: TNomenclatures.id_nomenclature})
        )
        db.session.execute(stmt)
        erroneous_conds = [dest_col == None]
        if fill_with_defaults:
            # Set default nomenclature for empty user fields
            stmt = (
                update(transient_table)
                .where(transient_table.c.id_import == imprt.id_import)
                .where(source_col == None)
                .where(dest_col == None)  # empty source_col may be have been completed by mapping
                .values(
                    {
                        field.dest_field: getattr(
                            sa.func, entity.destination_table_schema
                        ).get_default_nomenclature_value(
                            field.mnemonique,
                        )
                    }
                )
            )
            db.session.execute(stmt)
            # Do not report invalid nomenclature when source_col is NULL: if dest_col is NULL,
            # it is because there are no default nomenclature. This is the same as server
            # default value getting default nomenclature which may be NULL (unexisting).
            erroneous_conds.append(source_col != None)
        report_erroneous_rows(
            imprt,
            entity,
            error_type="INVALID_NOMENCLATURE",
            error_column=field.name_field,
            whereclause=sa.and_(*erroneous_conds),
        )


def check_nomenclature_exist_proof(
    imprt, entity, nomenclature_field, digital_proof_field, non_digital_proof_field
):
    transient_table = imprt.destination.get_transient_table()
    if digital_proof_field is None and non_digital_proof_field is None:
        return
    oui = TNomenclatures.query.filter(
        TNomenclatures.nomenclature_type.has(
            BibNomenclaturesTypes.mnemonique == nomenclature_field.mnemonique
        ),
        TNomenclatures.mnemonique == "Oui",
    ).one()
    oui_filter = transient_table.c[nomenclature_field.dest_field] == oui.id_nomenclature
    proof_set_filters = []
    if digital_proof_field is not None:
        proof_set_filters.append(
            transient_table.c[digital_proof_field.dest_field] != None,
        )
    if non_digital_proof_field is not None:
        proof_set_filters.append(
            transient_table.c[non_digital_proof_field.dest_field] != None,
        )
    proof_set_filter = sa.or_(*proof_set_filters) if proof_set_filters else sa.false()
    report_erroneous_rows(
        imprt,
        entity,
        error_type="INVALID_EXISTING_PROOF_VALUE",
        error_column=nomenclature_field.name_field,
        whereclause=sa.or_(
            sa.and_(oui_filter, ~proof_set_filter),
            sa.and_(~oui_filter, proof_set_filter),
        ),
    )


# TODO This check will requires to evolve to handle per-row dataset,
# as private status will require to be checker for each row.
def check_nomenclature_blurring(imprt, entity, blurring_field):
    """
    Raise an error if blurring not set.
    Required if the dataset is private.
    """
    transient_table = imprt.destination.get_transient_table()
    report_erroneous_rows(
        imprt,
        entity,
        error_type="CONDITIONAL_MANDATORY_FIELD_ERROR",
        error_column=blurring_field.name_field,
        whereclause=(transient_table.c[blurring_field.dest_field] == None),
    )


def check_nomenclature_source_status(imprt, entity, source_status_field, ref_biblio_field):
    transient_table = imprt.destination.get_transient_table()
    litterature = TNomenclatures.query.filter(
        TNomenclatures.nomenclature_type.has(BibNomenclaturesTypes.mnemonique == "STATUT_SOURCE"),
        TNomenclatures.cd_nomenclature == "Li",
    ).one()
    report_erroneous_rows(
        imprt,
        entity,
        error_type="CONDITIONAL_MANDATORY_FIELD_ERROR",
        error_column=source_status_field.name_field,
        whereclause=sa.and_(
            transient_table.c[source_status_field.dest_field] == litterature.id_nomenclature,
            transient_table.c[ref_biblio_field.dest_field] == None,
        ),
    )
