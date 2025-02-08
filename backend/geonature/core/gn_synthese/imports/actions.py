import typing
from math import ceil

import sqlalchemy as sa
from apptax.taxonomie.models import Taxref
from bokeh.embed.standalone import StandaloneEmbedJson
from flask import current_app
from geonature.core.gn_commons.models import TModules
from geonature.core.gn_synthese.models import Synthese, TSources
from geonature.core.imports.actions import (
    ImportActions,
    ImportInputUrl,
    ImportStatisticsLabels,
)
from geonature.core.imports.checks.dataframe import (
    check_counts,
    check_datasets,
    check_geometry,
    check_required_values,
    check_types,
    concat_dates,
)
from geonature.core.imports.checks.sql import (
    check_altitudes,
    check_cd_hab,
    check_cd_nom,
    check_dates,
    check_depths,
    check_digital_proof_urls,
    check_duplicate_source_pk,
    check_duplicate_uuid,
    check_existing_uuid,
    check_geometry_outside,
    check_is_valid_geometry,
    check_nomenclature_blurring,
    check_nomenclature_exist_proof,
    check_nomenclature_source_status,
    check_orphan_rows,
    convert_geom_columns,
    do_nomenclatures_mapping,
    generate_altitudes,
    generate_missing_uuid,
    init_rows_validity,
    set_geom_point,
)
from geonature.core.imports.models import BibFields, Entity, EntityField, TImports
from geonature.core.imports.utils import (
    compute_bounding_box,
    load_transient_data_in_dataframe,
    update_transient_data_from_dataframe,
)
from geonature.utils.env import db
from geonature.utils.sentry import start_sentry_child
from sqlalchemy import distinct, func, select

from .geo import set_geom_columns_from_area_codes
from .plot import taxon_distribution_plot


class SyntheseImportActions(ImportActions):

    @staticmethod
    def statistics_labels() -> typing.List[ImportStatisticsLabels]:
        return [
            {"key": "import_count", "value": "Nombre d'observations importées"},
            {"key": "taxa_count", "value": "Nombre de taxons"},
        ]

    @staticmethod
    def preprocess_transient_data(imprt: TImports, df) -> set:
        pass

    @staticmethod
    def check_transient_data(task, logger, imprt: TImports):
        entity = db.session.execute(
            select(Entity).where(Entity.destination == imprt.destination)
        ).scalar_one()  # Observation

        entity_bib_fields = db.session.scalars(
            sa.select(BibFields)
            .where(BibFields.destination == imprt.destination)
            .options(sa.orm.selectinload(BibFields.entities).joinedload(EntityField.entity))
        ).all()

        fields = {field.name_field: field for field in entity_bib_fields}
        # Note: multi fields are not selected here, and therefore, will be not loaded in dataframe or checked in SQL.
        # Fix this code (see import function) if you want to operate on multi fields data.
        selected_fields = {
            field_name: fields[field_name]
            for field_name, source_field in imprt.fieldmapping.items()
            if source_field.get("column_src", None) in imprt.columns
            or source_field.get("default_value", None) is not None
        }
        init_rows_validity(imprt)
        task.update_state(state="PROGRESS", meta={"progress": 0.05})
        check_orphan_rows(imprt)
        task.update_state(state="PROGRESS", meta={"progress": 0.1})

        batch_size = current_app.config["IMPORT"]["DATAFRAME_BATCH_SIZE"]
        batch_count = ceil(imprt.source_count / batch_size)

        def update_batch_progress(batch, step):
            start = 0.1
            end = 0.4
            step_count = 8
            progress = start + ((batch + step / step_count) / batch_count) * (end - start)
            task.update_state(state="PROGRESS", meta={"progress": progress})

        source_cols = [
            field.source_column
            for field in selected_fields.values()
            if field.mandatory or (field.source_field is not None and field.mnemonique is None)
        ]

        for batch in range(batch_count):
            offset = batch * batch_size
            updated_cols = set()

            logger.info(f"[{batch+1}/{batch_count}] Loading import data in dataframe…")
            with start_sentry_child(op="check.df", description="load dataframe"):
                df = load_transient_data_in_dataframe(
                    imprt, entity, source_cols, offset=offset, limit=batch_size
                )
            update_batch_progress(batch, 1)

            logger.info(f"[{batch+1}/{batch_count}] Concat dates…")
            with start_sentry_child(op="check.df", description="concat dates"):
                updated_cols |= concat_dates(
                    df,
                    fields["datetime_min"].dest_field,
                    fields["datetime_max"].dest_field,
                    fields["date_min"].source_field,
                    fields["date_max"].source_field,
                    fields["hour_min"].source_field,
                    fields["hour_max"].source_field,
                )
            update_batch_progress(batch, 2)

            logger.info(f"[{batch+1}/{batch_count}] Check required values…")
            with start_sentry_child(op="check.df", description="check required values"):
                updated_cols |= check_required_values(imprt, entity, df, fields)
            update_batch_progress(batch, 3)

            logger.info(f"[{batch+1}/{batch_count}] Check types…")
            with start_sentry_child(op="check.df", description="check types"):
                updated_cols |= check_types(imprt, entity, df, fields)
            update_batch_progress(batch, 4)

            logger.info(f"[{batch+1}/{batch_count}] Check dataset rows")
            with start_sentry_child(op="check.df", description="check datasets rows"):
                updated_cols |= check_datasets(
                    imprt,
                    entity,
                    df,
                    uuid_field=fields["unique_dataset_id"],
                    id_field=fields["id_dataset"],
                    module_code="SYNTHESE",
                )
            update_batch_progress(batch, 5)
            logger.info(f"[{batch+1}/{batch_count}] Check geography…")
            with start_sentry_child(op="check.df", description="set geography"):
                updated_cols |= check_geometry(
                    imprt,
                    entity,
                    df,
                    file_srid=imprt.srid,
                    geom_4326_field=fields["the_geom_4326"],
                    geom_local_field=fields["the_geom_local"],
                    wkt_field=fields["WKT"],
                    latitude_field=fields["latitude"],
                    longitude_field=fields["longitude"],
                    codecommune_field=fields["codecommune"],
                    codemaille_field=fields["codemaille"],
                    codedepartement_field=fields["codedepartement"],
                )
            update_batch_progress(batch, 6)

            logger.info(f"[{batch+1}/{batch_count}] Check counts…")
            with start_sentry_child(op="check.df", description="check count"):
                updated_cols |= check_counts(
                    imprt,
                    entity,
                    df,
                    fields["count_min"],
                    fields["count_max"],
                    default_count=current_app.config["IMPORT"]["DEFAULT_COUNT_VALUE"],
                )
            update_batch_progress(batch, 7)

            logger.info(f"[{batch+1}/{batch_count}] Updating import data from dataframe…")
            with start_sentry_child(op="check.df", description="save dataframe"):
                update_transient_data_from_dataframe(imprt, entity, updated_cols, df)
            update_batch_progress(batch, 8)

        # Checks in SQL
        convert_geom_columns(
            imprt,
            entity,
            geom_4326_field=fields["the_geom_4326"],
            geom_local_field=fields["the_geom_local"],
        )
        set_geom_columns_from_area_codes(
            imprt,
            entity,
            geom_4326_field=fields["the_geom_4326"],
            geom_local_field=fields["the_geom_local"],
            codecommune_field=fields["codecommune"],
            codemaille_field=fields["codemaille"],
            codedepartement_field=fields["codedepartement"],
        )
        set_geom_point(
            imprt=imprt,
            entity=entity,
            geom_4326_field=fields["the_geom_4326"],
            geom_point_field=fields["the_geom_point"],
        )
        # All valid rows should have a geom as verified in dataframe check 'check_geometry'

        do_nomenclatures_mapping(
            imprt,
            entity,
            {
                field_name: fields[field_name]
                for field_name, mapping in imprt.fieldmapping.items()
                if field_name in fields
                and (
                    mapping.get("column_src", None) in imprt.columns
                    or mapping.get("default_value") is not None
                )
            },
            fill_with_defaults=current_app.config["IMPORT"][
                "FILL_MISSING_NOMENCLATURE_WITH_DEFAULT_VALUE"
            ],
        )

        if current_app.config["IMPORT"]["CHECK_EXIST_PROOF"]:
            check_nomenclature_exist_proof(
                imprt,
                entity,
                fields["id_nomenclature_exist_proof"],
                selected_fields.get("digital_proof"),
                selected_fields.get("non_digital_proof"),
            )
        if current_app.config["IMPORT"]["CHECK_PRIVATE_JDD_BLURING"]:
            check_nomenclature_blurring(
                imprt,
                entity,
                fields["id_nomenclature_blurring"],
                fields["id_dataset"],
            )
        if current_app.config["IMPORT"]["CHECK_REF_BIBLIO_LITTERATURE"]:
            check_nomenclature_source_status(
                imprt, entity, fields["id_nomenclature_source_status"], fields["reference_biblio"]
            )

        if "cd_nom" in selected_fields:
            check_cd_nom(
                imprt,
                entity,
                selected_fields["cd_nom"],
                list_id=current_app.config["IMPORT"].get("ID_LIST_TAXA_RESTRICTION", None),
            )
        if "cd_hab" in selected_fields:
            check_cd_hab(imprt, entity, selected_fields["cd_hab"])
        if "entity_source_pk_value" in selected_fields:
            check_duplicate_source_pk(imprt, entity, selected_fields["entity_source_pk_value"])

        if imprt.fieldmapping.get("altitudes_generate", False):
            generate_altitudes(
                imprt, fields["the_geom_local"], fields["altitude_min"], fields["altitude_max"]
            )
        check_altitudes(
            imprt, entity, selected_fields.get("altitude_min"), selected_fields.get("altitude_max")
        )

        if "unique_id_sinp" in selected_fields:
            check_duplicate_uuid(imprt, entity, selected_fields["unique_id_sinp"])
            if current_app.config["IMPORT"]["PER_DATASET_UUID_CHECK"]:
                check_existing_uuid(
                    imprt,
                    entity,
                    selected_fields["unique_id_sinp"],
                    id_dataset_field=fields["id_dataset"],
                )
            else:
                check_existing_uuid(
                    imprt,
                    entity,
                    selected_fields["unique_id_sinp"],
                )
        if imprt.fieldmapping.get(
            "unique_id_sinp_generate",
            current_app.config["IMPORT"]["DEFAULT_GENERATE_MISSING_UUID"],
        ):
            generate_missing_uuid(imprt, entity, fields["unique_id_sinp"])
        check_dates(imprt, entity, fields["datetime_min"], fields["datetime_max"])
        check_depths(
            imprt, entity, selected_fields.get("depth_min"), selected_fields.get("depth_max")
        )
        if "digital_proof" in selected_fields:
            check_digital_proof_urls(imprt, entity, selected_fields["digital_proof"])

        if "WKT" in selected_fields:
            check_is_valid_geometry(imprt, entity, selected_fields["WKT"], fields["the_geom_4326"])
        if current_app.config["IMPORT"]["ID_AREA_RESTRICTION"]:
            check_geometry_outside(
                imprt,
                entity,
                fields["the_geom_local"],
                id_area=current_app.config["IMPORT"]["ID_AREA_RESTRICTION"],
            )

    @staticmethod
    def import_data_to_destination(imprt: TImports) -> None:
        module = db.session.execute(
            sa.select(TModules).filter_by(module_code="IMPORT")
        ).scalar_one()
        name_source = "Import"
        source = db.session.execute(
            sa.select(TSources).filter_by(module=module, name_source=name_source)
        ).scalar_one_or_none()
        transient_table = imprt.destination.get_transient_table()

        destination_bib_fields = db.session.scalars(
            sa.select(BibFields).where(
                BibFields.destination == imprt.destination, BibFields.dest_field != None
            )
        ).all()
        fields = {field.name_field: field for field in destination_bib_fields}

        # Construct the exact list of required fields to copy from transient table to synthese
        # This list contains generated fields, and selected fields (including multi fields).
        insert_fields = {
            fields["datetime_min"],
            fields["datetime_max"],
            fields["the_geom_4326"],
            fields["the_geom_local"],
            fields["the_geom_point"],
            fields["id_area_attachment"],  # XXX sure?
            fields["id_dataset"],
        }
        if imprt.fieldmapping.get(
            "unique_id_sinp_generate",
            current_app.config["IMPORT"]["DEFAULT_GENERATE_MISSING_UUID"],
        ):
            insert_fields |= {fields["unique_id_sinp"]}
        if imprt.fieldmapping.get("altitudes_generate", False):
            insert_fields |= {fields["altitude_min"], fields["altitude_max"]}

        for field_name, source_field in imprt.fieldmapping.items():
            if field_name not in fields:  # not a destination field
                continue
            field = fields[field_name]
            column_src = source_field.get("column_src", None)
            if field.multi:
                if not set(column_src).isdisjoint(imprt.columns):
                    insert_fields |= {field}
            else:
                if (
                    column_src in imprt.columns
                    or source_field.get("default_value", None) is not None
                ):
                    insert_fields |= {field}

        select_stmt = (
            sa.select(
                *[transient_table.c[field.dest_field] for field in insert_fields],
                sa.literal(source.id_source),
                sa.literal(source.module.id_module),
                sa.literal(imprt.id_import),
                sa.literal("I"),
            )
            .where(transient_table.c.id_import == imprt.id_import)
            .where(transient_table.c.valid == True)
        )
        names = [field.dest_field for field in insert_fields] + [
            "id_source",
            "id_module",
            "id_import",
            "last_action",
        ]
        batch_size = current_app.config["IMPORT"]["INSERT_BATCH_SIZE"]
        batch_count = ceil(imprt.source_count / batch_size)
        for batch in range(batch_count):
            min_line_no = batch * batch_size
            max_line_no = (batch + 1) * batch_size
            insert_stmt = sa.insert(Synthese).from_select(
                names=names,
                select=select_stmt.filter(
                    transient_table.c["line_no"] >= min_line_no,
                    transient_table.c["line_no"] < max_line_no,
                ),
            )
            db.session.execute(insert_stmt)
            yield (batch + 1) / batch_count
        insert_stmt = sa.insert(Synthese).from_select(
            names=names,
            select=select_stmt,
        )

        # TODO: Improve this
        imprt.statistics = {
            "taxa_count": (
                db.session.scalar(
                    sa.select(func.count(distinct(Synthese.cd_nom))).where(
                        Synthese.id_import == imprt.id_import
                    )
                )
            ),
        }

    @staticmethod
    def remove_data_from_destination(imprt: TImports) -> None:
        with start_sentry_child(op="task", description="clean imported data"):
            db.session.execute(sa.delete(Synthese).where(Synthese.id_import == imprt.id_import))

    @staticmethod
    def report_plot(imprt: TImports) -> StandaloneEmbedJson:
        return taxon_distribution_plot(imprt)

    @staticmethod
    def compute_bounding_box(imprt: TImports):
        return compute_bounding_box(imprt, "observation", "the_geom_4326")
