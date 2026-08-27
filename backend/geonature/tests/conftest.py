# force discovery of some fixtures
import pytest

from utils_flask_sqla.tests.fixtures import *  # activate temporary_transaction fixture


from geonature.tests.fixtures import _app, _session
from geonature.tests.fixtures import *
from pypnusershub.tests.fixtures import teardown_logout_user

pytest.endpoint = ""


def pytest_addoption(parser):
    parser.addoption("--sql-log-filename", action="store", default=None)


@pytest.fixture(scope="session")
def sqllogfilename(request):
    return request.config.getoption("--sql-log-filename")
