import time
import logging

import pytest
import pandas
from sqlalchemy import event

from geonature.utils.env import db
from .benchmark_generator import CLater

logging.basicConfig()
logger = logging.getLogger("logger-name")
logger.setLevel(logging.DEBUG)


@pytest.fixture(scope="class")
def activate_profiling_sql():
    """
    Fixture to activate profiling for SQL queries and storing query's statements and execution times in a csv file.
    """

    results_file = "sql_queries.csv"
    df = pandas.DataFrame([], columns=["Query", "Total Time [s.]"])
    df.to_csv(results_file, mode="a", header=True, index=None, sep=";")

    # @event.listens_for(Engine, "before_cursor_execute")
    def before_cursor_execute(conn, cursor, statement, parameters, context, executemany):
        conn.info.setdefault("query_start_time", []).append(time.time())
        logger.debug("Start Query: %s" % statement)

    # @event.listens_for(Engine, "after_cursor_execute")
    def after_cursor_execute(conn, cursor, statement, parameters, context, executemany):
        total = time.time() - conn.info["query_start_time"].pop(-1)
        logger.debug("Query Complete!")
        logger.debug("Total Time: %f" % total)
        if statement.startswith("SELECT"):
            df = pandas.DataFrame([[statement, total]], columns=["Query", "Total Time"])
            df.to_csv(results_file, mode="a", header=False, index=None, sep=";")

    event.listen(db.engine, "before_cursor_execute", before_cursor_execute)
    event.listen(db.engine, "after_cursor_execute", after_cursor_execute)


CLIENT_GET, CLIENT_POST = CLater("self.client.get"), CLater("self.client.post")
