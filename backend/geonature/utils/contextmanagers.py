from contextlib import contextmanager
import sqlalchemy as sa

from geonature.utils.env import db


@contextmanager
def trigger_disabled(table, trigger):
    db.session.execute(sa.text(f"ALTER TABLE {table} DISABLE TRIGGER {trigger}"))
    yield
    db.session.execute(sa.text(f"ALTER TABLE {table} ENABLE TRIGGER {trigger}"))
