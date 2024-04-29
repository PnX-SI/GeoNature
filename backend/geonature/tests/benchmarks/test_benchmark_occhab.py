import logging
import pytest
from geonature.tests.benchmarks import *
from geonature.tests.test_pr_occhab import stations

from .benchmark_generator import BenchmarkTest, CLater
from .utils import activate_profiling_sql

logging.basicConfig()
logger = logging.getLogger("logger-name")
logger.setLevel(logging.DEBUG)

from .utils import CLIENT_GET, CLIENT_POST


@pytest.mark.benchmark(group="occhab")
@pytest.mark.usefixtures("client_class", "temporary_transaction", "activate_profiling_sql")
class TestBenchmarkOcchab:

    test_get_station = BenchmarkTest(
        CLIENT_GET,
        [CLater("""url_for("occhab.get_station", id_station=8)""")],
        dict(user_profile="user", fixtures=[stations]),
    )()

    test_list_stations = BenchmarkTest(
        CLIENT_GET,
        [CLater("""url_for("occhab.list_stations")""")],
        dict(user_profile="admin_user", fixtures=[]),
    )()

    test_list_stations_restricted = BenchmarkTest(
        CLIENT_GET,
        [CLater("""url_for("occhab.list_stations")""")],
        dict(user_profile="user_restricted_occhab", fixtures=[]),
    )()


for format_ in "csv geojson shapefile".split():
    setattr(
        TestBenchmarkOcchab,
        f"test_export_all_habitats_{format_}",
        BenchmarkTest(
            CLIENT_POST,
            [CLater("""url_for("occhab.export_all_habitats",export_format="csv")""")],
            dict(user_profile="admin_user", fixtures=[]),
        )(),
    )
