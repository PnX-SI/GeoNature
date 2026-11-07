"""Désinstallation des services et de la configuration système écrits par l'installateur.

Ne touche jamais à la base de données ni au rôle PostgreSQL, à `config/`, au code, au venv, aux médias ni aux
sauvegardes : seuls sont retirés les services systemd, la configuration Apache, `logrotate`, `tmpfiles.d` et
les marqueurs d'étapes (`install/.state`).
"""

import os
from pathlib import Path

SERVICES = ("geonature.service", "geonature-worker.service")
SYSTEMD_DIR = "/etc/systemd/system"

OWN_FILES = (
    *(f"{SYSTEMD_DIR}/{unit}" for unit in SERVICES),
    "/etc/tmpfiles.d/geonature.conf",
    "/etc/logrotate.d/geonature",
)
# Partagés avec d'anciens montages à instances (geonature@.service…) : retirés uniquement sur demande
SHARED_FILES = (
    "/etc/systemd/system-generators/geonature-generator",
    f"{SYSTEMD_DIR}/geonature-reload@.path",
    f"{SYSTEMD_DIR}/geonature-reload.service",
)
APACHE_SITES = ("geonature", "geonature_maintenance")
APACHE_FILES = (
    "/etc/apache2/sites-available/geonature.conf",
    "/etc/apache2/sites-available/geonature_maintenance.conf",
    "/etc/apache2/conf-available/geonature.conf",
    "/var/www/geonature_maintenance/index.html",
)

KEPT = (
    "la base de données et son rôle PostgreSQL",
    "install/install.toml (avec le mot de passe de la base) et config/",
    "le code, le venv, les médias et ~/geonature_backups",
)


def build_plan(include_shared=False, exists=os.path.lexists):
    """Liste de (libellé, commande, ignorer_un_échec). Ne retient que ce qui existe sur la machine."""
    plan = []
    for unit in SERVICES:
        if exists(f"{SYSTEMD_DIR}/{unit}"):
            plan.append(
                (
                    f"arrêt et désactivation de {unit}",
                    ["sudo", "systemctl", "disable", "--now", unit],
                    True,
                )
            )
    systemd_files = [
        f for f in (*OWN_FILES, *(SHARED_FILES if include_shared else ())) if exists(f)
    ]
    for path in systemd_files:
        plan.append((f"suppression de {path}", ["sudo", "rm", "-f", path], False))
    if any(f.startswith(("/etc/systemd", "/etc/tmpfiles.d")) for f in systemd_files):
        plan.append(("rechargement de systemd", ["sudo", "systemctl", "daemon-reload"], False))

    apache = False
    for site in APACHE_SITES:
        if exists(f"/etc/apache2/sites-enabled/{site}.conf"):
            plan.append((f"désactivation du site Apache {site}", ["sudo", "a2dissite", site], True))
            apache = True
    if exists("/etc/apache2/conf-enabled/geonature.conf"):
        plan.append(
            (
                "désactivation de la configuration Apache geonature",
                ["sudo", "a2disconf", "geonature"],
                True,
            )
        )
        apache = True
    for path in APACHE_FILES:
        if exists(path):
            plan.append((f"suppression de {path}", ["sudo", "rm", "-f", path], False))
            apache = True
    if apache:
        plan.append(
            ("vérification de la configuration Apache", ["sudo", "apachectl", "configtest"], False)
        )
        plan.append(("rechargement d'Apache", ["sudo", "systemctl", "reload", "apache2"], False))
    return plan


def run(ctx, plan):
    for label, cmd, tolerate in plan:
        ctx.log(label)
        ctx.runner.run(cmd, check=not tolerate)
    ctx.state.reset()
