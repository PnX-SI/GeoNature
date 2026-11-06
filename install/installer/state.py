"""Marqueurs d'étapes terminées (`install/.state/<étape>.done`) : reprise et idempotence."""

import json
import time
from pathlib import Path


class State:
    def __init__(self, directory):
        self.directory = Path(directory)

    def _file(self, step):
        return self.directory / f"{step}.done"

    def is_done(self, step):
        return self._file(step).exists()

    def mark_done(self, step, **info):
        self.directory.mkdir(parents=True, exist_ok=True)
        self._file(step).write_text(
            json.dumps({"date": time.strftime("%Y-%m-%dT%H:%M:%S"), **info})
        )

    def reset(self, step=None):
        """Oublie une étape (ou toutes si `step` est None) pour la rejouer."""
        files = [self._file(step)] if step else list(self.directory.glob("*.done"))
        for f in files:
            f.unlink(missing_ok=True)
