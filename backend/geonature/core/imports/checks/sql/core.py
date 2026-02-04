from geonature.core.imports.checks.errors import ImportCodeError
from geonature.core.imports.checks.sql.utils import report_erroneous_rows
import sqlalchemy as sa

from geonature.utils.env import db

from geonature.core.imports.models import (
    Entity,
    EntityField,
    BibFields,
    TImports,
)


__all__ = ["init_rows_validity", "check_orphan_rows"]


def init_rows_validity(imprt: TImports, dataset_name_field: str = "id_dataset"):
    """
    Validity columns are three-states:
      - None: the row does not contains data for the given entity
      - False: the row contains data for the given entity, but data are erroneous
      - True: the row contains data for the given entity, and data are valid
    """
    transient_table = imprt.destination.get_transient_table()
    entities = (
        Entity.query.filter_by(destination=imprt.destination).order_by(sa.desc(Entity.order)).all()
    )
    # Set validity=NULL (not participating in the entity) for all rows
    db.session.execute(
        sa.update(transient_table)
        .where(transient_table.c.id_import == imprt.id_import)
        .values({entity.validity_column: None for entity in entities})
    )
    # Multi-entity fields are ignored for entity identification, but this is not an issue
    # as rows with multi-entity field only will raise an ORPHAN_ROW error
    selected_fields_names = []
    constant_fields = []
    for field_name, source_field in imprt.fieldmapping.items():
        column_src = source_field.get("column_src", None)
        if column_src:
            if type(column_src) == list:
                selected_fields_names.extend(set(column_src) & set(imprt.columns))
            elif column_src in imprt.columns:
                selected_fields_names.append(field_name)
        else:
            constant_fields.append(field_name)
    for entity in entities:
        # Select fields associated to this entity *and only to this entity*
        fields = (
            db.session.query(BibFields)
            .where(BibFields.name_field.in_(selected_fields_names))
            .where(BibFields.entities.any(EntityField.entity == entity))
            .where(~BibFields.entities.any(EntityField.entity != entity))
            .where(BibFields.name_field != dataset_name_field)
            .all()
        )
        is_constant_field_indicated = db.session.scalar(
            sa.exists(BibFields)
            .where(BibFields.name_field.in_(constant_fields))
            .where(BibFields.entities.any(EntityField.entity == entity))
            .where(~BibFields.entities.any(EntityField.entity != entity))
            .where(BibFields.name_field != dataset_name_field)
            .select()
        )

        if fields:
            db.session.execute(
                sa.update(transient_table)
                .where(transient_table.c.id_import == imprt.id_import)
                .where(
                    sa.or_(
                        *[
                            sa.or_(
                                transient_table.c[field.source_column].isnot(None),
                                transient_table.c[field.dest_column].isnot(None),
                            )
                            for field in fields
                        ]
                    )
                )
                .values({entity.validity_column: True})
            )
        if is_constant_field_indicated:
            db.session.execute(
                sa.update(transient_table)
                .where(transient_table.c.id_import == imprt.id_import)
                .values({entity.validity_column: True})
            )


def update_rows_validity(imprt: TImports, entity: Entity):
    """
    Update validity column for an entity:
      - For rows with the same UUID, keep only ONE row that contains data (validity=True)
      - Set validity to None for other duplicate rows that also contain data
      - Never modify rows where validity is False
    """
    transient_table = imprt.destination.get_transient_table()

    # Get the UUID column for this entity
    uuid_column = entity.uuid_column.dest_column  # type: ignore

    if not uuid_column:
        return

    # Get fields associated to this entity *and only to this entity*
    selected_fields_names = []
    for field_name, source_field in imprt.fieldmapping.items():
        column_src = source_field.get("column_src", None)
        if column_src:
            if type(column_src) == list:
                selected_fields_names.extend(set(column_src) & set(imprt.columns))
            elif column_src in imprt.columns:
                selected_fields_names.append(field_name)

    fields = (
        db.session.query(BibFields)
        .where(BibFields.name_field.in_(selected_fields_names))
        .where(BibFields.entities.any(EntityField.entity == entity))
        .where(~BibFields.entities.any(EntityField.entity != entity))
        .all()
    )

    if not fields:
        return

    # Build condition to check if a row has data in entity fields
    has_data_conditions = []
    for field in fields:
        has_data_conditions.append(
            sa.or_(
                transient_table.c[field.source_column].isnot(None),
                transient_table.c[field.dest_column].isnot(None),
            )
        )

    # Subquery to find duplicate UUIDs where multiple rows have data
    # and get the minimum line_no among rows with data
    duplicate_uuids_with_data = (
        sa.select(
            transient_table.c[uuid_column],
            sa.func.min(transient_table.c.line_no).label("min_line_no"),
        )
        .where(transient_table.c.id_import == imprt.id_import)
        .where(transient_table.c[entity.validity_column] == True)  # Only True, not False
        .where(transient_table.c[uuid_column].isnot(None))
        .where(sa.or_(*has_data_conditions))  # Only rows with data
        .group_by(transient_table.c[uuid_column])
        .having(sa.func.count() > 1)
        .subquery()
    )

    # Update validity to None for duplicate rows with data (except the first one)
    db.session.execute(
        sa.update(transient_table)
        .where(transient_table.c.id_import == imprt.id_import)
        .where(transient_table.c[entity.validity_column] == True)  # Only True, not False or None
        .where(
            transient_table.c[uuid_column].in_(sa.select(duplicate_uuids_with_data.c[uuid_column]))
        )
        .where(sa.or_(*has_data_conditions))  # Only rows with data
        .where(
            transient_table.c.line_no
            != sa.select(duplicate_uuids_with_data.c.min_line_no)
            .where(duplicate_uuids_with_data.c[uuid_column] == transient_table.c[uuid_column])
            .scalar_subquery()
        )
        .values({entity.validity_column: None})
    )


def check_orphan_rows(imprt: TImports):
    transient_table = imprt.destination.get_transient_table()
    # TODO: handle multi-source fields
    # This is actually not a big issue as multi-source fields are unlikely to also be multi-entity fields.
    selected_fields_names = []
    for field_name, source_field in imprt.fieldmapping.items():
        column_src = source_field.get("column_src", None)
        if type(column_src) == list:
            selected_fields_names.extend(set(column_src) & set(imprt.columns))
        elif column_src in imprt.columns:
            selected_fields_names.append(field_name)
    # Select fields associated to multiple entities
    AllEntityField = sa.orm.aliased(EntityField)
    fields = (
        db.session.query(BibFields)
        .join(EntityField)
        .join(Entity)
        .order_by(Entity.order)  # errors are associated to the first Entity
        .filter(BibFields.name_field.in_(selected_fields_names))
        .join(AllEntityField, AllEntityField.id_field == BibFields.id_field)
        .group_by(BibFields.id_field, EntityField.id_field, Entity.id_entity)
        .having(sa.func.count(AllEntityField.id_entity) > 1)
        .all()
    )
    for field in fields:
        report_erroneous_rows(
            imprt,
            entity=None,  # OK because ORPHAN_ROW has only WARNING level
            error_type=ImportCodeError.ORPHAN_ROW,
            error_column=field.name_field,
            whereclause=sa.and_(
                transient_table.c[field.source_field].isnot(None),
                *[transient_table.c[col].is_(None) for col in imprt.destination.validity_columns],
            ),
        )


def check_mandatory_field(imprt, entity, field):
    transient_table = imprt.destination.get_transient_table()
    source_field = transient_table.c[field.source_column]
    whereclause = sa.and_(
        transient_table.c[entity.validity_column].isnot(None),
        source_field.is_(None),
    )
    report_erroneous_rows(
        imprt,
        entity=entity,
        error_type=ImportCodeError.MISSING_VALUE,
        error_column=field.name_field,
        whereclause=whereclause,
    )


# Currently not used as done during dataframe checks
def check_mandatory_fields(imprt, entity, fields):
    for field in fields.values():
        if not field.mandatory or not field.dest_field:
            continue
        check_mandatory_field(imprt, entity, field)
