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


@pytest.mark.benchmark(group="home")
@pytest.mark.usefixtures("client_class", "temporary_transaction", "activate_profiling_sql")
class TestBenchmarkHome:

    test_general_stats = BenchmarkTest(
        CLIENT_GET,
        [CLater("""url_for("gn_synthese.synthese_statistics.general_stats")""")],
        dict(user_profile="user", fixtures=[]),
    )()

    test_general_stats_admin = BenchmarkTest(
        CLIENT_GET,
        [CLater("""url_for("gn_synthese.synthese_statistics.general_stats")""")],
        dict(user_profile="admin_user", fixtures=[]),
    )()
