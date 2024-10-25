from typing import Mapping, Optional
from geonature.core.imports.checks.errors import ImportCodeError
from sqlalchemy.sql.expression import select, update
from sqlalchemy.sql import column
import sqlalchemy as sa

from geonature.utils.env import db

from geonature.core.imports.models import BibFields, Entity, TImports
from geonature.core.imports.checks.sql.utils import report_erroneous_rows

from pypnnomenclature.models import TNomenclatures, BibNomenclaturesTypes


__all__ = [
    "do_nomenclatures_mapping",
    "check_nomenclature_exist_proof",
    "check_nomenclature_blurring",
    "check_nomenclature_source_status",
    "check_nomenclature_technique_collect",
]


def do_nomenclatures_mapping(
    imprt: TImports,
    entity: Entity,
    fields: Mapping[str, BibFields],
    fill_with_defaults: bool = False,
) -> None:
    """
    Set nomenclatures using content mapping.

    Parameters
    ----------
    imprt : TImports
        The import to check.
    entity : Entity
        The entity to check.
    fields : Mapping[str, BibFields]
        Mapping of field names to BibFields objects.
    fill_with_defaults : bool, optional
        If True, fill empty user fields with default nomenclatures.

    Notes
    -----
    See the following link for explanation on empty fields and default nomenclature handling:
    https://github.com/PnX-SI/gn_module_import/issues/68#issuecomment-1384267087
    """

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
            .where(
                transient_table.c.id_import == imprt.id_import,
                source_col.isnot_distinct_from(cte.c.value),  # to ensure NULL == NULL is True
                TNomenclatures.cd_nomenclature == cte.c.cd_nomenclature,
                BibNomenclaturesTypes.mnemonique == field.mnemonique,
                TNomenclatures.id_type == BibNomenclaturesTypes.id_type,
            )
            .values({field.dest_field: TNomenclatures.id_nomenclature})
        )
        db.session.execute(stmt)
        erroneous_conds = [dest_col == None]
        if fill_with_defaults:
            # Set default nomenclature for empty user fields
            stmt = (
                update(transient_table)
                .where(
                    transient_table.c.id_import == imprt.id_import,
                    source_col == None,
                    dest_col == None,
                )  # empty source_col may be have been completed by mapping
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
            error_type=ImportCodeError.INVALID_NOMENCLATURE,
            error_column=field.name_field,
            whereclause=sa.and_(*erroneous_conds),
        )


def check_nomenclature_exist_proof(
    imprt: TImports,
    entity: Entity,
    nomenclature_field: BibFields,
    digital_proof_field: Optional[BibFields],
    non_digital_proof_field: Optional[BibFields],
) -> None:
    """
    Check the existence of a nomenclature proof in the transient table.

    Parameters
    ----------
    imprt : TImports
        The import to check.
    entity : Entity
        The entity to check.
    nomenclature_field : BibFields
        The field representing the nomenclature to check.
    digital_proof_field : Optional[BibFields]
        The field for digital proof, if any.
    non_digital_proof_field : Optional[BibFields]
        The field for non-digital proof, if any.
    """
    transient_table = imprt.destination.get_transient_table()

    if digital_proof_field is None and non_digital_proof_field is None:
        return

    oui_nomenclature = db.session.execute(
        sa.select(TNomenclatures).where(
            TNomenclatures.mnemonique == "Oui",
            TNomenclatures.nomenclature_type.has(
                BibNomenclaturesTypes.mnemonique == nomenclature_field.mnemonique
            ),
        )
    ).scalar_one()

    oui_filter = (
        transient_table.c[nomenclature_field.dest_field] == oui_nomenclature.id_nomenclature
    )
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
        error_type=ImportCodeError.INVALID_EXISTING_PROOF_VALUE,
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
        error_type=ImportCodeError.CONDITIONAL_MANDATORY_FIELD_ERROR,
        error_column=blurring_field.name_field,
        whereclause=(transient_table.c[blurring_field.dest_field] == None),
    )


def check_nomenclature_source_status(
    imprt: TImports, entity: Entity, source_status_field: BibFields, ref_biblio_field: BibFields
) -> None:
    """
    Check the nomenclature source status and raise an error if the status is "Lit" (Literature)
    whereas the reference biblio field is empty.

    Parameters
    ----------
    imprt : TImports
        The import to check.
    entity : Entity
        The entity to check.
    source_status_field : BibFields
        The field representing the source status.
    ref_biblio_field : BibFields
        The field representing the reference bibliography.

    Notes
    -----
    The error codes are:
        - CONDITIONAL_MANDATORY_FIELD_ERROR: the field is mandatory and not set.
    """
    transient_table = imprt.destination.get_transient_table()

    litterature_nomenclature = db.session.execute(
        sa.select(TNomenclatures).where(
            TNomenclatures.nomenclature_type.has(
                BibNomenclaturesTypes.mnemonique == "STATUT_SOURCE"
            ),
            TNomenclatures.cd_nomenclature == "Li",
        )
    ).scalar_one()

    report_erroneous_rows(
        imprt,
        entity,
        error_type=ImportCodeError.CONDITIONAL_MANDATORY_FIELD_ERROR,
        error_column=source_status_field.name_field,
        whereclause=sa.and_(
            transient_table.c[source_status_field.dest_field]
            == litterature_nomenclature.id_nomenclature,
            transient_table.c[ref_biblio_field.dest_field] == None,
        ),
    )


def check_nomenclature_technique_collect(
    imprt: TImports,
    entity: Entity,
    source_status_field: BibFields,
    technical_precision_field: BibFields,
) -> None:
    """
    Check the nomenclature source status and raise an error if the status is "Autre, préciser"
    whereas technical precision field is empty.

    Parameters
    ----------
    imprt : TImports
        The import to check.
    entity : Entity
        The entity to check.
    source_status_field : BibFields
        The field representing the source status.
    technical_precision_field : BibFields
        The field representing the technical precision.

    Notes
    -----
    The error codes are:
        - CONDITIONAL_MANDATORY_FIELD_ERROR: the field is mandatory and not set.
    """
    transient_table = imprt.destination.get_transient_table()
    other = db.session.execute(
        sa.select(TNomenclatures).where(
            TNomenclatures.nomenclature_type.has(
                BibNomenclaturesTypes.mnemonique == "TECHNIQUE_COLLECT_HAB"
            ),
            TNomenclatures.cd_nomenclature == "10",
        )
    ).scalar_one()

    report_erroneous_rows(
        imprt,
        entity,
        error_type=ImportCodeError.CONDITIONAL_MANDATORY_FIELD_ERROR,
        error_column=source_status_field.name_field,
        whereclause=sa.and_(
            transient_table.c[source_status_field.dest_field] == other.id_nomenclature,
            transient_table.c[technical_precision_field.dest_field] == None,
        ),
    )
