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
    imprt,
    parent_entity,
    child_entity,
    id_field,
    fields,
):
    transient_table = imprt.destination.get_transient_table()
    parent_destination = parent_entity.get_destination_table()
    for field in fields:
        if field is None:
            continue
        db.session.execute(
            sa.update(transient_table)
            .where(transient_table.c.id_import == imprt.id_import)
            .where(transient_table.c[child_entity.validity_column].isnot(None))
            # We need to complete the id_parent only for child not on the same row than a parent
            .where(transient_table.c[parent_entity.validity_column].is_(None))
            # finding parent row:
            .where(transient_table.c[field.dest_column] == parent_destination.c[field.dest_column])
            .values({id_field.dest_column: parent_destination.c[id_field.dest_column]})
        )


def set_parent_line_no(
    imprt,
    parent_entity,
    child_entity,
    parent_line_no,
    fields,
):
    transient_child = imprt.destination.get_transient_table()
    transient_parent = aliased(transient_child, name="transient_parent")
    for field in fields:
        if field is None:
            continue
        db.session.execute(
            sa.update(transient_child)
            .where(transient_child.c.id_import == imprt.id_import)
            .where(transient_child.c[child_entity.validity_column].isnot(None))
            # We need to complete the parent_line_no only for child not on the same row than a parent
            .where(transient_child.c[parent_entity.validity_column].is_(None))
            # finding parent row:
            .where(transient_parent.c.id_import == imprt.id_import)
            .where(transient_parent.c[parent_entity.validity_column].isnot(None))
            .where(transient_parent.c[field.dest_column] == transient_child.c[field.dest_column])
            .values({parent_line_no: transient_parent.c.line_no})
        )


def check_no_parent_entity(imprt, parent_entity, child_entity, id_parent, parent_line_no):
    """
    Station may be referenced:
    - on the same line (station_validity is not None)
    - by id_parent (parent already exists in destination)
    - by parent_line_no (new parent from another line of the imported file)
    """
    transient_table = imprt.destination.get_transient_table()
    report_erroneous_rows(
        imprt,
        child_entity,
        error_type="NO_PARENT_ENTITY",
        error_column=id_parent,
        whereclause=sa.and_(
            # Complains for missing parent only for valid child, as parent may be missing
            # because of erroneous uuid required to find the parent.
            transient_table.c[child_entity.validity_column].is_(True),
            transient_table.c[parent_entity.validity_column].is_(None),  # no parent on same line
            transient_table.c[id_parent].is_(None),  # no parent in destination
            transient_table.c[parent_line_no].is_(None),  # no parent on another line
        ),
    )


def check_erroneous_parent_entities(imprt, parent_entity, child_entity, parent_line_no):
    # Note: if child entity reference parent entity by id_parent, this means the parent
    # entity is already in destination table so obviously valid.
    transient_child = imprt.destination.get_transient_table()
    transient_parent = aliased(transient_child)
    report_erroneous_rows(
        imprt,
        child_entity,
        error_type="ERRONEOUS_PARENT_ENTITY",
        error_column="",
        whereclause=sa.and_(
            transient_child.c[child_entity.validity_column].isnot(None),
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
