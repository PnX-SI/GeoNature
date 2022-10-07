from os import environ
from importlib import import_module

from flask_sqlalchemy import SQLAlchemy


db_path = environ.get("FLASK_SQLALCHEMY_DB")
if db_path and db_path != f"{__name__}.db":
    db_module_name, db_object_name = db_path.rsplit(".", 1)
    db_module = import_module(db_module_name)
    db = getattr(db_module, db_object_name)
else:
    db = SQLAlchemy()
    environ["FLASK_SQLALCHEMY_DB"] = f"{__name__}.db"


__all__ = ["db"]
