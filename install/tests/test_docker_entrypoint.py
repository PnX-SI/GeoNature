import importlib.util
import sys
from pathlib import Path
from types import SimpleNamespace

import pytest

INSTALL = Path(__file__).resolve().parents[1]

spec = importlib.util.spec_from_file_location(
    "docker_entrypoint", INSTALL / "assets" / "docker_entrypoint.py"
)
entry = importlib.util.module_from_spec(spec)
spec.loader.exec_module(entry)


@pytest.fixture
def ready(tmp_path, monkeypatch):
    monkeypatch.setattr(entry, "READY_FILE", tmp_path / "ready")
    return tmp_path / "ready"


class Recorder:
    """Faux `geonature` : enregistre les commandes ; les sondes (check=False) répondent `probes`."""

    def __init__(self, probes=1):
        self.calls, self.probes = [], probes

    def __call__(self, *args, check=True):
        self.calls.append(args)
        return SimpleNamespace(returncode=self.probes if not check else 0)


def run_main(environ, rec, argv=("gunicorn",)):
    execed = []
    entry.main(list(argv), environ=environ, run=rec, execvp=lambda *a: execed.append(a))
    return execed


def test_populate_then_exec_and_ready(ready):
    rec = Recorder(probes=1)  # base vide : TAXREF et sensibilité absents
    execed = run_main({}, rec)
    assert ("db", "upgrade", "geonature@head", "-x", "local-srid=2154") in rec.calls
    assert ("taxref", "import-v18", "--skip-bdc-statuts") in rec.calls
    assert rec.calls[-1] == ("upgrade-modules-db",)
    assert ready.exists()
    assert execed == [("gunicorn", ["gunicorn"])]


def test_skip_populate_only_touches_ready(ready):
    rec = Recorder()
    ready.touch()
    execed = run_main({"GEONATURE_SKIP_POPULATE_DB": "true"}, rec)
    assert rec.calls == [] and ready.exists() and execed


def test_options_come_from_environment(ready):
    rec = Recorder(probes=0)  # TAXREF et sensibilité déjà chargés
    env = {
        "srid_local": "4326",
        "add_sample_data": "true",
        "usershub": "true",
        "usershub_samples": "true",
    }
    run_main(env, rec)
    assert ("db", "upgrade", "geonature@head", "-x", "local-srid=4326") in rec.calls
    assert ("db", "upgrade", "geonature-samples@head") in rec.calls
    assert not any(c[0] == "taxref" for c in rec.calls)
    assert ("db", "upgrade", "usershub@head") in rec.calls
    assert ("db", "upgrade", "usershub-samples@head") in rec.calls


def test_supergrant_args(ready):
    rec = Recorder(probes=0)
    run_main({"GEONATURE_SUPERGRANT_ARGS": '--group --nom "Grp admin"'}, rec)
    assert rec.calls[-1] == ("permissions", "supergrant", "--yes", "--group", "--nom", "Grp admin")


def test_secret_files(ready, tmp_path):
    secret = tmp_path / "key"
    secret.write_text("s3cr3t\n")
    env = {"GEONATURE_SECRET_KEY_FILE": str(secret), "GEONATURE_SKIP_POPULATE_DB": "true"}
    run_main(env, Recorder())
    assert env["GEONATURE_SECRET_KEY"] == "s3cr3t" and "GEONATURE_SECRET_KEY_FILE" not in env


def test_secret_and_file_are_exclusive(ready, tmp_path):
    env = {"GEONATURE_SECRET_KEY": "a", "GEONATURE_SECRET_KEY_FILE": str(tmp_path / "x")}
    with pytest.raises(SystemExit):
        run_main(env, Recorder())
