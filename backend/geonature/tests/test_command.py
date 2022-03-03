from click.testing import CliRunner
from flask import request
import pytest

from geonature.core.command.alembic import box_drowing, status
from geonature.utils.env import db


@pytest.fixture
def runner(app):
    with db.session.begin_nested():
        yield app.test_cli_runner()


@pytest.mark.parametrize(
    "up,down,left,right,expected",
    [
        (False, False, False, False, "─"),
        (True, False, False, False, "┸"),
        (False, True, False, False, "┰"),
        (True, True, False, False, "┃"),
        (True, False, True, False, "┛"),
        (True, False, False, True, "┗"),
        (False, False, True, True, "━"),
        (False, True, True, False, "┓"),
        (False, True, False, True, "┏"),
        (True, True, False, True, "┣"),
        (True, True, True, False, "┫"),
        (True, False, True, True, "┻"),
        (False, True, True, True, "┳"),
        (True, True, True, True, "╋"),
    ],
)
class TestAlembicBoxDrowing:
    def test_box_drowing(self, up, down, left, right, expected):
        result = box_drowing(up=up, down=down, left=left, right=right)

        assert result == expected


@pytest.mark.usefixtures("client_class", "temporary_transaction")
class TestAlembic:
    @pytest.mark.skip
    def test_status(self, runner):
        request.environ["FLASK_REQUEST_ID"] = 5
        result = runner.invoke(status)

        assert result
