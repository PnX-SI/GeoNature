import logging

import pytest
from geonature.tests.benchmarks import *
from geonature.tests.test_pr_occhab import stations
from geonature.core.gn_synthese.models import Synthese
from .utils import activate_profiling_sql

from .benchmark_generator import BenchmarkTest, CLater


logging.basicConfig()
logger = logging.getLogger("logger-name")
logger.setLevel(logging.DEBUG)

from .utils import CLIENT_GET, CLIENT_POST, add_bluring_to_benchmark_test_class

SYNTHESE_GET_OBS_URL = """url_for("gn_synthese.get_observations_for_web")"""
SYNTHESE_EXPORT_OBS_URL = """url_for("gn_synthese.export_observations_web")"""
SYNTHESE_EXPORT_STATUS_URL = """url_for("gn_synthese.export_status")"""
SYNTHESE_EXPORT_TAXON_WEB_URL = """url_for("gn_synthese.export_taxon_web")"""


@pytest.mark.benchmark(group="synthese")
@pytest.mark.usefixtures("client_class", "temporary_transaction", "activate_profiling_sql")
class TestBenchmarkSynthese:
    # GET NOMENCLATURE
    test_get_default_nomenclatures = BenchmarkTest(
        CLIENT_GET,
        [CLater("""url_for("gn_synthese.getDefaultsNomenclatures")""")],
        dict(user_profile="self_user"),
    )

    test_with_geometry_bbox = BenchmarkTest(
        CLIENT_POST,
        [CLater(SYNTHESE_GET_OBS_URL)],
        dict(
            user_profile="admin_user",
            json=benchmark_synthese_intersection_data_test_bbox,
        ),
    )

    test_with_geometry_complex_poly = BenchmarkTest(
        CLIENT_POST,
        [CLater(SYNTHESE_GET_OBS_URL)],
        dict(
            user_profile="admin_user",
            json=benchmark_synthese_intersection_data_test_complex_polygon,
        ),
    )
    test_with_commune = BenchmarkTest(
        CLIENT_POST,
        [CLater(SYNTHESE_GET_OBS_URL)],
        dict(
            user_profile="admin_user",
            json=CLater("benchmark_data.benchmark_synthese_intersection_data_test_commune()"),
        ),
    )

    test_with_departement = BenchmarkTest(
        CLIENT_POST,
        [CLater(SYNTHESE_GET_OBS_URL)],
        dict(
            user_profile="admin_user",
            json=CLater("benchmark_data.benchmark_synthese_intersection_data_test_departement()"),
        ),
    )
    test_with_region = BenchmarkTest(
        CLIENT_POST,
        [CLater(SYNTHESE_GET_OBS_URL)],
        dict(
            user_profile="admin_user",
            json=CLater("benchmark_data.benchmark_synthese_intersection_data_test_region()"),
        ),
    )
    test_with_up_tree_taxon = BenchmarkTest(
        CLIENT_POST,
        [CLater(SYNTHESE_GET_OBS_URL)],
        dict(
            user_profile="admin_user",
            json=benchmark_synthese_with_tree_taxon,
        ),
    )


# EXPORT TESTING
for url, label in [
    (SYNTHESE_EXPORT_STATUS_URL, "status"),
    (SYNTHESE_EXPORT_TAXON_WEB_URL, "taxons"),
    (SYNTHESE_EXPORT_OBS_URL, "observations"),
]:
    for n_obs in [1000, 10000, 100000, 1000000]:
        setattr(
            TestBenchmarkSynthese,
            f"test_export_{label}_{n_obs}",
            BenchmarkTest(
                CLIENT_POST,
                [CLater(SYNTHESE_EXPORT_OBS_URL)],
                dict(
                    user_profile="admin_user",
                    json=CLater(
                        f"db.session.execute(select(Synthese.id_synthese).limit({n_obs})).all()"
                    ),
                ),
            ),
        )

add_bluring_to_benchmark_test_class(TestBenchmarkSynthese)
