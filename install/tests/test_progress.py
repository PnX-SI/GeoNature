import io
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parents[1]))

from installer import progress


def test_bar_and_duration_formats():
    assert progress.format_bar(0, 4) == "░" * 20
    assert progress.format_bar(2, 4) == "█" * 10 + "░" * 10
    assert progress.format_bar(4, 4) == "█" * 20
    assert [progress.format_duration(s) for s in (5, 83, 3725)] == ["5s", "1m23s", "1h02m"]


def test_tail_line_skips_command_headers(tmp_path):
    log = tmp_path / "install.log"
    log.write_text("--- 10:00:00 $ npm ci\nadded 120 packages\n\n--- 10:00:05 $ npm run build\n")
    assert progress.tail_line(log) == "added 120 packages"
    assert progress.tail_line(tmp_path / "absent.log") == ""


def test_plain_output_without_terminal_has_no_control_characters():
    out = io.StringIO()
    clock = iter([0, 83]).__next__
    p = progress.Progress(3, stream=out, tty=False, clock=clock)
    p.skipped("Paquets système")
    p.start("Backend")
    p.done()
    text = out.getvalue()
    assert "\r" not in text and "\033" not in text
    assert "✔ [1/3] Paquets système (déjà fait)" in text
    assert "▶ [2/3] Backend…" in text and "✔ [2/3] Backend (1m23s)" in text


def test_failure_is_reported_with_step_number():
    out = io.StringIO()
    p = progress.Progress(2, stream=out, tty=False, clock=iter([0, 5]).__next__)
    p.start("Base de données")
    p.failed()
    assert "✘ [1/2] Base de données : échec après 5s" in out.getvalue()


def test_live_line_shows_step_spinner_time_and_log_tail(tmp_path):
    log = tmp_path / "install.log"
    log.write_text("--- 10:00 $ apt\nSetting up libgdal-dev\n")
    p = progress.Progress(9, log_file=log, stream=io.StringIO(), tty=True, clock=lambda: 12)
    p.index, p.title, p._started = 3, "Backend", 0
    line = p.live_line(0, 120)
    assert "3/9 Backend" in line and "12s" in line and "Setting up libgdal-dev" in line
    assert len(p.live_line(0, 40)) <= 40


def test_message_does_not_leave_a_thread_running_after_done():
    out = io.StringIO()
    p = progress.Progress(1, stream=out, tty=True)
    p.start("Étape")
    p.message("info")
    p.done()
    assert p._thread is None and "info\n" in out.getvalue()


def test_tail_ignores_output_of_previous_steps(tmp_path):
    log = tmp_path / "install.log"
    log.write_text("old step output\n")
    since = progress.log_size(log)
    assert progress.tail_line(log, since) == ""
    with open(log, "a") as f:
        f.write("new step output\n")
    assert progress.tail_line(log, since) == "new step output"
