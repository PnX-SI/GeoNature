import logging
import pytest
from geonature.tests.benchmarks import *

from .benchmark_generator import BenchmarkTest, CLater

from .utils import activate_profiling_sql

logging.basicConfig()
logger = logging.getLogger("logger-name")
logger.setLevel(logging.DEBUG)

from .utils import CLIENT_GET


@pytest.mark.benchmark(group="ref_geo")
@pytest.mark.usefixtures("client_class", "temporary_transaction", "activate_profiling_sql")
class TestBenchmarkRefGeo:

    test_get_areas_with_geom = BenchmarkTest(
        CLIENT_GET,
        [
            CLater(
                """url_for("ref_geo.get_areas", without_geom="false", type_code=["REG", "DEP", "COM"])"""
            )
        ],
        dict(user_profile="admin_user", fixtures=[]),
    )()

    test_get_areas_without_geom = BenchmarkTest(
        CLIENT_GET,
        [
            CLater(
                """url_for("ref_geo.get_areas", without_geom="true", type_code=["REG", "DEP", "COM"])"""
            )
        ],
        dict(user_profile="admin_user", fixtures=[]),
    )()
