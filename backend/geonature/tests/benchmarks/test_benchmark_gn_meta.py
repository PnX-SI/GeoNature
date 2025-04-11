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


@pytest.mark.benchmark(group="gn_meta")
@pytest.mark.usefixtures("client_class", "temporary_transaction", "activate_profiling_sql")
class TestBenchmarkGnMeta:

    test_list_acquisition_frameworks = BenchmarkTest(
        CLIENT_GET,
        [CLater("""url_for("gn_meta.get_acquisition_frameworks_list")""")],
        dict(user_profile="admin_user", fixtures=[]),
    )()
    test_list_datasets = BenchmarkTest(
        CLIENT_GET,
        [CLater("""url_for("gn_meta.get_datasets")""")],
        dict(user_profile="admin_user", fixtures=[]),
    )()
