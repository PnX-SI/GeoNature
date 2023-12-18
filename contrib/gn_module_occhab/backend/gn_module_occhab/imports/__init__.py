from flask import current_app
import sqlalchemy as sa
from sqlalchemy.orm import joinedload

from geonature.utils.env import db
from geonature.utils.sentry import start_sentry_child

from geonature.core.imports.models import Entity, EntityField, BibFields
from geonature.core.imports.utils import (
    load_transient_data_in_dataframe,
    update_transient_data_from_dataframe,
)
from geonature.core.imports.checks.dataframe import (
    concat_dates,
    check_required_values,
    check_types,
    check_geography,
    check_datasets,
)
from geonature.core.imports.checks.sql import (
    do_nomenclatures_mapping,
    convert_geom_columns,
    check_cd_hab,
    generate_altitudes,
    check_duplicate_uuid,
    check_existing_uuid,
    generate_missing_uuid,
    check_duplicate_source_pk,
    check_dates,
    check_altitudes,
    check_depths,
    check_is_valid_geography,
    set_id_parent_from_destination,
    set_parent_line_no,
    check_erroneous_parent_entities,
    check_no_parent_entity,
)
from .checks import (
    generate_id_station,
    set_id_station_from_line_no,
)


def check_transient_data(task, logger, imprt):
    task.update_state(state="PROGRESS", meta={"progress": 0})
    transient_table = imprt.destination.get_transient_table()

    entities = {
        entity.code: entity
        for entity in Entity.query.filter_by(destination=imprt.destination)
        .order_by(Entity.order)  # order matters for id_station
        .all()
    }
    for entity in entities.values():
        fields = {ef.field.name_field: ef.field for ef in entity.fields}
        selected_fields = {
            field_name: fields[field_name]
            for field_name, source_field in imprt.fieldmapping.items()
            if source_field in imprt.columns and field_name in fields
        }
        source_cols = [
            field.source_column
            for field in selected_fields.values()
            if field.source_field is not None and field.mnemonique is None
        ]
        updated_cols = set()

        ### Dataframe checks

        df = load_transient_data_in_dataframe(imprt, entity, source_cols)

        if entity.code == "station":
            updated_cols |= concat_dates(
                df,
                datetime_min_field=fields["date_min"],
                datetime_max_field=fields["date_max"],
                date_min_field=fields["date_min"],
                date_max_field=fields["date_max"],
            )

        updated_cols |= check_types(
            imprt, entity, df, fields
        )  # FIXME do not check station uuid twice

        if entity.code == "station":
            updated_cols |= check_datasets(
                imprt,
                entity,
                df,
                uuid_field=fields["unique_dataset_id"],
                id_field=fields["id_dataset"],
                module_code="OCCHAB",
            )

        updated_cols |= check_required_values(
            imprt, entity, df, fields
        )  # FIXME do not check required multi-entity fields twice

        if entity.code == "station":
            updated_cols |= check_geography(
                imprt,
                entity,
                df,
                file_srid=imprt.srid,
                geom_4326_field=fields["geom_4326"],
                geom_local_field=fields["geom_local"],
                wkt_field=fields["WKT"],
                latitude_field=fields["latitude"],
                longitude_field=fields["longitude"],
            )

        update_transient_data_from_dataframe(imprt, entity, updated_cols, df)

        ### SQL checks

        do_nomenclatures_mapping(
            imprt,
            entity,
            selected_fields,
            fill_with_defaults=current_app.config["IMPORT"][
                "FILL_MISSING_NOMENCLATURE_WITH_DEFAULT_VALUE"
            ],
        )

        if entity.code == "station":
            convert_geom_columns(
                imprt,
                entity,
                geom_4326_field=fields["geom_4326"],
                geom_local_field=fields["geom_local"],
            )
            if imprt.fieldmapping.get("altitudes_generate", False):
                generate_altitudes(
                    imprt, fields["the_geom_local"], fields["altitude_min"], fields["altitude_max"]
                )
            check_altitudes(
                imprt,
                entity,
                selected_fields.get("altitude_min"),
                selected_fields.get("altitude_max"),
            )
            check_dates(
                imprt, entity, selected_fields.get("date_min"), selected_fields.get("date_max")
            )
            check_depths(
                imprt, entity, selected_fields.get("depth_min"), selected_fields.get("depth_max")
            )
            if "WKT" in selected_fields:
                check_is_valid_geography(imprt, entity, selected_fields["WKT"], fields["geom_4326"])
            if current_app.config["IMPORT"]["ID_AREA_RESTRICTION"]:
                check_geography_outside(
                    imprt,
                    entity,
                    fields["geom_local"],
                    id_area=current_app.config["IMPORT"]["ID_AREA_RESTRICTION"],
                )
            if "unique_id_sinp_station" in selected_fields:
                check_duplicate_uuid(imprt, entity, selected_fields["unique_id_sinp_station"])
                check_existing_uuid(imprt, entity, selected_fields["unique_id_sinp_station"])
            if "id_station_source" in fields:
                check_duplicate_source_pk(imprt, entity, fields["id_station_source"])
                # TODO check existing source pk?

        if entity.code == "habitat":
            if "cd_hab" in selected_fields:
                check_cd_hab(imprt, entity, selected_fields["cd_hab"])
            if "unique_id_sinp_habitat" in selected_fields:
                check_duplicate_uuid(imprt, entity, selected_fields["unique_id_sinp_habitat"])
                check_existing_uuid(imprt, entity, selected_fields["unique_id_sinp_habitat"])

            set_id_parent_from_destination(
                imprt,
                parent_entity=entities["station"],
                child_entity=entities["habitat"],
                id_field=fields["id_station"],
                fields=[
                    selected_fields.get("unique_id_sinp_station"),
                ],
            )
            set_parent_line_no(
                imprt,
                parent_entity=entities["station"],
                child_entity=entities["habitat"],
                parent_line_no="station_line_no",
                fields=[
                    selected_fields.get("unique_id_sinp_station"),
                    selected_fields.get("id_station_source"),
                ],
            )
            check_no_parent_entity(
                imprt,
                parent_entity=entities["station"],
                child_entity=entities["habitat"],
                id_parent="id_station",
                parent_line_no="station_line_no",
            )
            check_erroneous_parent_entities(
                imprt,
                parent_entity=entities["station"],
                child_entity=entities["habitat"],
                parent_line_no="station_line_no",
            )


def import_data_to_occhab(imprt):
    transient_table = imprt.destination.get_transient_table()
    entities = {
        entity.code: entity
        for entity in (
            Entity.query.filter_by(destination=imprt.destination)
            .options(joinedload(Entity.fields))
            .order_by(Entity.order)
            .all()
        )
    }
    for entity in entities.values():
        fields = {
            ef.field.name_field: ef.field for ef in entity.fields if ef.field.dest_field != None
        }
        insert_fields = {fields["id_station"]}
        for field_name, source_field in imprt.fieldmapping.items():
            if field_name not in fields:  # not a destination field
                continue
            field = fields[field_name]
            if field.multi:
                if not set(source_field).isdisjoint(imprt.columns):
                    insert_fields |= {field}
            else:
                if source_field in imprt.columns:
                    insert_fields |= {field}
        if entity.code == "station":
            # unique_dataset_id is replaced with id_dataset
            insert_fields -= {fields["unique_dataset_id"]}
            insert_fields |= {fields["id_dataset"]}
            insert_fields |= {fields["geom_4326"], fields["geom_local"]}
            if imprt.fieldmapping.get("altitudes_generate", False):
                insert_fields |= {fields["altitude_min"], fields["altitude_max"]}
            # FIXME:
            # if not selected_fields.get("unique_id_sinp_generate", False):
            #    # even if not selected, add uuid column to force insert of NULL values instead of default generation of uuid
            #    insert_fields |= {fields["unique_id_sinp_station"]}
        else:  # habitat
            # These fields are associated with habitat as necessary to find the corresponding station,
            # but they are not inserted in habitat destination so we need to manually remove them.
            insert_fields -= {fields["unique_id_sinp_station"], fields["id_station_source"]}
            # FIXME:
            # if not selected_fields.get("unique_id_sinp_generate", False):
            #    # even if not selected, add uuid column to force insert of NULL values instead of default generation of uuid
            #    insert_fields |= {fields["unique_id_sinp_habitat"]}
        names = ["id_import"] + [field.dest_field for field in insert_fields]
        select_stmt = (
            sa.select(
                sa.literal(imprt.id_import),
                *[transient_table.c[field.dest_field] for field in insert_fields],
            )
            .where(transient_table.c.id_import == imprt.id_import)
            .where(transient_table.c[entity.validity_column] == True)
        )
        destination_table = entity.get_destination_table()
        insert_stmt = sa.insert(destination_table).from_select(
            names=names,
            select=select_stmt,
        )
        if entity.code == "station":
            """
            We need the id_station in transient table to use it when inserting habitats.
            I have tried to use RETURNING after inserting the stations to update transient table, roughly:
            WITH (INSERT pr_occhab.t_stations FROM SELECT ... RETURNING transient_table.line_no, id_station) AS insert_cte
            UPDATE transient_table SET id_station = insert_cte.id_station WHERE transient_table.line_no = insert_cte.line_no
            but RETURNING clause can only contains columns from INSERTed table so we can not return line_no.
            Consequently, we generate id_station directly in transient table before inserting the stations.
            """
            generate_id_station(imprt, entity)
        else:
            set_id_station_from_line_no(
                imprt,
                station_entity=entities["station"],
                habitat_entity=entities["habitat"],
            )
        r = db.session.execute(insert_stmt)
        imprt.statistics.update({f"{entity.code}_count": r.rowcount})


def remove_data_from_occhab(imprt):
    entities = (
        Entity.query.filter_by(destination=imprt.destination).order_by(sa.desc(Entity.order)).all()
    )
    for entity in entities:
        destination_table = entity.get_destination_table()
        r = db.session.execute(
            sa.delete(destination_table).where(destination_table.c.id_import == imprt.id_import)
        )
