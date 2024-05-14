from flask import current_app
import sqlalchemy as sa
from sqlalchemy.orm import joinedload

import typing
import json

from geonature.utils.env import db
from geonature.core.imports.models import Entity, BibFields, TImports
from geonature.core.imports.import_mixin import ImportMixin, ImportStatisticsLabels
from .plot import distribution_plot
from bokeh.models.layouts import Row

from geonature.core.imports.utils import (
    load_transient_data_in_dataframe,
    update_transient_data_from_dataframe,
)
from geonature.core.imports.checks.dataframe import (
    check_datasets,
    check_geography,
    check_required_values,
    check_types,
    concat_dates,
)
from geonature.core.imports.checks.sql import (
    check_altitudes,
    check_cd_hab,
    check_dates,
    check_depths,
    check_erroneous_parent_entities,
    check_duplicate_source_pk,
    check_duplicate_uuid,
    check_existing_uuid,
    check_geography_outside,
    check_is_valid_geography,
    check_no_parent_entity,
    convert_geom_columns,
    do_nomenclatures_mapping,
    generate_altitudes,
    set_id_parent_from_destination,
    set_parent_line_no,
)
from .checks import (
    generate_id_station,
    set_id_station_from_line_no,
)


class OcchabImportMixin(ImportMixin):

    @staticmethod
    def statistics_labels() -> typing.List[ImportStatisticsLabels]:
        return [
            {"key": "station_count", "value": "Nombre de stations importées"},
            {"key": "habitat_count", "value": "Nombre d’habitats importés"},
        ]

    @staticmethod
    def preprocess_transient_data(imprt: TImports, df) -> set:
        updated_cols = set()
        date_min_field = db.session.execute(
            db.select(BibFields)
            .where(BibFields.destination == imprt.destination)
            .where(BibFields.name_field == "date_min")
        ).scalar_one()
        date_max_field = db.session.execute(
            db.select(BibFields)
            .where(BibFields.destination == imprt.destination)
            .where(BibFields.name_field == "date_max")
        ).scalar_one()
        updated_cols |= concat_dates(
            df,
            datetime_min_col=date_min_field.source_field,
            datetime_max_col=date_max_field.source_field,
            date_min_col=date_min_field.source_field,
            date_max_col=date_max_field.source_field,
        )
        return updated_cols

    @staticmethod
    def check_transient_data(task, logger, imprt: TImports):
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
                    # TODO@TestImportsOcchab.test_import_valid_file: add testcase
                    generate_altitudes(
                        imprt,
                        fields["the_geom_local"],
                        fields["altitude_min"],
                        fields["altitude_max"],
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
                    imprt,
                    entity,
                    selected_fields.get("depth_min"),
                    selected_fields.get("depth_max"),
                )
                if "WKT" in selected_fields:
                    check_is_valid_geography(
                        imprt, entity, selected_fields["WKT"], fields["geom_4326"]
                    )
                # TODO@TestImportsOcchab.test_import_valid_file: remove this check
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

    @staticmethod
    def import_data_to_destination(imprt: TImports) -> None:
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
                    # TODO@TestImportsOcchab.test_import_valid_file: add testcase
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
                # TODO@TestImportsOcchab.test_import_valid_file: add testcase
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

    @staticmethod
    def remove_data_from_destination(imprt: TImports) -> None:
        entities = (
            Entity.query.filter_by(destination=imprt.destination)
            .order_by(sa.desc(Entity.order))
            .all()
        )
        for entity in entities:
            destination_table = entity.get_destination_table()
            r = db.session.execute(
                sa.delete(destination_table).where(destination_table.c.id_import == imprt.id_import)
            )

    @staticmethod
    def report_plot(imprt: TImports) -> Row:
        return distribution_plot(imprt)

    @staticmethod
    def compute_bounding_box(imprt: TImports):
        name_geom_4326_field = "geom_4326"
        code_entity = "station"

        entity = Entity.query.filter_by(destination=imprt.destination, code=code_entity).one()

        where_clause_id_import = None
        id_import = imprt.id_import
        destination_import = imprt.destination

        # If import is still in-progress data is retrieved from the import transient table,
        #   otherwise the import is done and data is retrieved from the destination table
        if imprt.loaded:
            # Retrieve the import transient table ("t_imports_occhab")
            table_with_data = destination_import.get_transient_table()
        else:
            # Retrieve the destination table ("t_stations")
            entity = Entity.query.filter_by(destination=destination_import, code="station").one()
            table_with_data = entity.get_destination_table()

        # Set the WHERE clause
        where_clause_id_import = table_with_data.c["id_import"] == id_import

        # Build the statement to retrieve the valid bounding box
        statement = None
        if imprt.loaded == True:
            # Compute from entries in the transient table and related to the import
            transient_table = imprt.destination.get_transient_table()
            statement = (
                sa.select(
                    sa.func.ST_AsGeojson(
                        sa.func.ST_Extent(transient_table.c[name_geom_4326_field])
                    )
                )
                .where(where_clause_id_import)
                .where(transient_table.c[entity.validity_column] == True)
            )
        else:
            destination_table = entity.get_destination_table()
            # Compute from entries in the destination table and related to the import
            statement = sa.select(
                sa.func.ST_AsGeojson(sa.func.ST_Extent(destination_table.c[name_geom_4326_field]))
            ).where(where_clause_id_import)

        # Execute the statement to eventually retrieve the valid bounding box
        (valid_bbox,) = db.session.execute(statement).fetchone()

        # Return the valid bounding box or None
        if valid_bbox:
            return json.loads(valid_bbox)
        pass
