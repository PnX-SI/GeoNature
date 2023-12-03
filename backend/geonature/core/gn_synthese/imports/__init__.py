from math import ceil

from flask import current_app
import sqlalchemy as sa
from sqlalchemy import func, distinct

from geonature.utils.env import db
from geonature.utils.sentry import start_sentry_child
from geonature.core.gn_commons.models import TModules
from geonature.core.gn_synthese.models import Synthese, TSources

from gn_module_import.models import BibFields
from gn_module_import.utils import (
    mark_all_rows_as_invalid,
    load_transient_data_in_dataframe,
    update_transient_data_from_dataframe,
)
from gn_module_import.checks.dataframe import run_all_checks
from gn_module_import.checks.dataframe.geography import set_the_geom_column


def check_transient_data(task, logger, imprt):
    task.update_state(state="PROGRESS", meta={"progress": 0})

    selected_fields_names = [
        field_name
        for field_name, source_field in imprt.fieldmapping.items()
        if source_field in imprt.columns
    ]
    selected_fields = BibFields.query.filter(
        BibFields.destination == imprt.destination,  # FIXME by entities?
        BibFields.name_field.in_(selected_fields_names),
    ).all()

    fields = {
        field.name_field: field
        for field in selected_fields
        if (  # handled in SQL, exclude from dataframe
            field.source_field is not None and field.mnemonique is None
        )
    }

    with start_sentry_child(op="check.df", description="mark_all"):
        mark_all_rows_as_invalid(imprt)
    task.update_state(state="PROGRESS", meta={"progress": 0.1})

    batch_size = current_app.config["IMPORT"]["DATAFRAME_BATCH_SIZE"]
    batch_count = ceil(imprt.source_count / batch_size)

    def update_batch_progress(batch, step):
        start = 0.1
        end = 0.4
        step_count = 4
        progress = start + ((batch + 1) / batch_count) * (step / step_count) * (end - start)
        task.update_state(state="PROGRESS", meta={"progress": progress})

    for batch in range(batch_count):
        offset = batch * batch_size
        batch_fields = fields.copy()
        # Checks on dataframe
        logger.info(f"[{batch+1}/{batch_count}] Loading import data in dataframe…")
        with start_sentry_child(op="check.df", description="load dataframe"):
            df = load_transient_data_in_dataframe(imprt, batch_fields, offset, batch_size)
        update_batch_progress(batch, 1)
        logger.info(f"[{batch+1}/{batch_count}] Running dataframe checks…")
        with start_sentry_child(op="check.df", description="run all checks"):
            run_all_checks(imprt, batch_fields, df)
        update_batch_progress(batch, 2)
        logger.info(f"[{batch+1}/{batch_count}] Completing geometric columns…")
        with start_sentry_child(op="check.df", description="set geom column"):
            set_the_geom_column(imprt, batch_fields, df)
        update_batch_progress(batch, 3)
        logger.info(f"[{batch+1}/{batch_count}] Updating import data from dataframe…")
        with start_sentry_child(op="check.df", description="save dataframe"):
            update_transient_data_from_dataframe(imprt, batch_fields, df)
        update_batch_progress(batch, 4)

    fields = batch_fields  # retrive fields added during dataframe checks
    fields.update({field.name_field: field for field in selected_fields})

    from gn_module_import.checks.sql import (
        do_nomenclatures_mapping,
        check_nomenclatures,
        complete_others_geom_columns,
        check_cd_nom,
        check_cd_hab,
        set_altitudes,
        set_uuid,
        check_duplicates_source_pk,
        check_dates,
        check_altitudes,
        check_depths,
        check_digital_proof_urls,
        check_geography_outside,
        check_is_valid_geography,
    )

    # Checks in SQL
    sql_checks = [
        complete_others_geom_columns,
        do_nomenclatures_mapping,
        check_nomenclatures,
        check_cd_nom,
        check_cd_hab,
        check_duplicates_source_pk,
        set_altitudes,
        check_altitudes,
        set_uuid,
        check_dates,
        check_depths,
        check_digital_proof_urls,
        check_is_valid_geography,
        check_geography_outside,
    ]
    with start_sentry_child(op="check.sql", description="run all checks"):
        for i, check in enumerate(sql_checks):
            logger.info(f"Running SQL check '{check.__name__}'…")
            with start_sentry_child(op="check.sql", description=check.__name__):
                check(imprt, fields)
            progress = 0.4 + ((i + 1) / len(sql_checks)) * 0.6
            task.update_state(state="PROGRESS", meta={"progress": progress})


def import_data_to_synthese(imprt):
    module = TModules.query.filter_by(module_code="IMPORT").one()
    name_source = f"Import(id={imprt.id_import})"
    source = TSources.query.filter_by(module=module, name_source=name_source).one_or_none()
    if source is None:
        entity_source_pk_field = BibFields.query.filter_by(
            name_field="entity_source_pk_value"
        ).one()
        source = TSources(
            module=module,
            name_source=name_source,
            desc_source=f"Imported data from import module (id={imprt.id_import})",
            entity_source_pk_field=entity_source_pk_field.dest_field,
        )
        db.session.add(source)
        db.session.flush()  # force id_source definition
    transient_table = imprt.destination.get_transient_table()
    generated_fields = {
        "datetime_min",
        "datetime_max",
        "the_geom_4326",
        "the_geom_local",
        "the_geom_point",
        "id_area_attachment",
    }
    if imprt.fieldmapping.get(
        "unique_id_sinp_generate", current_app.config["IMPORT"]["DEFAULT_GENERATE_MISSING_UUID"]
    ):
        generated_fields |= {"unique_id_sinp"}
    if imprt.fieldmapping.get("altitudes_generate", False):
        generated_fields |= {"altitude_min", "altitude_max"}
    fields = BibFields.query.filter(
        BibFields.dest_field != None,
        BibFields.name_field.in_(imprt.fieldmapping.keys() | generated_fields),
    ).all()
    select_stmt = (
        sa.select(
            [transient_table.c[field.dest_field] for field in fields]
            + [
                sa.literal(source.id_source),
                sa.literal(source.module.id_module),
                sa.literal(imprt.id_dataset),
                sa.literal("I"),
            ]
        )
        .where(transient_table.c.id_import == imprt.id_import)
        .where(transient_table.c.valid == True)
    )
    names = [field.dest_field for field in fields] + [
        "id_source",
        "id_module",
        "id_dataset",
        "last_action",
    ]
    insert_stmt = sa.insert(Synthese).from_select(
        names=names,
        select=select_stmt,
    )
    db.session.execute(insert_stmt)
    imprt.statistics = {
        "taxa_count": (
            db.session.query(func.count(distinct(Synthese.cd_nom)))
            .filter_by(source=source)
            .scalar()
        )
    }


def remove_data_from_synthese(imprt):
    source = TSources.query.filter(
        TSources.module.has(TModules.module_code == "IMPORT"),
        TSources.name_source == f"Import(id={imprt.id_import})",
    ).one_or_none()
    if source is not None:
        with start_sentry_child(op="task", description="clean imported data"):
            Synthese.query.filter(Synthese.source == source).delete()
        db.session.delete(source)
