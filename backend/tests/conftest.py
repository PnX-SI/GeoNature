import os, logging

import psycopg2

from geonature import create_app
from geonature.utils.config import config


def pytest_sessionstart(session):
    """before session.main() is called."""
    app = create_app()
    app.config["TESTING"] = True
    # push the app_context
    ctx = app.app_context()
    ctx.push()
    logging.disable(logging.DEBUG)

    # setup test data
    execute_script("delete_sample_data.sql")
    execute_script("sample_data.sql")


def execute_script(file_name):
    """
    Execute a script to set or delete sample data before test
    """
    conn = psycopg2.connect(config["SQLALCHEMY_DATABASE_URI"])
    cur = conn.cursor()
    sql_file = os.path.join(os.path.dirname(os.path.abspath(__file__)), file_name)
    cur.execute(open(sql_file, "r").read())
    conn.commit()
    cur.close()
    conn.close()
