from typing import Any, Dict, Sequence, Callable
from .utils import set_logged_user
from .fixtures import users
from .test_pr_occhab import stations
from flask import url_for
import pytest

from .benchmark_data import *


class GetLatter:
    def __init__(self, value) -> None:
        self.value = value


class BenchmarkTest:
    """
    Class that allows to define a benchmark test and generate the pytest function to run the benchmark.

    Example, in a pytest file:
    ```python
    import pytest
    bench = BenchmarkTest(print,"test_print",["Hello","World"],{})
    @pytest.mark.usefixtures("client_class", "temporary_transaction")
        class TestBenchie:
            pass
    TestBenchie.test_print = bench.generate_func_test()
    ```

    If a function or its argument depend on the pytest function context, use the GetLatter class : GetLatter("<python expression">). For example, to use
    the `url_for()` function, replace from `url_for(...)` to `GetLatter("url_for(...)")`.

    If the benchmark requires a user to be logged, use the `function_kwargs` with the "user_profile" key and the value corresponds to a key
    available in the dictionary returned by the `user` fixture.


    """

    def __init__(self, function, name_benchmark, function_args=[], function_kwargs={}) -> None:
        """
        Constructor of BenchmarkTest

        Parameters
        ----------
        function : Callable | GetLatter
            function that will be benchmark
        name_benchmark : str
            name of the benchmark
        function_args : Sequence[Any | GetLatter]
            args for the function
        function_kwargs : Dict[str,Any]
            kwargs for the function
        """
        self.function = function
        self.name_benchmark = name_benchmark
        self.function_args = function_args
        self.function_kwargs = function_kwargs

    def generate_func_test(self):
        """
        Return the pytest function to run the benchmark on the indicated function.

        Returns
        -------
        Callable
            test function

        Raises
        ------
        KeyError
            if the user_profile given do not exists
        """
        fixture = self.function_kwargs.pop("fixture", [])
        user_profile = self.function_kwargs.pop("user_profile", None)

        func, args, kwargs = self.function, self.function_args, self.function_kwargs

        def function_to_include_fixture(*fixture):

            def final_test_function(self, benchmark, users):

                if user_profile:
                    if not user_profile in users:
                        raise KeyError(f"{user_profile} can't be found in the users fixture !")
                    set_logged_user(self.client, users[user_profile])
                benchmark(
                    eval(func.value) if isinstance(func, GetLatter) else func,
                    *[eval(arg.value) if isinstance(arg, GetLatter) else arg for arg in args],
                    **kwargs,
                )

            return final_test_function

        return function_to_include_fixture(*fixture)


from geonature.utils.env import db
from sqlalchemy import event
from sqlalchemy.engine import Engine
import time
import logging

logging.basicConfig()
logger = logging.getLogger("logger-name")
logger.setLevel(logging.DEBUG)

import pandas


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


# r = self.client.post(url_for("gn_synthese.get_observations_for_web"), json=filters)
tests = [
    BenchmarkTest(
        GetLatter("self.client.get"),
        "get_station",
        [GetLatter("""url_for("occhab.get_station", id_station=8)""")],
        dict(user_profile="user", fixture=[stations]),
    ),
    BenchmarkTest(
        GetLatter("self.client.get"),
        "get_default_nomenclatures",
        [GetLatter("""url_for("gn_synthese.getDefaultsNomenclatures")""")],
        dict(user_profile="self_user"),
    ),
    BenchmarkTest(
        GetLatter("self.client.post"),
        "synthese_with_geometry_bbox",
        [GetLatter("""url_for("gn_synthese.get_observations_for_web")""")],
        dict(user_profile="admin_user", json=benchmark_synthese_intersection_data_test_bbox),
    ),
    BenchmarkTest(
        GetLatter("self.client.post"),
        "synthese_with_geometry_complex_poly",
        [GetLatter("""url_for("gn_synthese.get_observations_for_web")""")],
        dict(
            user_profile="admin_user",
            json=benchmark_synthese_intersection_data_test_complex_polygon,
        ),
    ),
    BenchmarkTest(
        GetLatter("self.client.post"),
        "synthese_with_commune",
        [GetLatter("""url_for("gn_synthese.get_observations_for_web")""")],
        dict(
            user_profile="admin_user",
            json=benchmark_synthese_intersection_data_test_commune,
        ),
    ),
    BenchmarkTest(
        GetLatter("self.client.post"),
        "synthese_with_up_tree_taxon",
        [GetLatter("""url_for("gn_synthese.get_observations_for_web")""")],
        dict(
            user_profile="admin_user",
            json=benchmark_synthese_with_tree_taxon,
        ),
    ),
]


@pytest.mark.usefixtures("client_class", "temporary_transaction", "activate_profiling_sql")
class TestBenchie:
    pass


for test in tests:
    setattr(TestBenchie, f"test_{test.name_benchmark}", test.generate_func_test())


# def test_routes(app):
#     for rule in app.url_map.iter_rules():
#         print(rule.endpoint)
