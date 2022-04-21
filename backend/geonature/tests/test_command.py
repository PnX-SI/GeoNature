import pytest

from geonature.utils.env import db


@pytest.fixture(scope="function")
def runner(app):
    with db.session.begin_nested():
        yield app.test_cli_runner()
