#!/usr/bin/env python3
"""Point d'entrée de l'image Docker du backend GeoNature.

Crée/met à jour la base (migrations, TAXREF, sensibilité…) puis lance la commande de l'image (gunicorn),
sauf si la variable d'environnement GEONATURE_SKIP_POPULATE_DB vaut « true ».

Le peuplement est celui de l'installateur (install/installer/steps.py, `populate_database`) ; ses options
sont lues dans l'environnement, avec les mêmes noms que dans install.toml : srid_local, install_bdc_statuts,
taxref_region, add_sample_data, install_sig_layers, install_grid_layer[_N], install_ref_sensitivity,
install_default_dem, vectorise_dem. S'y ajoutent usershub / usershub_samples et GEONATURE_SUPERGRANT_ARGS.
"""

import os
import shlex
import subprocess
import sys
from pathlib import Path

# Dans l'image, le paquet `installer` est à côté du script ; dans le dépôt, il est dans install/ (dossier parent).
HERE = Path(__file__).resolve().parent
sys.path[:0] = [str(HERE), str(HERE.parent)]

from installer import steps  # noqa: E402

READY_FILE = Path("/tmp/ready")
# Variables pouvant être fournies par un fichier (secrets Docker) : VAR_FILE=/run/secrets/…
FILE_ENV = (
    "GEONATURE_SECRET_KEY",
    "GEONATURE_SQLALCHEMY_DATABASE_URI",
    "GEONATURE_SENTRY_DSN",
    "GEONATURE_MAIL_CONFIG__MAIL_USERNAME",
    "GEONATURE_MAIL_CONFIG__MAIL_PASSWORD",
)


def file_env(environ, var):
    """`VAR_FILE` remplit `VAR` depuis un fichier (même convention que l'image officielle de PostgreSQL)."""
    path = environ.get(f"{var}_FILE")
    if environ.get(var) and path:
        raise SystemExit(f"error: both {var} and {var}_FILE are set (but are exclusive)")
    if path:
        environ[var] = Path(path).read_text().rstrip("\n")
        del environ[f"{var}_FILE"]


def is_true(environ, name):
    return environ.get(name, "").lower() == "true"


def geonature(*args, check=True):
    # check=False ne sert qu'aux sondes (« TAXREF est-il déjà chargé ? ») dont l'échec est attendu : sans bruit
    return subprocess.run(
        ["geonature", *args], check=check, stderr=None if check else subprocess.DEVNULL
    )


def populate(environ, run=geonature):
    cfg = {"srid_local": "2154", **environ}
    steps.populate_database(run, cfg)
    if is_true(environ, "usershub"):
        run("db", "upgrade", "usershub@head")
        if is_true(environ, "usershub_samples"):
            run("db", "upgrade", "usershub-samples@head")
    run("upgrade-modules-db")
    if environ.get("GEONATURE_SUPERGRANT_ARGS"):
        run(
            "permissions", "supergrant", "--yes", *shlex.split(environ["GEONATURE_SUPERGRANT_ARGS"])
        )


def main(argv, environ=os.environ, run=geonature, execvp=os.execvp):
    READY_FILE.unlink(missing_ok=True)
    for var in FILE_ENV:
        file_env(environ, var)
    if not is_true(environ, "GEONATURE_SKIP_POPULATE_DB"):
        populate(environ, run)
    READY_FILE.touch()
    execvp(argv[0], argv)


if __name__ == "__main__":
    main(sys.argv[1:])
