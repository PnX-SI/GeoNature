"""Contrôles à effectuer avant de lancer l'installation (aucune modification du système)."""

import locale
import os
import shutil
import socket
import sys
import subprocess
import urllib.error
import urllib.request
from dataclasses import dataclass
from pathlib import Path

from .style import Style

OK, WARN, FAIL = "OK", "WARN", "FAIL"

PYTHON_VERSION = "3.13"  # version demandée à uv, cf. steps.py
MIN_RAM_MB = 4096
MIN_DISK_GB = 20
REQUIRED_PORTS = (80,)
EXTERNAL_HOSTS = (
    "https://github.com",
    "https://pypi.org",
    "https://registry.npmjs.org",
    "https://geonature.fr",
    "https://data.geopf.fr",
)


@dataclass
class Check:
    name: str
    status: str
    detail: str = ""


def check_arch():
    bits = int(subprocess.run(["getconf", "LONG_BIT"], capture_output=True, text=True).stdout or 0)
    return Check("Architecture", OK if bits == 64 else FAIL, f"{bits} bits")


def check_uv(which=shutil.which, run=subprocess.run):
    """uv crée le venv du backend ; s'il manque, l'installation le installe avec `pip --user`."""
    path = which("uv")
    if path:
        version = run([path, "--version"], capture_output=True, text=True).stdout.strip()
        return Check("uv", OK, version or path)
    if run([sys.executable, "-m", "pip", "--version"], capture_output=True).returncode == 0:
        return Check("uv", WARN, "absent, sera installé avec pip --user")
    return Check("uv", WARN, "absent, et pip sera d'abord installé par apt (python3-pip)")


def check_uv_python(which=shutil.which, run=subprocess.run):
    """uv utilise un Python système compatible, sinon il télécharge une version autonome depuis GitHub."""
    path = which("uv")
    if path and run([path, "python", "find", PYTHON_VERSION], capture_output=True).returncode == 0:
        return Check(f"Python {PYTHON_VERSION}", OK, "disponible pour uv")
    return Check(
        f"Python {PYTHON_VERSION}", WARN, "sera téléchargé par uv (github.com doit être joignable)"
    )


def check_not_root(uid=None):
    uid = os.getuid() if uid is None else uid
    return Check(
        "Utilisateur", FAIL if uid == 0 else OK, "ne pas lancer en root" if uid == 0 else "non-root"
    )


def check_sudo():
    if shutil.which("sudo") is None:
        return Check("sudo", FAIL, "commande sudo introuvable")
    ok = subprocess.run(["sudo", "-n", "true"], capture_output=True).returncode == 0
    return Check(
        "sudo",
        OK if ok else WARN,
        "accès sans mot de passe" if ok else "mot de passe demandé pendant l'installation",
    )


def check_ram(meminfo="/proc/meminfo"):
    try:
        for line in Path(meminfo).read_text().splitlines():
            if line.startswith("MemTotal:"):
                mb = int(line.split()[1]) // 1024
                return Check(
                    "Mémoire",
                    OK if mb >= MIN_RAM_MB else WARN,
                    f"{mb} Mo (recommandé : {MIN_RAM_MB} Mo)",
                )
    except (OSError, ValueError):
        pass
    return Check("Mémoire", WARN, "impossible de lire /proc/meminfo")


def check_disk(path=None):
    path = path or str(Path.home())
    free_gb = shutil.disk_usage(path).free // 1024**3
    return Check(
        "Disque",
        OK if free_gb >= MIN_DISK_GB else FAIL,
        f"{free_gb} Go libres dans {path} ({MIN_DISK_GB} Go requis)",
    )


def check_locale(name):
    """La locale doit exister sur le système, sinon `createdb -l` échoue."""
    try:
        out = subprocess.run(["locale", "-a"], capture_output=True, text=True).stdout.split()
    except OSError:
        return Check("Locale", WARN, "commande locale introuvable")
    normalize = lambda s: s.lower().replace("utf-8", "utf8")
    ok = normalize(name) in {normalize(x) for x in out}
    return Check(
        "Locale",
        OK if ok else FAIL,
        f"{name} " + ("disponible" if ok else "absente (dpkg-reconfigure locales)"),
    )


def check_port_free(port):
    with socket.socket(socket.AF_INET, socket.SOCK_STREAM) as s:
        s.settimeout(1)
        used = s.connect_ex(("127.0.0.1", port)) == 0
    return Check(f"Port {port}", WARN if used else OK, "déjà utilisé" if used else "libre")


def check_host(url, timeout=5):
    try:
        urllib.request.urlopen(urllib.request.Request(url, method="HEAD"), timeout=timeout)
        return Check(url, OK)
    except urllib.error.HTTPError:
        return Check(url, OK, "joignable")  # une réponse HTTP, même d'erreur, prouve l'accès réseau
    except (urllib.error.URLError, socket.timeout, OSError) as e:
        return Check(url, FAIL, f"injoignable ({getattr(e, 'reason', e)}) : proxy à configurer ?")


def check_postgres(host="localhost"):
    if host not in ("localhost", "127.0.0.1", ""):
        return Check(
            "PostgreSQL", WARN, f"serveur distant ({host}) : création de base non vérifiée"
        )
    if shutil.which("psql") is None:
        return Check("PostgreSQL", WARN, "non installé (sera installé par apt)")
    r = subprocess.run(["pg_isready"], capture_output=True, text=True)
    return Check(
        "PostgreSQL", OK if r.returncode == 0 else WARN, r.stdout.strip() or "serveur arrêté"
    )


def run_all(settings=None, network=True):
    """Retourne la liste des `Check`. `settings` : dict de la config d'installation (optionnel)."""
    settings = settings or {}
    checks = [
        check_arch(),
        check_not_root(),
        check_sudo(),
        check_uv(),
        check_uv_python(),
        check_ram(),
        check_disk(),
        check_postgres(settings.get("pg_host", "localhost")),
    ]
    if settings.get("my_local"):
        checks.append(check_locale(settings["my_local"]))
    checks += [check_port_free(p) for p in REQUIRED_PORTS]
    if network:
        checks += [check_host(u) for u in EXTERNAL_HOSTS]
    return checks


def report(checks, style=None):
    """Affiche le rapport et retourne True si aucun contrôle bloquant n'a échoué."""
    style = style or Style.for_stream()
    paint = {OK: style.green, WARN: style.yellow, FAIL: style.red}
    for c in checks:
        print(
            f"[{paint[c.status](f'{c.status:<4}')}] {c.name}"
            + (style.gray(f" : {c.detail}") if c.detail else "")
        )
    failures = [c for c in checks if c.status == FAIL]
    warnings = sum(c.status == WARN for c in checks)
    summary = f"{len(failures)} échec(s), {warnings} avertissement(s)."
    print(
        "\n"
        + (
            style.red(summary)
            if failures
            else style.yellow(summary) if warnings else style.green(summary)
        )
    )
    return not failures
