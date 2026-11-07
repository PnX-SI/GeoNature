"""Avancement de l'installation : barre d'étapes, durée, et dernière ligne du journal en direct.

Sur un terminal, une ligne est rafraîchie pendant chaque étape ; sinon (CI, redirection, `curl | sh`
sans terminal) seules des lignes simples sont écrites, sans caractères de contrôle.
"""

import shutil
import sys
import threading
import time
from pathlib import Path

from .style import Style

SPINNER = "⠋⠙⠹⠸⠼⠴⠦⠧⠇⠏"
BAR_WIDTH = 20


def format_bar(done, total, width=BAR_WIDTH):
    filled = round(width * done / total) if total else width
    return "█" * filled + "░" * (width - filled)


def format_duration(seconds):
    seconds = int(seconds)
    if seconds < 60:
        return f"{seconds}s"
    minutes, seconds = divmod(seconds, 60)
    if minutes < 60:
        return f"{minutes}m{seconds:02d}s"
    return f"{minutes // 60}h{minutes % 60:02d}m"


def log_size(path):
    try:
        return Path(path).stat().st_size
    except OSError:
        return 0


def tail_line(path, since=0, max_bytes=4096):
    """Dernière ligne non vide du journal écrite après l'offset `since`, sans les en-têtes (`--- … $`)."""
    try:
        with open(path, "rb") as f:
            f.seek(0, 2)
            f.seek(max(since, f.tell() - max_bytes))
            lines = f.read().decode(errors="replace").splitlines()
    except OSError:
        return ""
    for line in reversed(lines):
        line = line.strip()
        if line and not line.startswith("--- "):
            return line
    return ""


def fit(text, width):
    return text if len(text) <= width else text[: max(width - 1, 0)] + "…"


class Progress:
    def __init__(
        self, total, log_file=None, stream=None, tty=None, clock=time.monotonic, style=None
    ):
        self.total, self.log_file, self.clock = total, log_file, clock
        self.stream = stream or sys.stdout
        self.tty = self.stream.isatty() if tty is None else tty
        # couleurs : selon le terminal, même quand la ligne en direct est désactivée (mode verbeux)
        self.style = style or Style.for_stream(self.stream)
        self.icon = ""
        self.index = 0
        self.title = ""
        self._started = 0
        self._log_start = 0
        self._stop = None
        self._thread = None

    # --- affichage ---------------------------------------------------------------------------

    def live_line(self, frame, width):
        st = self.style
        spin = f"{SPINNER[frame % len(SPINNER)]} {format_duration(self.clock() - self._started)}"
        bar = f"[{format_bar(self.index - 1, self.total)}]"
        middle = f" {self.index}/{self.total} {self.title} "
        width -= 3 if self.icon else 0  # une icône occupe deux colonnes et une espace
        room = width - len(bar) - len(middle) - len(spin) - 2
        detail = (
            fit(tail_line(self.log_file, self._log_start), room)
            if self.log_file and room > 10
            else ""
        )
        plain = fit(f"{bar}{middle}{spin}  {detail}".rstrip(), width)
        if not st.enabled or len(plain) < len(f"{bar}{middle}{spin}"):
            return self.icon + plain
        # couleurs ajoutées après le calcul des largeurs, sur le texte brut
        line = st.cyan(bar) + middle + st.gray(spin)
        return self.icon + line + (f"  {st.gray(detail)}" if detail else "")

    def _write_live(self, frame):
        width = shutil.get_terminal_size((100, 20)).columns - 1
        self.stream.write("\r\033[K" + self.live_line(frame, width))
        self.stream.flush()

    def _clear(self):
        if self.tty:
            self.stream.write("\r\033[K")

    def _loop(self):
        frame = 0
        while not self._stop.wait(0.2):
            self._write_live(frame)
            frame += 1

    # --- cycle d'une étape -------------------------------------------------------------------

    def skipped(self, title, step=None):
        self.index += 1
        st = self.style
        self.message(st.gray(f"✔ {st.icon(step)}[{self.index}/{self.total}] {title} (déjà fait)"))

    def start(self, title, step=None):
        self.index += 1
        self.title, self._started = title, self.clock()
        self.icon = self.style.icon(step)
        self._log_start = log_size(self.log_file) if self.log_file else 0
        if not self.tty:
            self.message(
                f"{self.style.cyan('▶')} {self.icon}{self.style.bold(f'[{self.index}/{self.total}] {title}')}…"
            )
            return
        self._stop = threading.Event()
        self._write_live(0)
        self._thread = threading.Thread(target=self._loop, daemon=True)
        self._thread.start()

    def _halt(self):
        if self._thread:
            self._stop.set()
            self._thread.join()
            self._thread = None
        self._clear()

    def done(self):
        self._halt()
        took = format_duration(self.clock() - self._started)
        st = self.style
        self.message(
            f"{st.green('✔')} {self.icon}[{self.index}/{self.total}] {self.title} {st.gray(f'({took})')}"
        )

    def failed(self):
        self._halt()
        took = format_duration(self.clock() - self._started)
        self.message(
            self.style.red(
                f"✘ {self.icon}[{self.index}/{self.total}] {self.title} : échec après {took}"
            )
        )

    def message(self, text):
        """Écrit une ligne sans casser la ligne en direct (utilisé comme `ctx.log`)."""
        if self._thread:
            self._clear()
        self.stream.write(text + "\n")
        self.stream.flush()
