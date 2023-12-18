from flask import current_app
import sqlalchemy as sa
from sqlalchemy.orm import joinedload

from geonature.utils.env import db
from geonature.utils.sentry import start_sentry_child

from gn_module_import.models import Entity, EntityField, BibFields
from gn_module_import.utils import (
    load_transient_data_in_dataframe,
    update_transient_data_from_dataframe,
)
from gn_module_import.checks.dataframe import (
    concat_dates,
    check_required_values,
    check_types,
    check_geography,
    check_datasets,
)
from gn_module_import.checks.sql import (
    do_nomenclatures_mapping,
    convert_geom_columns,
    check_cd_hab,
    generate_altitudes,
    check_duplicate_uuid,
    check_existing_uuid,
    generate_missing_uuid,
    check_duplicates_source_pk,
    check_dates,
    check_altitudes,
    check_depths,
    check_is_valid_geography,
)


def check_transient_data(task, logger, imprt):
    task.update_state(state="PROGRESS", meta={"progress": 0})
    transient_table = imprt.destination.get_transient_table()

    entities = Entity.query.filter_by(destination=imprt.destination).order_by(Entity.order).all()
    for entity in entities:
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

        updated_cols |= check_types(imprt, entity, df, fields)

        if entity.code == "station":
            updated_cols |= check_datasets(
                imprt,
                entity,
                df,
                uuid_field=fields["unique_dataset_id"],
                id_field=fields["id_dataset"],
                module_code="OCCHAB",
            )

        updated_cols |= check_required_values(imprt, entity, df, fields)

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

        if entity.code == "station":
            convert_geom_columns(
                imprt,
                entity,
                geom_4326_field=fields["geom_4326"],
                geom_local_field=fields["geom_local"],
            )

        if "entity_source_pk_value" in selected_fields:  # FIXME FIXME
            check_duplicates_source_pk(imprt, entity, selected_fields["entity_source_pk_value"])

        if entity.code == "station" and "unique_id_sinp_station" in selected_fields:
            check_duplicate_uuid(imprt, entity, selected_fields["unique_id_sinp_station"])
            check_existing_uuid(imprt, entity, selected_fields["unique_id_sinp_station"])
        if entity.code == "habitat" and "unique_id_sinp_habitat" in selected_fields:
            check_duplicate_uuid(imprt, entity, selected_fields["unique_id_sinp_habitat"])
            check_existing_uuid(imprt, entity, selected_fields["unique_id_sinp_habitat"])

        do_nomenclatures_mapping(
            imprt,
            entity,
            selected_fields,
            fill_with_defaults=current_app.config["IMPORT"][
                "FILL_MISSING_NOMENCLATURE_WITH_DEFAULT_VALUE"
            ],
        )

        if entity.code == "habitat":
            if "cd_hab" in selected_fields:
                check_cd_hab(imprt, entity, selected_fields["cd_hab"])

        if entity.code == "station":
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

        check_dates(imprt, entity, selected_fields.get("date_min"), selected_fields.get("date_max"))
        check_depths(
            imprt, entity, selected_fields.get("depth_min"), selected_fields.get("depth_max")
        )

        if entity.code == "station":
            if "WKT" in selected_fields:
                check_is_valid_geography(imprt, entity, selected_fields["WKT"], fields["geom_4326"])
            if current_app.config["IMPORT"]["ID_AREA_RESTRICTION"]:
                check_geography_outside(
                    imprt,
                    entity,
                    fields["geom_local"],
                    id_area=current_app.config["IMPORT"]["ID_AREA_RESTRICTION"],
                )


def import_data_to_occhab(imprt):
    pass


def remove_data_from_occhab(imprt):
    pass
