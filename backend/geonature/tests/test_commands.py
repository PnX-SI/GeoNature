import logging
import os
import sys
from collections.abc import Sequence
from pathlib import Path, _PosixFlavour, _WindowsFlavour

import geonature.core.command.create_gn_module as install_module
import geonature.utils.command as command_utils
from click.testing import CliRunner
from geonature.utils.config import config
from geonature.utils.env import db
from munch import Munch
from pypnusershub.db.models import User
import pytest

from .fixtures import *

# Reuse Lambda function in the following tests
abs_function = lambda *args, **kwargs: None


def run_success_mock(*args, **kwargs):
    """
    Simulate a successfull subprocess.run()
    """

    class CommResponse:
        def __init__(self) -> None:
            self.returncode = 0

    return CommResponse()


def iter_module_dist_mock(module_name):
    """
    Mock the iter_module_dist method

    Parameters
    ----------
    module_name : str
        name of the simulated module
    """

    def module_code():
        return "test"

    def _():
        return [
            Munch.fromDict(
                {
                    "entry_points": {
                        "code": {"module": module_name, "load": module_code},
                    }
                }
            )
        ]

    return _


#  Create the SequenceMock class
SequenceMock = type(
    "SequenceMock",
    (Sequence,),
    {
        "__contains__": lambda self, value: True,
        "__getitem__": lambda self, x: None,
        "__len__": lambda self: 3,
    },
)


#  Create the PathMock class
class PathMock(Path):
    _flavour = _PosixFlavour() if os.name == "posix" else _WindowsFlavour()

    def __new__(cls, *pathsegments):
        return super().__new__(cls, *pathsegments)

    def is_file(self) -> bool:
        return True

    @property
    def parents(self):
        return SequenceMock()


def patch_monkeypatch(monkeypatch):
    monkeypatch.setattr(command_utils, "run", run_success_mock)
    monkeypatch.setattr(install_module.subprocess, "run", run_success_mock)
    monkeypatch.setattr(install_module, "Path", PathMock)

    for (
        method
    ) in "module_db_upgrade build_frontend create_frontend_module_config install_frontend_dependencies".split():
        monkeypatch.setattr(install_module, method, abs_function)
    # Redefine os
    monkeypatch.setattr(install_module.os.path, "exists", lambda x: True)
    monkeypatch.setattr(install_module.os, "symlink", lambda x, y: None)
    monkeypatch.setattr(install_module.os, "unlink", lambda x: None)
    monkeypatch.setattr(install_module.os, "readlink", lambda x: None)
    monkeypatch.setattr(install_module.importlib, "reload", abs_function)


@pytest.fixture
def client_click():
    return CliRunner()


@pytest.mark.usefixtures()
class TestCommands:
    # Avoid redefine at each test
    cli = CliRunner()

    def test_install_gn_module_no_modulecode(self):
        result = self.cli.invoke(install_module.install_gn_module, ["test/", "TEST"])
        assert isinstance(result.exception, Exception)

    def test_install_gn_module_dist_code_is_none(self, monkeypatch):
        patch_monkeypatch(monkeypatch)
        monkeypatch.setattr(install_module, "get_dist_from_code", lambda x: None)
        result = self.cli.invoke(install_module.install_gn_module, ["test/", "TEST"])
        assert result.exception.code > 0

    def test_install_gn_module_dist_code_is_GEONATURE(self, monkeypatch):
        patch_monkeypatch(monkeypatch)
        monkeypatch.setattr(install_module, "get_dist_from_code", lambda x: "GEONATURE")
        result = self.cli.invoke(install_module.install_gn_module, ["test/"])
        assert result.exit_code == 0

    def test_install_gn_module_no_module_code(self, monkeypatch):
        patch_monkeypatch(monkeypatch)
        module_path = "backend/geonature/core"
        monkeypatch.setattr(
            install_module, "iter_modules_dist", iter_module_dist_mock("geonature")
        )
        result = self.cli.invoke(install_module.install_gn_module, [module_path])
        assert result.exit_code == 0

    def test_install_gn_module_empty_iter_module_dist(self, monkeypatch):
        patch_monkeypatch(monkeypatch)
        module_path = "backend/geonature/core"
        monkeypatch.setattr(install_module, "iter_modules_dist", lambda: [])
        result = self.cli.invoke(install_module.install_gn_module, [module_path])
        assert result.exit_code > 0
        monkeypatch.setattr(
            install_module, "iter_modules_dist", iter_module_dist_mock("geonature")
        )

    def test_install_gn_module_nomodule_code(self, monkeypatch):
        patch_monkeypatch(monkeypatch)
        module_path = "backend/geonature/core"
        monkeypatch.setattr(
            install_module, "iter_modules_dist", iter_module_dist_mock("geonature")
        )
        result = self.cli.invoke(install_module.install_gn_module, [module_path, "--build=false"])
        assert result.exit_code == 0

    def test_install_gn_module_false_upgrade_db(self, monkeypatch):
        patch_monkeypatch(monkeypatch)
        module_path = "backend/geonature/core"
        monkeypatch.setattr(
            install_module, "iter_modules_dist", iter_module_dist_mock("geonature")
        )

        result = self.cli.invoke(
            install_module.install_gn_module, [module_path, "--upgrade-db=false"]
        )
        assert result.exit_code == 0

    def test_install_gn_module_symlink_not_exists(self, monkeypatch):
        patch_monkeypatch(monkeypatch)
        module_path = "backend/geonature/core"
        monkeypatch.setattr(
            install_module, "iter_modules_dist", iter_module_dist_mock("geonature")
        )
        monkeypatch.setattr(install_module.os.path, "exists", lambda x: False)
        result = self.cli.invoke(install_module.install_gn_module, [module_path])

        assert result.exit_code == 0

    def test_install_gn_module_module_notin_sysmodule(self, monkeypatch):
        patch_monkeypatch(monkeypatch)
        module_path = "backend/geonature/core"
        monkeypatch.setattr(install_module.os.path, "exists", lambda x: False)
        monkeypatch.setattr(install_module, "iter_modules_dist", iter_module_dist_mock("pouet"))
        result = self.cli.invoke(install_module.install_gn_module, [module_path])
        assert result.exit_code > 0  # will fail

    def test_upgrade_modules_db(self, monkeypatch):
        monkeypatch.setattr(
            install_module, "iter_modules_dist", iter_module_dist_mock("geonature")
        )
        result = self.cli.invoke(install_module.upgrade_modules_db, [])
        assert result.exit_code > 0

        with monkeypatch.context() as m:
            m.setitem(config, "DISABLED_MODULES", ["test"])
            result = self.cli.invoke(install_module.upgrade_modules_db, ["test"])
            assert result.exit_code == 0

        monkeypatch.setattr(install_module, "module_db_upgrade", lambda *args, **kwargs: True)
        result = self.cli.invoke(install_module.upgrade_modules_db, ["test"])
        assert result.exit_code == 0

        monkeypatch.setattr(install_module, "module_db_upgrade", lambda *args, **kwargs: False)
        result = self.cli.invoke(install_module.upgrade_modules_db, ["test"])
        assert result.exit_code == 0

    def test_nvm_available(self, monkeypatch):
        # Test if nvm exists is done in CI
        monkeypatch.setattr(command_utils, "run", run_success_mock)
        assert command_utils.nvm_available()

    def test_install_fronted_dependencies(self, monkeypatch):
        monkeypatch.setattr(command_utils, "run", run_success_mock)
        command_utils.install_frontend_dependencies("module_path")

    def test_build_frontend(self, monkeypatch):
        monkeypatch.setattr(command_utils, "run", run_success_mock)
        command_utils.build_frontend()
