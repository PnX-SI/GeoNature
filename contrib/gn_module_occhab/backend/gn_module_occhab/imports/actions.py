from math import ceil
from flask import current_app
from werkzeug.exceptions import Conflict

from geonature.core.imports.checks.sql.extra import (
    check_entity_data_consistency,
    disable_duplicated_rows,
    generate_missing_uuid_for_id_origin,
    generate_missing_uuid,
    generate_entity_id,
    set_parent_id_from_line_no,
)
from geonature.core.imports.checks.sql.utils import report_erroneous_rows, print_transient_table
import sqlalchemy as sa
from sqlalchemy.orm import joinedload, aliased
from sqlalchemy.inspection import inspect

import typing

from geonature.utils.env import db
from geonature.core.imports.models import Entity, BibFields, TImports
from geonature.core.imports.actions import ImportActions, ImportStatisticsLabels
from .plot import distribution_plot

from geonature.core.imports.utils import (
    get_mapping_data,
    load_transient_data_in_dataframe,
    update_transient_data_from_dataframe,
    compute_bounding_box,
)

from geonature.core.imports.checks.dataframe import (
    check_datasets,
    check_geometry,
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
    check_duplicate_uuid,
    check_existing_uuid,
    check_geometry_outside,
    check_is_valid_geometry,
    check_no_parent_entity,
    convert_geom_columns,
    do_nomenclatures_mapping,
    generate_altitudes,
    set_id_parent_from_destination,
    set_parent_line_no,
    init_rows_validity,
    check_orphan_rows,
    check_nomenclature_technique_collect,
)
from geonature.core.imports.checks.sql.core import (
    check_mandatory_field,
)
from .checks import (
    check_existing_station_permissions,
)
from bokeh.embed.standalone import StandaloneEmbedJson


def get_occhab_entities() -> typing.Tuple[Entity, Entity]:
    entity_habitat = Entity.query.filter_by(code="habitat").one()
    entity_station = Entity.query.filter_by(code="station").one()
    return entity_station, entity_habitat


class OcchabImportActions(ImportActions):
    @staticmethod
    def statistics_labels() -> typing.List[ImportStatisticsLabels]:
        return [
            {"key": "station_count", "value": "Nombre de stations importées"},
            {"key": "habitat_count", "value": "Nombre d’habitats importés"},
        ]

    @staticmethod
    def preprocess_transient_data(imprt: TImports, df) -> None:
        date_min_field = db.session.execute(
            sa.select(BibFields)
            .where(BibFields.destination == imprt.destination)
            .where(BibFields.name_field == "date_min")
        ).scalar_one()
        date_max_field = db.session.execute(
            sa.select(BibFields)
            .where(BibFields.destination == imprt.destination)
            .where(BibFields.name_field == "date_max")
        ).scalar_one()
        if date_min_field.source_field in df and date_max_field.source_field in df:
            concat_dates(
                df,
                datetime_min_col=date_min_field.source_field,
                datetime_max_col=date_max_field.source_field,
                date_min_col=date_min_field.source_field,
                date_max_col=date_max_field.source_field,
            )

    @staticmethod
    def dataframe_checks(imprt, df, entity, fields, selected_fields):
        updated_cols = set({})
        updated_cols |= check_types(
            imprt, entity, df, fields
        )  # FIXME do not check station uuid twice

        updated_cols |= check_required_values(imprt, entity, df, fields)

        return updated_cols

    @staticmethod
    def check_habitat_dataframe(imprt):
        """
        Check the habitat data before importing.

        List of checks (in order of execution):
        - check required values
        - check types
        - check the existence of cd_hab
        - check the duplicates of unique_id_sinp_habitat (in the file and in the database)

        Parameters
        ----------
        imprt : TImports
            The import to check.

        """
        _, entity_habitat = get_occhab_entities()
        fields, selected_fields, source_cols = get_mapping_data(imprt, entity_habitat)

        updated_cols = set()

        ### Dataframe checks
        df = load_transient_data_in_dataframe(imprt, entity_habitat, source_cols)
        updated_cols |= OcchabImportActions.dataframe_checks(
            imprt, df, entity_habitat, fields, selected_fields
        )
        update_transient_data_from_dataframe(imprt, entity_habitat, updated_cols, df)

    @staticmethod
    def check_habitat_sql(imprt):
        entity_station, entity_habitat = get_occhab_entities()
        fields, selected_fields, _ = get_mapping_data(imprt, entity_habitat)

        ### SQL checks
        do_nomenclatures_mapping(
            imprt,
            entity_habitat,
            selected_fields,
            fill_with_defaults=current_app.config["IMPORT"][
                "FILL_MISSING_NOMENCLATURE_WITH_DEFAULT_VALUE"
            ],
        )
        if "cd_hab" in selected_fields:
            check_cd_hab(imprt, entity_habitat, selected_fields["cd_hab"])
        if not current_app.config["IMPORT"]["DEFAULT_GENERATE_MISSING_UUID"]:
            check_mandatory_field(imprt, entity_habitat, fields["unique_id_sinp_station"])
        if "unique_id_sinp_habitat" in selected_fields:
            check_duplicate_uuid(imprt, entity_habitat, selected_fields["unique_id_sinp_habitat"])
            check_existing_uuid(
                imprt,
                entity_habitat,
                selected_fields["unique_id_sinp_habitat"],
                skip=True,  # TODO config
            )
        if current_app.config["IMPORT"]["DEFAULT_GENERATE_MISSING_UUID"]:
            generate_missing_uuid(
                imprt,
                entity_habitat,
                fields["unique_id_sinp_habitat"],
            )
        else:
            check_mandatory_field(imprt, entity_habitat, fields["unique_id_sinp_habitat"])

        check_nomenclature_technique_collect(
            imprt,
            entity_habitat,
            fields["id_nomenclature_collection_technique"],
            fields["technical_precision"],
        )

        set_id_parent_from_destination(
            imprt,
            parent_entity=entity_station,
            entity=entity_habitat,
            id_field=fields["id_station"],
            fields=[
                selected_fields.get("unique_id_sinp_station"),
            ],
        )
        check_existing_station_permissions(imprt)

        set_parent_line_no(
            imprt,
            parent_entity=entity_station,
            entity=entity_habitat,
            parent_line_no="station_line_no",
            fields=[
                selected_fields.get("id_station_source"),
                selected_fields.get("unique_id_sinp_station"),
            ],
        )

        # Check habitat parents
        check_no_parent_entity(
            imprt,
            parent_entity=entity_station,
            entity=entity_habitat,
            id_parent="id_station",
            parent_line_no="station_line_no",
        )

        check_erroneous_parent_entities(
            imprt,
            parent_entity=entity_station,
            entity=entity_habitat,
            parent_line_no="station_line_no",
        )

    @staticmethod
    def check_station_consistency(imprt):
        entity_station, _ = get_occhab_entities()

        _, selected_fields, _ = get_mapping_data(imprt, entity_station)

        if "id_station_source" in selected_fields:
            check_entity_data_consistency(
                imprt,
                entity_station,
                selected_fields,
                selected_fields["id_station_source"],
            )
        if "unique_id_sinp_station" in selected_fields:
            check_entity_data_consistency(
                imprt,
                entity_station,
                selected_fields,
                selected_fields["unique_id_sinp_station"],
            )

    @staticmethod
    def check_station_dataframe(imprt):
        """
        Check the station data before importing.

        List of checks and data operations (in order of execution):
        - check datasets
        - check types
        - check required values
        - convert geom columns
        - check geography
        - generate altitudes if requested
        - check altitudes
        - check dates
        - check depths
        - check if given geometries are valid (see ST_VALID in PostGIS)
        - if requested, check if given geometry is outside the restricted area

        Parameters
        ----------
        imprt : TImports
            The import to check.

        """

        entity_station, _ = get_occhab_entities()

        fields, selected_fields, source_cols = get_mapping_data(imprt, entity_station)

        # Save column names where the data was changed in the dataframe
        updated_cols = set()

        ### Dataframe checks
        df = load_transient_data_in_dataframe(imprt, entity_station, source_cols)

        updated_cols |= OcchabImportActions.dataframe_checks(
            imprt, df, entity_station, fields, selected_fields
        )
        updated_cols |= check_datasets(
            imprt,
            entity_station,
            df,
            uuid_field=fields["unique_dataset_id"],
            id_field=fields["id_dataset"],
            module_code="OCCHAB",
        )

        updated_cols |= check_geometry(
            imprt,
            entity_station,
            df,
            file_srid=imprt.srid,
            geom_4326_field=fields["geom_4326"],
            geom_local_field=fields["geom_local"],
            wkt_field=fields["WKT"],
            latitude_field=fields["latitude"],
            longitude_field=fields["longitude"],
        )

        update_transient_data_from_dataframe(imprt, entity_station, updated_cols, df)

    @staticmethod
    def check_station_sql(imprt):
        transient_table = imprt.destination.get_transient_table()
        entity_station, _ = get_occhab_entities()

        fields, selected_fields, _ = get_mapping_data(imprt, entity_station)

        do_nomenclatures_mapping(
            imprt,
            entity_station,
            selected_fields,
            fill_with_defaults=current_app.config["IMPORT"][
                "FILL_MISSING_NOMENCLATURE_WITH_DEFAULT_VALUE"
            ],
        )

        convert_geom_columns(
            imprt,
            entity_station,
            geom_4326_field=fields["geom_4326"],
            geom_local_field=fields["geom_local"],
        )

        # Process altitude generate field
        # TODO@TestImportsOcchab.test_import_valid_file: add testcase
        default_altitude_generate = True
        altitudes_generate = default_altitude_generate
        altitudes_generate_bib_field = imprt.fieldmapping.get("altitudes_generate", None)
        if altitudes_generate_bib_field:
            altitudes_generate = altitudes_generate_bib_field.get(
                "constant_value", default_altitude_generate
            )
        if altitudes_generate:
            generate_altitudes(
                imprt, fields["geom_local"], fields["altitude_min"], fields["altitude_max"]
            )
        check_altitudes(
            imprt,
            entity_station,
            selected_fields.get("altitude_min"),
            selected_fields.get("altitude_max"),
        )
        check_dates(
            imprt, entity_station, selected_fields.get("date_min"), selected_fields.get("date_max")
        )
        check_depths(
            imprt,
            entity_station,
            selected_fields.get("depth_min"),
            selected_fields.get("depth_max"),
        )
        if "WKT" in selected_fields:
            check_is_valid_geometry(
                imprt, entity_station, selected_fields["WKT"], fields["geom_4326"]
            )
        # TODO@TestImportsOcchab.test_import_valid_file: remove this check
        if current_app.config["IMPORT"]["ID_AREA_RESTRICTION"]:
            check_geometry_outside(
                imprt,
                entity_station,
                fields["geom_local"],
                id_area=current_app.config["IMPORT"]["ID_AREA_RESTRICTION"],
            )

        # Checks before these lines create errors for each rows, including for duplicate
        # station, whereas checks after create errors only for first row of duplicate station.
        if "id_station_source" in selected_fields:
            disable_duplicated_rows(
                imprt,
                entity_station,
                selected_fields,
                selected_fields["id_station_source"],
            )
        if "unique_id_sinp_station" in selected_fields:
            disable_duplicated_rows(
                imprt,
                entity_station,
                selected_fields,
                selected_fields["unique_id_sinp_station"],
            )

        # The check existing_uuid should preferably run before generating missing UUID
        # for performance reason (this avoid looking for generated values in dest table).
        if "unique_id_sinp_station" in selected_fields:
            check_existing_uuid(
                imprt,
                entity_station,
                selected_fields["unique_id_sinp_station"],
                skip=True,  # TODO add config parameter
            )

        if current_app.config["IMPORT"]["DEFAULT_GENERATE_MISSING_UUID"]:
            # This generate UUID for all rows, not only for station!
            generate_missing_uuid_for_id_origin(
                imprt,
                fields["unique_id_sinp_station"],
                id_origin_field=fields["id_station_source"],
            )
            if "id_station_source" in selected_fields:
                # UUID have been already generated where id_station_source is defined,
                # generate UUID only when there are no id_station_source.
                whereclause = transient_table.c[
                    selected_fields["id_station_source"].source_field
                ].is_(None)
            else:
                whereclause = None
            generate_missing_uuid(
                imprt,
                entity_station,
                fields["unique_id_sinp_station"],
                whereclause=whereclause,
            )
        else:
            check_mandatory_field(imprt, entity_station, fields["unique_id_sinp_station"])

    @staticmethod
    def check_transient_data(task, logger, imprt: TImports):
        task.update_state(state="PROGRESS", meta={"progress": 0})
        entity_station, _ = get_occhab_entities()

        fields, selected_fields, _ = get_mapping_data(imprt, entity_station)
        init_rows_validity(imprt)
        task.update_state(state="PROGRESS", meta={"progress": 0.05})
        check_orphan_rows(imprt)
        task.update_state(state="PROGRESS", meta={"progress": 0.1})

        # We first check station consistency in order to avoid checking
        # incoherent station data
        OcchabImportActions.check_station_consistency(imprt)

        # We run station & habitat dataframe checks before SQL checks in order to avoid
        # check_types overriding generated values during SQL checks.
        OcchabImportActions.check_station_dataframe(imprt)
        OcchabImportActions.check_habitat_dataframe(imprt)

        OcchabImportActions.check_station_sql(imprt)
        OcchabImportActions.check_habitat_sql(imprt)

        task.update_state(state="PROGRESS", meta={"progress": 1})

    @staticmethod
    def import_data_to_destination(imprt: TImports) -> None:
        transient_table = imprt.destination.get_transient_table()
        entities = {
            entity.code: entity
            for entity in (
                db.session.scalars(
                    sa.select(Entity)
                    .where(Entity.destination == imprt.destination)
                    .options(joinedload(Entity.fields))
                    .order_by(Entity.order)
                )
                .unique()
                .all()
            )
        }
        entity_station = entities["station"]
        entity_habitat = entities["habitat"]

        #     """
        #     We need the id_station in transient table to use it when inserting habitats.
        #     I have tried to use RETURNING after inserting the stations to update transient table, roughly:
        #     WITH (INSERT pr_occhab.t_stations FROM SELECT ... RETURNING transient_table.line_no, id_station) AS insert_cte
        #     UPDATE transient_table SET id_station = insert_cte.id_station WHERE transient_table.line_no = insert_cte.line_no
        #     but RETURNING clause can only contains columns from INSERTed table so we can not return line_no.
        #     Consequently, we generate id_station directly in transient table before inserting the stations.
        #     """
        generate_entity_id(
            imprt, entity_station, "pr_occhab", "t_stations", "unique_id_sinp_station", "id_station"
        )
        generate_entity_id(
            imprt, entity_habitat, "pr_occhab", "t_habitats", "unique_id_sinp_hab", "id_habitat"
        )

        set_parent_id_from_line_no(
            imprt,
            entity=entity_habitat,
            parent_line_no_field_name="station_line_no",
            parent_id_field_name="id_station",
        )

        for entity in entities.values():

            fields = {
                ef.field.name_field: ef.field for ef in entity.fields if ef.field.dest_field != None
            }
            insert_fields = {fields["id_station"]}
            for field_name, mapping in imprt.fieldmapping.items():
                if field_name not in fields:  # not a destination field
                    continue
                field = fields[field_name]
                column_src = mapping.get("column_src", None)
                if field.multi:
                    # TODO@TestImportsOcchab.test_import_valid_file: add testcase
                    if not set(column_src).isdisjoint(imprt.columns):
                        insert_fields |= {field}
                else:
                    if (
                        column_src in imprt.columns
                        or mapping.get("constant_value", None) is not None
                    ):
                        insert_fields |= {field}
            if entity.code == "station":
                insert_fields |= {fields["id_dataset"]}
                insert_fields |= {fields["geom_4326"], fields["geom_local"]}
                # TODO@TestImportsOcchab.test_import_valid_file: add testcase
                if imprt.fieldmapping.get("altitudes_generate", False):
                    insert_fields |= {fields["altitude_min"], fields["altitude_max"]}
                # The field is either generated, or marked as mandatory
                insert_fields |= {fields["unique_id_sinp_station"]}
            elif entity.code == "habitat":  # habitat
                # These fields are associated with habitat as necessary to find the corresponding station,
                # but they are not inserted in habitat destination so we need to manually remove them.
                insert_fields -= {fields["unique_id_sinp_station"], fields["id_station_source"]}
                # The field is either generated, or marked as mandatory
                insert_fields |= {fields["unique_id_sinp_habitat"]}
            names = ["id_import"] + [field.dest_field for field in insert_fields]
            select_stmt = (
                sa.select(
                    sa.literal(imprt.id_import).label("id_import"),
                    *[transient_table.c[field.dest_field] for field in insert_fields],
                )
                .where(transient_table.c.id_import == imprt.id_import)
                .where(transient_table.c[entity.validity_column] == True)
                .where(transient_table.c.id_station.is_not(None))
            )
            destination_table = entity.get_destination_table()
            batch_size = current_app.config["IMPORT"]["INSERT_BATCH_SIZE"]
            batch_count = ceil(imprt.source_count / batch_size)
            row_count = 0
            for batch in range(batch_count):
                min_line_no = batch * batch_size
                max_line_no = (batch + 1) * batch_size
                insert_stmt = sa.insert(destination_table).from_select(
                    names=names,
                    select=select_stmt.filter(
                        transient_table.c["line_no"] >= min_line_no,
                        transient_table.c["line_no"] < max_line_no,
                    ),
                )
                row_count += db.session.execute(insert_stmt).rowcount
                yield (batch + 1) / batch_count
            imprt.statistics.update({f"{entity.code}_count": row_count})

    @staticmethod
    def report_plot(imprt: TImports) -> StandaloneEmbedJson:
        return distribution_plot(imprt)

    @staticmethod
    def compute_bounding_box(imprt: TImports):

        return compute_bounding_box(
            imprt=imprt,
            geom_entity_code="station",
            geom_4326_field_name__transient="geom_4326",
            geom_4326_field_name__destination="geom_4326",
            child_entity_code="habitat",
        )
