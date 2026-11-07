import io
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parents[1]))

from installer import configure, preflight, progress, render, summary
from installer.style import PLAIN, STEP_ICONS, Style


def test_plain_style_adds_nothing():
    assert PLAIN.green("ok") == "ok" and PLAIN.icon("apt") == ""


def test_enabled_style_colors_and_gives_icons():
    st = Style(True)
    assert st.green("ok") == "\033[32mok\033[0m" and st.red("x").startswith("\033[31m")
    assert st.icon("apt") == STEP_ICONS["apt"] + " " and st.icon("inconnue") == ""


def test_style_follows_the_stream():
    assert Style.for_stream(io.StringIO()).enabled is False


def test_every_installer_step_has_an_icon():
    from installer import steps

    assert {s.name for s in steps.STEPS} <= set(STEP_ICONS)


def test_colored_progress_lines_keep_step_icon_and_status():
    out = io.StringIO()
    p = progress.Progress(
        2, stream=out, tty=False, clock=iter([0, 5, 0, 7]).__next__, style=Style(True)
    )
    p.start("Backend", "backend")
    p.done()
    p.start("Frontend", "frontend")
    p.failed()
    text = out.getvalue()
    assert STEP_ICONS["backend"] in text and "\033[32m✔" in text and "(5s)" in text
    assert "\033[31m" in text and "échec après 7s" in text


def test_colored_live_line_has_same_visible_text_as_plain(tmp_path):
    log = tmp_path / "l.log"
    log.write_text("Setting up libgdal\n")

    def make(style):
        p = progress.Progress(
            9, log_file=log, stream=io.StringIO(), tty=True, clock=lambda: 12, style=style
        )
        p.index, p.title, p._started = 3, "Backend", 0
        return p.live_line(0, 120)

    strip = lambda t: __import__("re").sub(r"\033\[[0-9;]*m", "", t)
    assert strip(make(Style(True))) == make(PLAIN)


def test_plain_summary_and_preflight_have_no_escape_codes(capsys):
    cfg = render.resolve_config({"my_url": "http://x.org/"})
    assert "\033" not in summary.format_summary(cfg, "/srv/gn")
    assert "\033" in summary.format_summary(cfg, "/srv/gn", style=Style(True))
    preflight.report([preflight.Check("Test", preflight.OK, "détail")])
    assert "\033" not in capsys.readouterr().out  # sortie capturée : pas un terminal


def test_prompts_are_colored_only_with_a_style():
    seen = []
    configure.ask(
        "str", "Hôte", "localhost", lambda p: seen.append(p) or "", None, print, Style(True)
    )
    configure.ask("str", "Hôte", "localhost", lambda p: seen.append(p) or "", None, print)
    assert "\033[36m[localhost]" in seen[0] and "\033" not in seen[1]
