from typing import List
from geonature.core.imports.checks.errors import ImportCodeError
from geonature.core.imports.models import BibFields, Entity, TImports
import sqlalchemy as sa
from sqlalchemy.orm import aliased

from geonature.utils.env import db
from geonature.core.imports.checks.sql.utils import report_erroneous_rows

__all__ = [
    "set_id_parent_from_destination",
    "set_parent_line_no",
    "check_no_parent_entity",
    "check_erroneous_parent_entities",
]


def set_id_parent_from_destination(
    imprt: TImports,
    parent_entity: Entity,
    entity: Entity,
    id_field: BibFields,
    fields: List[BibFields],
) -> None:
    """
    Complete the id_parent column in the transient table of an import when the parent already exists in the destination table.

    Parameters
    ----------
    imprt : TImports
        The import to update.
    parent_entity : Entity
        The entity of the parent.
    entity : Entity
        The current entity.
    id_field : BibFields
        The field containing the id of the parent.
    fields : List[BibFields]
        The fields to use for matching the child with its parent in the destination table.
    """
    transient_table = imprt.destination.get_transient_table()
    parent_destination = parent_entity.get_destination_table()
    for field in fields:
        if field is None:
            continue
        db.session.execute(
            sa.update(transient_table)
            .where(
                transient_table.c.id_import == imprt.id_import,
                transient_table.c[entity.validity_column].isnot(None),
            )
            # We need to complete the id_parent only for child not on the same row than a parent
            .where(transient_table.c[parent_entity.validity_column].is_(None))
            # finding parent row:
            .where(transient_table.c[field.dest_column] == parent_destination.c[field.dest_column])
            .values({id_field.dest_column: parent_destination.c[id_field.dest_column]})
        )


def set_parent_line_no(
    imprt: TImports,
    parent_entity: Entity,
    entity: Entity,
    parent_line_no: BibFields,
    fields: List[BibFields],
) -> None:
    """
    Set parent_line_no on child entities when:
    - no parent entity on same line
    - parent entity is valid
    - looking for parent entity through each given field in fields

    Parameters
    ----------
    imprt : TImports
        The import to update.
    parent_entity : Entity
        The entity of the parent.
    entity : Entity
        The current entity.
    id_parent : BibFields
        The field containing the id of the parent.
    parent_line_no : BibFields
        The field containing the line number of the parent.
    fields : List[BibFields]
        The fields to use for matching the child with its parent in the destination table.
    """
    transient_child = imprt.destination.get_transient_table()
    transient_parent = aliased(transient_child, name="transient_parent")
    for field in fields:
        if field is None:
            continue
        db.session.execute(
            sa.update(transient_child)
            .where(
                transient_child.c.id_import == imprt.id_import,
                transient_child.c[entity.validity_column].isnot(None),
            )
            # We need to complete the parent_line_no only for child not on the same row than a parent
            .where(transient_child.c[parent_entity.validity_column].is_(None))
            # finding parent row:
            .where(
                transient_parent.c.id_import == imprt.id_import,
                transient_parent.c[parent_entity.validity_column].isnot(None),
                transient_parent.c[field.dest_column] == transient_child.c[field.dest_column],
            )
            .values({parent_line_no: transient_parent.c.line_no})
        )


def check_no_parent_entity(
    imprt: TImports,
    parent_entity: Entity,
    entity: Entity,
    id_parent: BibFields,
    parent_line_no: BibFields,
) -> None:
    """
    Station may be referenced:
    - on the same line (station_validity is not None)
    - by id_parent (parent already exists in destination)
    - by parent_line_no (new parent from another line of the imported file - see set_parent_line_no)

    Parameters
    ----------
    imprt : TImports
        The import to check.
    parent_entity : Entity
        The entity of the parent.
    entity : Entity
        The current entity.
    id_parent : BibFields
        The field containing the id of the parent.
    parent_line_no : BibFields
        The field containing the line number of the parent.
    """
    transient_table = imprt.destination.get_transient_table()
    report_erroneous_rows(
        imprt,
        entity,
        error_type=ImportCodeError.NO_PARENT_ENTITY,
        error_column=id_parent,
        whereclause=sa.and_(
            # Complains for missing parent only for valid child, as parent may be missing
            # because of erroneous uuid required to find the parent.
            transient_table.c[entity.validity_column].is_(True),
            transient_table.c[parent_entity.validity_column].is_(None),  # no parent on same line
            transient_table.c[id_parent].is_(None),  # no parent in destination
            transient_table.c[parent_line_no].is_(None),  # no parent on another line
        ),
    )


def check_erroneous_parent_entities(
    imprt: TImports, parent_entity: Entity, entity: Entity, parent_line_no: BibFields
) -> None:
    """
    Check for erroneous (not valid) parent entities in the transient table of an import.

    Parameters
    ----------
    imprt : TImports
        The import to check.
    parent_entity : Entity
        The entity of the parent.
    entity : Entity
        The current entity.
    parent_line_no : BibFields
        The field containing the line number of the parent.

    Notes
    -----
    # Note: if child entity reference parent entity by id_parent, this means the parent
    # entity is already in destination table so obviously valid.

    The error codes are:
        - ERRONEOUS_PARENT_ENTITY: the parent on the same line is not valid.
    """
    transient_child = imprt.destination.get_transient_table()
    transient_parent = aliased(transient_child)
    report_erroneous_rows(
        imprt,
        entity,
        error_type=ImportCodeError.ERRONEOUS_PARENT_ENTITY,
        error_column="",
        whereclause=sa.and_(
            transient_child.c[entity.validity_column].isnot(None),
            sa.or_(
                # parent is on the same line
                transient_child.c[parent_entity.validity_column].is_(False),
                sa.and_(  # parent is on another line referenced by parent_line_no
                    transient_parent.c.id_import == transient_child.c.id_import,
                    transient_parent.c.line_no == transient_child.c[parent_line_no],
                    transient_parent.c[parent_entity.validity_column].is_(False),
                ),
            ),
        ),
    )
