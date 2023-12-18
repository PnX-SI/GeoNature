from datetime import datetime

from flask import current_app
import sqlalchemy as sa
from sqlalchemy import func, select, delete
from sqlalchemy.dialects.postgresql import array_agg, aggregate_order_by
from celery.utils.log import get_task_logger

from geonature.utils.env import db
from geonature.utils.celery import celery_app

from geonature.core.notifications.utils import dispatch_notifications

from geonature.core.imports.models import TImports
from geonature.core.imports.checks.sql import init_rows_validity, check_orphan_rows


logger = get_task_logger(__name__)


@celery_app.task(bind=True)
def do_import_checks(self, import_id):
    logger.info(f"Starting verification of import {import_id}.")
    imprt = db.session.get(TImports, import_id)
    if imprt is None or imprt.task_id != self.request.id:
        logger.warning("Task cancelled, doing nothing.")
        return

    self.update_state(state="PROGRESS", meta={"progress": 0})
    init_rows_validity(imprt)
    self.update_state(state="PROGRESS", meta={"progress": 0.05})
    check_orphan_rows(imprt)
    self.update_state(state="PROGRESS", meta={"progress": 0.1})

    imprt.destination.check_transient_data(self, logger, imprt)

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
                sa.or_(
                    *[transient_table.c[v] == False for v in imprt.destination.validity_columns]
                )
            )
            .where(transient_table.c.id_import == imprt.id_import)
        )
        imprt.erroneous_rows = db.session.execute(stmt).scalar()
        db.session.commit()


@celery_app.task(bind=True)
def do_import_in_destination(self, import_id):
    logger.info(f"Starting insertion in destination of import {import_id}.")
    imprt = db.session.get(TImports, import_id)
    if imprt is None or imprt.task_id != self.request.id:
        logger.warning("Task cancelled, doing nothing.")
        return
    transient_table = imprt.destination.get_transient_table()

    # Copy valid transient data to destination
    imprt.destination.import_data_to_destination(imprt)

    imprt.import_count = db.session.execute(
        db.select(func.count())
        .select_from(transient_table)
        .where(transient_table.c.id_import == imprt.id_import)
        .where(sa.or_(*[transient_table.c[v] == True for v in imprt.destination.validity_columns]))
    ).scalar()

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
def notify_import_done(imprt):
    id_authors = [author.id_role for author in imprt.authors]
    dispatch_notifications(
        code_categories=["IMPORT-DONE%"],
        id_roles=id_authors,
        title="Import terminé",
        url=(current_app.config["URL_APPLICATION"] + f"/#/import/{imprt.id_import}/report"),
        context={
            "import": imprt,
            "destination": imprt.destination,
            "url_notification_rules": current_app.config["URL_APPLICATION"]
            + "/#/notification/rules",
        },
    )
