from click.testing import CliRunner
from geonature.core.command.status import status


def test_invoke_geonature_status():
    runner = CliRunner()

    result = runner.invoke(status)

    assert result.exit_code == 0
