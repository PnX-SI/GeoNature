from datetime import datetime

from flask import current_app
import sqlalchemy as sa
from sqlalchemy import func, select, delete
from sqlalchemy.dialects.postgresql import array_agg, aggregate_order_by
from celery.utils.log import get_task_logger

from geonature.utils.env import db
from geonature.utils.celery import celery_app

from geonature.core.notifications.utils import dispatch_notifications

from geonature.core.imports.models import BibFields, Entity, EntityField, TImports
from geonature.core.imports.checks.sql import init_rows_validity, check_orphan_rows


logger = get_task_logger(__name__)


@celery_app.task(bind=True)
def do_import_checks(self, import_id):
    """
    Verify the import data.

    Parameters
    ----------
    import_id : int
        The ID of the import to verify.
    """
    logger.info(f"Starting verification of import {import_id}.")
    imprt = db.session.get(TImports, import_id)
    if imprt is None or imprt.task_id != self.request.id:
        logger.warning("Task cancelled, doing nothing.")
        return

    imprt.destination.actions.check_transient_data(self, logger, imprt)

    self.update_state(state="PROGRESS", meta={"progress": 1})

    imprt = db.session.get(TImports, import_id, with_for_update={"of": TImports})
    if imprt is None or imprt.task_id != self.request.id:
        logger.warning("Task cancelled, rollback changes.")
        db.session.rollback()
    else:
        logger.info("All done, committing…")
        transient_table = imprt.destination.get_transient_table()
        imprt.processed = True
        imprt.task_id = None
        stmt = (
            select(
                array_agg(aggregate_order_by(transient_table.c.line_no, transient_table.c.line_no))
            )
            .where(
                sa.or_(*[transient_table.c[v] == False for v in imprt.destination.validity_columns])
            )
            .where(transient_table.c.id_import == imprt.id_import)
        )
        imprt.erroneous_rows = db.session.execute(stmt).scalar()
        db.session.commit()


@celery_app.task(bind=True)
def do_import_in_destination(self, import_id):
    """
    Insert valid transient data into the destination of an import.

    Parameters
    ----------
    import_id : int
        The ID of the import to insert data into the destination.
    """
    logger.info(f"Starting insertion in destination of import {import_id}.")
    imprt = db.session.get(TImports, import_id)
    if imprt is None or imprt.task_id != self.request.id:
        logger.warning("Task cancelled, doing nothing.")
        return
    transient_table = imprt.destination.get_transient_table()

    # Copy valid transient data to destination
    imprt.destination.actions.import_data_to_destination(imprt)

    count_entities = 0
    for entity in (
        Entity.query.filter_by(destination=imprt.destination).order_by(Entity.order).all()
    ):
        fields = BibFields.query.where(
            BibFields.entities.any(EntityField.entity == entity),
            BibFields.dest_field != None,
            BibFields.name_field.in_(imprt.fieldmapping.keys()),
        ).all()
        columns_to_count_unique_entities = [
            transient_table.c[field.dest_column] for field in fields
        ]
        n_valid_data = db.session.execute(
            select(func.count(func.distinct(*columns_to_count_unique_entities)))
            .select_from(transient_table)
            .where(transient_table.c.id_import == imprt.id_import)
            .where(transient_table.c[entity.validity_column] == True)
        ).scalar()
        count_entities += n_valid_data
    imprt.import_count = count_entities

    # Clear transient data
    stmt = delete(transient_table).where(transient_table.c.id_import == imprt.id_import)
    db.session.execute(stmt)
    imprt.loaded = False

    imprt = db.session.get(TImports, import_id, with_for_update={"of": TImports})
    if imprt is None or imprt.task_id != self.request.id:
        logger.warning("Task cancelled, rollback changes.")
        db.session.rollback()
        return

    logger.info("All done, committing…")
    imprt.task_id = None
    imprt.date_end_import = datetime.now()

    # Send element to notification system
    notify_import_done(imprt)

    db.session.commit()


# Send notification
def notify_import_done(imprt: TImports):
    """
    Notify the authors of an import that it has finished.

    Parameters
    ----------
    imprt : TImports
        The import that has finished.

    """
    id_authors = [author.id_role for author in imprt.authors]
    dispatch_notifications(
        code_categories=["IMPORT-DONE%"],
        id_roles=id_authors,
        title="Import terminé",
        url=(
            current_app.config["URL_APPLICATION"]
            + f"/#/import/{imprt.destination.code}/{imprt.id_import}/report"
        ),
        context={
            "import": imprt,
            "destination": imprt.destination,
            "url_notification_rules": current_app.config["URL_APPLICATION"]
            + "/#/notification/rules",
        },
    )
