import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parents[1]))

from installer import preflight as pf


class Done:
    def __init__(self, code=0, out=""):
        self.returncode, self.stdout = code, out


def test_uv_present():
    c = pf.check_uv(which=lambda _: "/bin/uv", run=lambda *a, **k: Done(0, "uv 0.5.0"))
    assert (c.status, c.detail) == (pf.OK, "uv 0.5.0")


def test_uv_installable_with_pip():
    assert pf.check_uv(which=lambda _: None, run=lambda *a, **k: Done(0)).status == pf.WARN


def test_uv_missing_without_pip_is_not_blocking():
    # python3-pip fait partie des paquets installés par l'étape apt
    assert pf.check_uv(which=lambda _: None, run=lambda *a, **k: Done(1)).status == pf.WARN


def test_uv_python_found_or_downloadable():
    assert (
        pf.check_uv_python(which=lambda _: "/bin/uv", run=lambda *a, **k: Done(0)).status == pf.OK
    )
    assert (
        pf.check_uv_python(which=lambda _: "/bin/uv", run=lambda *a, **k: Done(1)).status == pf.WARN
    )
    assert pf.check_uv_python(which=lambda _: None).status == pf.WARN


def test_not_root():
    assert pf.check_not_root(1000).status == pf.OK
    assert pf.check_not_root(0).status == pf.FAIL


def test_ram(tmp_path):
    low, high = tmp_path / "low", tmp_path / "high"
    low.write_text("MemTotal:        1048576 kB\n")
    high.write_text("MemTotal:        8388608 kB\n")
    assert pf.check_ram(str(low)).status == pf.WARN
    assert pf.check_ram(str(high)).status == pf.OK
    assert pf.check_ram(str(tmp_path / "absent")).status == pf.WARN


def test_postgres_remote_is_not_probed():
    assert pf.check_postgres("db.example.org").status == pf.WARN


def test_report_returns_false_on_failure(capsys):
    assert pf.report([pf.Check("a", pf.OK), pf.Check("b", pf.FAIL, "boom")]) is False
    assert pf.report([pf.Check("a", pf.OK), pf.Check("b", pf.WARN)]) is True
