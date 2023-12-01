from collections.abc import Sequence
import os
from pathlib import Path
import sys
import geonature.utils.command as command_utils
from .fixtures import *
from click.testing import CliRunner
import geonature.core.command.create_gn_module as install_module
from munch import Munch
from pathlib import _PosixFlavour
from pathlib import _WindowsFlavour

run_mock = lambda x: True
run = run_mock


def run_mock(*args, **kwargs):
    class CommResponse:
        def __init__(self) -> None:
            self.returncode = 0

    return CommResponse()


def true():
    return True


def iter_module_dist_mock(module_name):
    def module_code():
        return "test"

    def foo():
        return [
            Munch.fromDict(
                {
                    "entry_points": {
                        "code": {
                            "module": module_name,
                            "load": module_code,
                        },
                    },
                }
            )
        ]

    return foo


class SequenceMock(Sequence):
    def __contains__(self, value: object) -> bool:
        return True

    def __getitem__(self, x):
        return None

    def __len__(self) -> int:
        return 3


class PathMock(Path):
    _flavour = _PosixFlavour() if os.name == "posix" else _WindowsFlavour()

    def __new__(cls, *pathsegments):
        return super().__new__(cls, *pathsegments)

    def is_file(self) -> bool:
        return True

    @property
    def parents(self):
        return SequenceMock()


class TestCommands:
    def test_install_gn_module(self, monkeypatch):
        """
        Function to redefine

        os.path.exists
        subprocess.run
        Path.is_file --> strict is always True
        module_db_upgrade --> do nothing
        """
        cli = CliRunner()

        def base_context(m):
            m.setattr(command_utils, "run", run_mock)
            m.setattr(install_module.os.path, "exists", lambda x: True)
            m.setattr(install_module.subprocess, "run", run_mock)
            m.setattr(install_module, "Path", PathMock)
            m.setattr(install_module.os, "symlink", lambda x, y: None)
            m.setattr(install_module.os, "unlink", lambda x: None)

        # module code
        # 1. If module code
        # 1.1 check that if module do not exist works
        result = cli.invoke(install_module.install_gn_module, ["test/", "TEST"])
        assert isinstance(result.exception, Exception)

        # 1.2 if get_dist_from_code is None
        with monkeypatch.context() as m:
            base_context(m)
            m.setattr(install_module, "get_dist_from_code", lambda x: None)
            result = cli.invoke(install_module.install_gn_module, ["test/", "TEST"])
            assert result.exception.code > 0

        # 2. If not module code
        with monkeypatch.context() as m:
            base_context(m)
            module_path = "backend/geonature/core"
            m.setattr(install_module, "iter_modules_dist", iter_module_dist_mock("geonature"))
            m.setattr(install_module.os, "readlink", lambda x: module_path)
            result = cli.invoke(install_module.install_gn_module, [module_path])
            print(result.output, result.exception)
            # assert result.exit_code == 0

    def test_nvm_available(self, monkeypatch):
        # Test if nvm exists is done in CI
        monkeypatch.setattr(command_utils, "run", run_mock)
        assert command_utils.nvm_available()

    def test_install_fronted_dependencies(self, monkeypatch):
        monkeypatch.setattr(command_utils, "run", run_mock)
        command_utils.install_frontend_dependencies("module_path")

    def test_build_frontend(self, monkeypatch):
        monkeypatch.setattr(command_utils, "run", run_mock)
        command_utils.build_frontend()
