# force discovery of some fixtures
from .fixtures import app, users, _session, _app
from pypnusershub.tests.fixtures import teardown_logout_user
import pytest

pytest.endpoint = ""


def pytest_addoption(parser):
    parser.addoption("--sql-log-filename", action="store", default=None)


@pytest.fixture(scope="session")
def sqllogfilename(request):
    return request.config.getoption("--sql-log-filename")
