"""Exécution de commandes avec journal unique et erreurs explicites."""

import contextlib
import os
import subprocess
import sys
import threading
import time
from pathlib import Path

from .style import Style


class CommandError(RuntimeError):
    def __init__(self, cmd, returncode, log_file):
        self.cmd, self.returncode, self.log_file = cmd, returncode, log_file
        super().__init__(
            f"Commande en échec (code {returncode}) : {' '.join(map(str, cmd))}\n"
            f"Détails dans {log_file}. Corrigez puis relancez : les étapes terminées sont ignorées."
        )


class Runner:
    def __init__(self, log_file, cwd=None, env=None, verbose=False, echo=None):
        self.log_file, self.cwd, self.env = Path(log_file), cwd, env
        self.verbose = verbose  # affiche aussi la sortie des commandes, en direct
        self.echo = echo or self._print_line

    @staticmethod
    def _print_line(line):
        """Sortie détaillée : commandes en cyan, sortie en gris (couleurs seulement sur un terminal)."""
        style = Style.for_stream()
        text = (
            style.cyan(line.rstrip("\n"))
            if line.startswith("$ ")
            else style.gray(line.rstrip("\n"))
        )
        sys.stdout.write("    " + style.gray("│") + " " + text + "\n")
        sys.stdout.flush()

    def _run_tee(self, cmd, input, env, cwd, log):
        """Exécute `cmd` en copiant sa sortie (stdout + stderr) dans le journal et à l'écran, ligne à ligne."""
        self.echo(f"$ {' '.join(map(str, cmd))}\n")
        proc = subprocess.Popen(
            cmd,
            stdin=subprocess.PIPE if input is not None else None,
            stdout=subprocess.PIPE,
            stderr=subprocess.STDOUT,
            text=True,
            cwd=cwd or self.cwd,
            env=env,
        )
        if input is not None:
            # écriture dans un thread : une entrée volumineuse ne doit pas bloquer la lecture de la sortie
            def feed():
                with contextlib.suppress(BrokenPipeError):
                    proc.stdin.write(input)
                with contextlib.suppress(BrokenPipeError):
                    proc.stdin.close()

            threading.Thread(target=feed, daemon=True).start()
        for line in proc.stdout:
            log.write(line)
            log.flush()
            self.echo(line)
        proc.wait()
        return subprocess.CompletedProcess(cmd, proc.returncode)

    def _merge_env(self, env=None):
        """Environnement du processus : celui de l'appelant complété, jamais remplacé."""
        if self.env is None and env is None:
            return None
        return {**os.environ, **(self.env or {}), **(env or {})}

    def run(
        self, cmd, input=None, env=None, cwd=None, check=True, stdout_path=None, stdin_path=None
    ):
        """Lance `cmd` (liste, jamais de shell). Sortie ajoutée au journal ; retourne le CompletedProcess.

        `stdout_path` redirige la sortie standard vers un fichier (ex. pg_dump), `stdin_path` lit l'entrée
        depuis un fichier (ex. pg_restore) ; stderr reste dans le journal.
        """
        self.log_file.parent.mkdir(parents=True, exist_ok=True)
        merged_env = self._merge_env(env)
        with contextlib.ExitStack() as stack:
            log = stack.enter_context(open(self.log_file, "a"))
            log.write(f"\n--- {time.strftime('%H:%M:%S')} $ {' '.join(map(str, cmd))}\n")
            log.flush()
            out = stack.enter_context(open(stdout_path, "wb")) if stdout_path else log
            stdin = stack.enter_context(open(stdin_path, "rb")) if stdin_path else None
            if self.verbose and not (stdout_path or stdin_path):
                proc = self._run_tee(cmd, input, merged_env, cwd, log)
            else:
                proc = subprocess.run(
                    cmd,
                    input=None if stdin else input,
                    text=not (stdout_path or stdin_path),
                    stdin=stdin,
                    stdout=out,
                    stderr=log if stdout_path else subprocess.STDOUT,
                    cwd=cwd or self.cwd,
                    env=merged_env,
                )
        if check and proc.returncode != 0:
            raise CommandError(cmd, proc.returncode, self.log_file)
        return proc

    def capture(self, cmd, **kwargs):
        """Comme subprocess.run mais retourne la sortie ; pour les lectures sans effet."""
        return subprocess.run(
            cmd,
            input=kwargs.get("input"),
            capture_output=True,
            text=True,
            cwd=kwargs.get("cwd") or self.cwd,
            env=self._merge_env(kwargs.get("env")),
        )
