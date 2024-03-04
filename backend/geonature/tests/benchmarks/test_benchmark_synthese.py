import logging
import pytest
from geonature.tests.benchmarks import *
from geonature.tests.test_pr_occhab import stations

from .benchmark_generator import BenchmarkTest, CLater

logging.basicConfig()
logger = logging.getLogger("logger-name")
logger.setLevel(logging.DEBUG)

from .utils import CLIENT_GET, CLIENT_POST


@pytest.mark.usefixtures("client_class", "temporary_transaction")  # , "activate_profiling_sql")
class TestBenchmarkSynthese:
    test_get_default_nomenclatures = BenchmarkTest(
        CLIENT_GET,
        [CLater("""url_for("gn_synthese.getDefaultsNomenclatures")""")],
        dict(user_profile="self_user"),
    )()
    test_synthese_with_geometry_bbox = BenchmarkTest(
        CLIENT_POST,
        [CLater("""url_for("gn_synthese.get_observations_for_web")""")],
        dict(
            user_profile="admin_user",
            json=benchmark_synthese_intersection_data_test_bbox,
        ),
    )()

    test_synthese_with_geometry_complex_poly = BenchmarkTest(
        CLIENT_POST,
        [CLater("""url_for("gn_synthese.get_observations_for_web")""")],
        dict(
            user_profile="admin_user",
            json=benchmark_synthese_intersection_data_test_complex_polygon,
        ),
    )()
    test_synthese_with_commune = BenchmarkTest(
        CLIENT_POST,
        [CLater("""url_for("gn_synthese.get_observations_for_web")""")],
        dict(
            user_profile="admin_user",
            json=CLater("benchmark_data.benchmark_synthese_intersection_data_test_commune()"),
        ),
    )()

    test_synthese_with_departement = BenchmarkTest(
        CLIENT_POST,
        [CLater("""url_for("gn_synthese.get_observations_for_web")""")],
        dict(
            user_profile="admin_user",
            json=CLater("benchmark_data.benchmark_synthese_intersection_data_test_departement()"),
        ),
    )()
    test_synthese_with_region = BenchmarkTest(
        CLIENT_POST,
        [CLater("""url_for("gn_synthese.get_observations_for_web")""")],
        dict(
            user_profile="admin_user",
            json=CLater("benchmark_data.benchmark_synthese_intersection_data_test_region()"),
        ),
    )()
    test_synthese_with_up_tree_taxon = BenchmarkTest(
        CLIENT_POST,
        [CLater("""url_for("gn_synthese.get_observations_for_web")""")],
        dict(
            user_profile="admin_user",
            json=benchmark_synthese_with_tree_taxon,
        ),
    )()

    ### WITH BLURRING
    test_synthese_with_geometry_bbox_with_blurring = BenchmarkTest(
        CLIENT_POST,
        [CLater("""url_for("gn_synthese.get_observations_for_web")""")],
        dict(
            user_profile="user_with_blurring",
            json=benchmark_synthese_intersection_data_test_bbox,
        ),
    )()

    test_synthese_with_geometry_complex_poly_with_blurring = BenchmarkTest(
        CLIENT_POST,
        [CLater("""url_for("gn_synthese.get_observations_for_web")""")],
        dict(
            user_profile="user_with_blurring",
            json=benchmark_synthese_intersection_data_test_complex_polygon,
        ),
    )()
    test_synthese_with_commune_with_blurring = BenchmarkTest(
        CLIENT_POST,
        [CLater("""url_for("gn_synthese.get_observations_for_web")""")],
        dict(
            user_profile="user_with_blurring",
            json=CLater("benchmark_data.benchmark_synthese_intersection_data_test_commune()"),
        ),
    )()

    test_synthese_with_departement_with_blurring = BenchmarkTest(
        CLIENT_POST,
        [CLater("""url_for("gn_synthese.get_observations_for_web")""")],
        dict(
            user_profile="user_with_blurring",
            json=CLater("benchmark_data.benchmark_synthese_intersection_data_test_departement()"),
        ),
    )()
    test_synthese_with_region_with_blurring = BenchmarkTest(
        CLIENT_POST,
        [CLater("""url_for("gn_synthese.get_observations_for_web")""")],
        dict(
            user_profile="user_with_blurring",
            json=CLater("benchmark_data.benchmark_synthese_intersection_data_test_region()"),
        ),
    )()
    test_synthese_with_up_tree_taxon_with_blurring = BenchmarkTest(
        CLIENT_POST,
        [CLater("""url_for("gn_synthese.get_observations_for_web")""")],
        dict(
            user_profile="user_with_blurring",
            json=benchmark_synthese_with_tree_taxon,
        ),
    )()
