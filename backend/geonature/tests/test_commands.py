import logging
import os
import sys
from collections.abc import Sequence
from pathlib import Path, _PosixFlavour, _WindowsFlavour

import geonature.core.command.create_gn_module as install_module
import geonature.utils.command as command_utils
from click.testing import CliRunner
from geonature.utils.config import config
from munch import Munch

from .fixtures import *

# Reuse Lambda function in the following tests
true = lambda: True
false = lambda: False
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


def print_result(result):
    """
    Only for DEBUG test
    """
    print("---------")
    print("Output")
    print(result.output)
    print("Exception")
    print(result.exception)
    print("---------")


class TestCommands:
    def test_install_gn_module(self, monkeypatch):
        """
        Function to redefine

        os.path.exists
        subprocess.run
        Path.is_file --> strict is always True
        module_db_upgrade --> do nothing
        """
        logging.info("\nTEST INSTALL GN MODULE")
        cli = CliRunner()

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

        # module code
        # 1. If module code
        # 1.1 check that if module do not exist works
        logging.info("Test: if module code not exists")
        result = cli.invoke(install_module.install_gn_module, ["test/", "TEST"])
        assert isinstance(result.exception, Exception)

        # 1.2 if get_dist_from_code is None
        logging.info("Test : if get_dist_from_code() returns None")
        monkeypatch.setattr(install_module, "get_dist_from_code", lambda x: None)
        result = cli.invoke(install_module.install_gn_module, ["test/", "TEST"])
        assert result.exception.code > 0

        # 1.2 if get_dist_from_code is GEONATURE
        logging.info("Test : if get_dist_from_code() returns GEONATURE")
        monkeypatch.setattr(install_module, "get_dist_from_code", lambda x: "GEONATURE")
        result = cli.invoke(install_module.install_gn_module, ["test/"])
        assert result.exit_code == 0

        # 2. If not module code given

        logging.info("Test : no module code given")
        module_path = "backend/geonature/core"
        monkeypatch.setattr(
            install_module, "iter_modules_dist", iter_module_dist_mock("geonature")
        )
        result = cli.invoke(install_module.install_gn_module, [module_path])
        assert result.exit_code == 0

        logging.info("Test: if iter_modules_dist return an empty iterator")
        monkeypatch.setattr(install_module, "iter_modules_dist", lambda: [])
        result = cli.invoke(install_module.install_gn_module, [module_path])
        assert result.exit_code > 0
        monkeypatch.setattr(
            install_module, "iter_modules_dist", iter_module_dist_mock("geonature")
        )

        # 3. build parameter set to false
        logging.info("Test : build parameter set to false")
        result = cli.invoke(install_module.install_gn_module, [module_path, "--build=false"])
        assert result.exit_code == 0

        # 4. upgrade_db parameter set to false
        logging.info("Test : upgrade_db parameter set to false")
        result = cli.invoke(install_module.install_gn_module, [module_path, "--upgrade-db=false"])
        assert result.exit_code == 0

        logging.info("Test : if symlink not exists")
        monkeypatch.setattr(install_module.os.path, "exists", lambda x: False)
        result = cli.invoke(install_module.install_gn_module, [module_path])
        assert result.exit_code == 0

        logging.info("Test : if module not in sys.module")
        monkeypatch.setattr(install_module.os.path, "exists", lambda x: False)
        monkeypatch.setattr(install_module, "iter_modules_dist", iter_module_dist_mock("pouet"))
        result = cli.invoke(install_module.install_gn_module, [module_path])
        assert result.exit_code > 0  # will fail

    def test_upgrade_modules_db(self, monkeypatch):
        cli = CliRunner()
        monkeypatch.setattr(
            install_module, "iter_modules_dist", iter_module_dist_mock("geonature")
        )
        result = cli.invoke(install_module.upgrade_modules_db, [])
        assert result.exit_code > 0

        with monkeypatch.context() as m:
            m.setitem(config, "DISABLED_MODULES", ["test"])
            result = cli.invoke(install_module.upgrade_modules_db, ["test"])
            assert result.exit_code == 0

        monkeypatch.setattr(install_module, "module_db_upgrade", lambda *args, **kwargs: True)
        result = cli.invoke(install_module.upgrade_modules_db, ["test"])
        assert result.exit_code == 0

        monkeypatch.setattr(install_module, "module_db_upgrade", lambda *args, **kwargs: False)
        result = cli.invoke(install_module.upgrade_modules_db, ["test"])
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
