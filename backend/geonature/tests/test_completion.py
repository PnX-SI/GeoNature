import shutil
import subprocess

import click
import pytest

from geonature.core.command.completion import generate_completion_script


@click.group()
@click.option("--version", is_flag=True)
def cli(version):
    pass


@cli.group(name="ref_geo")
def ref_geo():
    pass


@ref_geo.command()
def info():
    pass


@cli.command()
@click.option("--port")
@click.option("--debug", is_flag=True)
@click.option("--secret", hidden=True)
def dev_back(port, debug, secret):
    pass


@cli.command(hidden=True)
def hidden_command():
    pass


@pytest.fixture
def completion_script():
    return generate_completion_script(click.Context(cli, info_name="geonature"))


def complete_with_bash(script, words):
    test = (
        f"{script}\n"
        'COMP_WORDS=("$@"); COMP_CWORD=$((${#COMP_WORDS[@]} - 1))\n'
        '_geonature; echo "${COMPREPLY[*]}"\n'
    )
    result = subprocess.run(
        ["bash", "-c", test, "bash", *words], capture_output=True, text=True, check=True
    )
    return result.stdout.split()


class TestCompletion:
    def test_completion_script(self, completion_script):
        assert '"") _gn_cmds="dev-back ref_geo"' in completion_script
        assert '"ref_geo info")' in completion_script
        assert "hidden-command" not in completion_script
        assert "--secret" not in completion_script

    @pytest.mark.skipif(not shutil.which("bash"), reason="bash is not available")
    @pytest.mark.parametrize(
        "words,expected",
        [
            (["geonature", ""], ["dev-back", "ref_geo"]),
            (["geonature", "--"], ["--version", "--help"]),
            (["geonature", "ref_geo", ""], ["info"]),
            (["geonature", "dev_back", "--"], ["--port", "--debug", "--help"]),
            (["geonature", "dev-back", "--port", ""], []),
        ],
    )
    def test_bash_completion(self, completion_script, words, expected):
        assert complete_with_bash(completion_script, words) == expected
