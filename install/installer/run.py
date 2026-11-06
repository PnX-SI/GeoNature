"""Exécution de commandes avec journal unique et erreurs explicites."""

import contextlib
import os
import subprocess
import time
from pathlib import Path


class CommandError(RuntimeError):
    def __init__(self, cmd, returncode, log_file):
        self.cmd, self.returncode, self.log_file = cmd, returncode, log_file
        super().__init__(
            f"Commande en échec (code {returncode}) : {' '.join(map(str, cmd))}\n"
            f"Détails dans {log_file}. Corrigez puis relancez : les étapes terminées sont ignorées."
        )


class Runner:
    def __init__(self, log_file, cwd=None, env=None):
        self.log_file, self.cwd, self.env = Path(log_file), cwd, env

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
