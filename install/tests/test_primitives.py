import hashlib
import io
import sys
import urllib.error
from pathlib import Path
from types import SimpleNamespace

import pytest

sys.path.insert(0, str(Path(__file__).resolve().parents[1]))

from installer import net, pg
from installer.run import CommandError, Runner
from installer.state import State


def test_state_roundtrip(tmp_path):
    s = State(tmp_path / ".state")
    assert not s.is_done("db")
    s.mark_done("db", version="1")
    assert s.is_done("db")
    s.mark_done("apache")
    s.reset("db")
    assert not s.is_done("db") and s.is_done("apache")
    s.reset()
    assert not s.is_done("apache")


def test_runner_logs_and_raises(tmp_path):
    r = Runner(tmp_path / "x.log")
    r.run(["echo", "bonjour"])
    with pytest.raises(CommandError) as e:
        r.run(["sh", "-c", "echo oups >&2; exit 3"])
    assert e.value.returncode == 3 and "x.log" in str(e.value)
    log = (tmp_path / "x.log").read_text()
    assert "bonjour" in log and "oups" in log
    assert r.run(["false"], check=False).returncode == 1


class Resp(io.BytesIO):
    def __enter__(self):
        return self

    def __exit__(self, *a):
        self.close()


def test_download_retries_then_succeeds(tmp_path):
    calls = []

    def opener(url, timeout):
        calls.append(url)
        if len(calls) < 3:
            raise urllib.error.URLError("réseau")
        return Resp(b"data")

    dest = net.download("http://x/f", tmp_path / "f", opener=opener, sleep=lambda s: None)
    assert dest.read_bytes() == b"data" and len(calls) == 3
    assert not list(tmp_path.glob("*.part"))


def test_download_gives_up_and_leaves_nothing(tmp_path):
    def opener(url, timeout):
        raise urllib.error.URLError("down")

    with pytest.raises(net.DownloadError):
        net.download("http://x/f", tmp_path / "f", attempts=2, opener=opener, sleep=lambda s: None)
    assert not list(tmp_path.iterdir())


def test_download_no_retry_on_404(tmp_path):
    calls = []

    def opener(url, timeout):
        calls.append(1)
        raise urllib.error.HTTPError(url, 404, "nf", {}, None)

    with pytest.raises(net.DownloadError):
        net.download("http://x/f", tmp_path / "f", opener=opener, sleep=lambda s: None)
    assert len(calls) == 1


def test_download_checks_sha256(tmp_path):
    ok = hashlib.sha256(b"data").hexdigest()
    opener = lambda url, timeout: Resp(b"data")
    assert net.download("u", tmp_path / "a", sha256=ok, opener=opener)
    with pytest.raises(net.DownloadError):
        net.download("u", tmp_path / "b", sha256="0" * 64, attempts=1, opener=opener)
    assert not (tmp_path / "b").exists()


class FakeRunner:
    def __init__(self, out=""):
        self.calls, self.out = [], out

    def run(self, cmd, input=None):
        self.calls.append((cmd, input))

    def capture(self, cmd, input=None):
        self.calls.append((cmd, input))
        return SimpleNamespace(stdout=self.out)


def test_password_is_never_in_command_line_or_inlined_in_sql():
    r = FakeRunner(out="")
    secret = "p'a\"ss;DROP"
    assert pg.create_role(r, "gn", secret) is True
    cmd, sql = r.calls[-1]
    assert secret not in " ".join(cmd)  # jamais visible dans `ps`
    assert "\\set p 'p''a\"ss;DROP'" in sql  # échappé par la syntaxe psql
    assert "PASSWORD :'p'" in sql


def test_set_command_escaping_and_rejection():
    assert pg.set_command("v", "a\\b'c") == "\\set v 'a\\\\b''c'\n"
    with pytest.raises(ValueError):
        pg.set_command("v", "a\nb")


def test_create_role_skipped_if_exists():
    assert pg.create_role(FakeRunner(out="1"), "gn", "x") is False


def test_drop_requires_confirmation():
    r = FakeRunner()
    with pytest.raises(pg.DatabaseExistsError):
        pg.drop_database(r, "geonature2db")
    with pytest.raises(pg.DatabaseExistsError):
        pg.drop_database(r, "geonature2db", confirm_drop="autre")
    assert not r.calls
    pg.drop_database(r, "geonature2db", confirm_drop="geonature2db")
    assert r.calls


def test_runner_env_completes_instead_of_replacing(tmp_path, monkeypatch):
    monkeypatch.setenv("HOME", "/home/precieux")
    r = Runner(tmp_path / "e.log")
    out = tmp_path / "out"
    r.run(["sh", "-c", 'printf "%s|%s" "$HOME" "$EXTRA"'], env={"EXTRA": "x"}, stdout_path=out)
    assert out.read_text() == "/home/precieux|x"
    r.env = {"ONLY_RUNNER": "y"}
    r.run(
        ["sh", "-c", 'printf "%s|%s|%s" "$HOME" "$ONLY_RUNNER" "$EXTRA"'],
        env={"EXTRA": "z"},
        stdout_path=out,
    )
    assert out.read_text() == "/home/precieux|y|z"


def test_runner_capture_honours_env(tmp_path, monkeypatch):
    monkeypatch.setenv("HOME", "/home/precieux")
    r = Runner(tmp_path / "e.log")
    out = r.capture(["sh", "-c", 'printf "%s|%s" "$HOME" "$EXTRA"'], env={"EXTRA": "x"}).stdout
    assert out == "/home/precieux|x"


def test_verbose_runner_streams_output_to_screen_and_log(tmp_path):
    shown = []
    runner = Runner(tmp_path / "x.log", verbose=True, echo=shown.append)
    runner.run(["sh", "-c", "echo un; echo deux >&2"])
    log = (tmp_path / "x.log").read_text()
    assert "un" in log and "deux" in log
    assert any(line.startswith("$ sh -c") for line in shown)
    assert "un\n" in shown and "deux\n" in shown


def test_verbose_runner_feeds_input_and_still_raises_on_failure(tmp_path):
    shown = []
    runner = Runner(tmp_path / "x.log", verbose=True, echo=shown.append)
    runner.run(["cat"], input="depuis stdin\n")
    assert "depuis stdin\n" in shown
    with pytest.raises(CommandError):
        runner.run(["sh", "-c", "echo avant; exit 3"])
    assert "avant\n" in shown


def test_quiet_runner_does_not_echo(tmp_path):
    shown = []
    Runner(tmp_path / "x.log", echo=shown.append).run(["echo", "silence"])
    assert shown == [] and "silence" in (tmp_path / "x.log").read_text()
