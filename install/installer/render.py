"""Génération des fichiers de configuration à partir de `install.toml`, sans `sed`.

`config/settings.ini` est écrit depuis `DEFAULTS` et `install.toml` ; `geonature_config.toml.sample` sert de
modèle (les commentaires sont conservés) et seules les lignes `CLÉ = valeur` de premier niveau sont remplacées.
"""

import json
import os
import re
import secrets
import shlex
from pathlib import Path
from urllib.parse import quote, unquote, urlsplit

# Clés de settings.ini lues par les anciens scripts (`. settings.ini`) ; les valeurs sont donc
# protégées pour le shell.
SETTINGS_KEYS = (
    "MODE",
    "venv_path",
    "my_local",
    "my_url",
    "url_application_prefix_path",
    "drop_apps_db",
    "db_host",
    "db_port",
    "db_name",
    "user_pg",
    "user_pg_pass",
    "srid_local",
    "default_language",
    "install_bdc_statuts",
    "taxref_region",
    "install_sig_layers",
    "install_grid_layer",
    "install_default_dem",
    "vectorise_dem",
    "add_sample_data",
    "install_ref_sensitivity",
    "install_module_validation",
    "install_module_occhab",
    "proxy_http",
    "proxy_https",
    "dev_backend_port",
)

# Valeurs prises quand `install.toml` ne dit rien (`user_pg_pass` absent : mot de passe généré).
DEFAULTS = {
    "MODE": "prod",
    "venv_path": "backend/venv",  # géré par uv, cf. steps.py
    "my_local": "fr_FR.UTF-8",
    "my_url": "http://url.com/",
    "url_application_prefix_path": "geonature",
    "drop_apps_db": "false",
    "db_host": "localhost",
    "db_port": "5432",
    "db_name": "geonature2db",
    "user_pg": "geonatadmin",
    "srid_local": "2154",
    "default_language": "fr",
    "install_bdc_statuts": "false",
    "taxref_region": "fr",
    "install_sig_layers": "true",
    "install_grid_layer": "true",
    "install_default_dem": "true",
    "vectorise_dem": "false",
    "add_sample_data": "true",
    "install_ref_sensitivity": "true",
    "install_module_validation": "true",
    "install_module_occhab": "true",
    "dev_backend_port": "8000",  # mode dev : port du backend (`geonature dev-back`)
}

SETTINGS_HEADER = (
    "## Généré par install/install.py à partir de install.toml.\n"
    "## Lu par le Makefile et les scripts de data/ ; pour modifier l'installation, éditez install.toml.\n"
)


def _scalar(value):
    if isinstance(value, bool):
        return "true" if value else "false"
    return str(value)


def format_ini(values):
    """Fichier `clé=valeur` lisible par `. settings.ini` : les valeurs sont protégées pour le shell."""
    lines = [f"{k}={shlex.quote(_scalar(v))}" for k, v in values.items()]
    return SETTINGS_HEADER + "\n".join(lines) + "\n"


def set_toml_values(template, values):
    """Remplace `CLÉ = ...` de premier niveau (avant la première section) par une chaîne TOML valide."""
    remaining = dict(values)
    out, in_section = [], False
    for line in template.splitlines():
        if line.startswith("["):
            in_section = True
        m = None if in_section else re.match(r"^([A-Z_][A-Z0-9_]*)\s*=", line)
        if m and m.group(1) in remaining:
            out.append(
                f"{m.group(1)} = {json.dumps(remaining.pop(m.group(1)), ensure_ascii=False)}"
            )
        else:
            out.append(line)
    if remaining:
        raise ValueError(f"clés absentes du modèle : {', '.join(remaining)}")
    return "\n".join(out) + "\n"


def application_urls(my_url, prefix, dev_backend_port=None):
    """(URL_APPLICATION, API_ENDPOINT). Calcul historique de l'ancien 01_install_backend.sh.

    En mode dev (`dev_backend_port` donné), il n'y a pas d'Apache : l'API est le backend lui-même, sur
    son port, et `my_url` est l'adresse du serveur de développement du frontend (`ng serve`).
    """
    base = my_url.rstrip("/")
    prefix = (prefix or "").strip("/")
    app = f"{base}/{prefix}" if prefix else base
    if dev_backend_port:
        parts = urlsplit(my_url)
        return app, f"{parts.scheme}://{parts.hostname}:{dev_backend_port}"
    return app, f"{app}/api"


def database_uri(cfg):
    """Utilisateur et mot de passe sont encodés : `@ / : # %` ne cassent plus l'URI."""
    user, password = quote(cfg["user_pg"], safe=""), quote(cfg["user_pg_pass"], safe="")
    return (
        f"postgresql://{user}:{password}@{cfg['db_host']}:{cfg['db_port']}/{cfg['db_name']}"
        "?application_name=geonature"
    )


def read_ini_value(path, key):
    """Lit une valeur déjà écrite dans un fichier settings.ini (pour ne pas régénérer un secret)."""
    try:
        for line in Path(path).read_text().splitlines():
            if line.startswith(f"{key}="):
                parts = shlex.split(line.partition("=")[2])
                return parts[0] if parts else ""
    except OSError:
        pass
    return ""


def read_ini(path):
    """Lit tout un settings.ini déjà généré (valeurs protégées pour le shell) sous forme de dict."""
    cfg = {}
    for line in Path(path).read_text().splitlines():
        m = re.match(r"^([A-Za-z_][A-Za-z0-9_]*)=(.*)$", line)
        if m:
            parts = shlex.split(m.group(2))
            cfg[m.group(1)] = parts[0] if parts else ""
    return cfg


def resolve_config(user_cfg, existing_settings=None):
    """Fusionne `DEFAULTS`, install.toml et secrets.

    Le mot de passe PostgreSQL absent est repris de settings.ini s'il existe, sinon généré :
    relancer l'installation ne change donc jamais un mot de passe déjà appliqué à la base.
    """
    cfg = dict(DEFAULTS)
    cfg.update(user_cfg)  # une valeur vide est un choix (ex. préfixe d'URL vide = racine)
    if "mode" in cfg:  # install.toml accepte `mode`, settings.ini utilise `MODE`
        cfg["MODE"] = cfg.pop("mode")
    if not user_cfg.get("user_pg_pass"):
        cfg["user_pg_pass"] = (
            read_ini_value(existing_settings, "user_pg_pass") if existing_settings else ""
        ) or secrets.token_hex(16)
    return cfg


def config_mismatches(root, cfg):
    """Écarts entre les fichiers de configuration existants et `cfg` (install.toml + défauts).

    Les fichiers existants ne sont jamais réécrits : si `install.toml` change la base ou le mode, les
    commandes `geonature` continueraient sinon d'utiliser l'ancienne base. Retourne une liste de phrases.
    """
    config_dir = Path(root) / "config"
    problems = []
    settings = config_dir / "settings.ini"
    if settings.exists():
        existing = read_ini(settings)
        for key in ("MODE", "db_host", "db_port", "db_name", "user_pg"):
            if key in existing and str(existing[key]) != str(cfg.get(key)):
                problems.append(
                    f"settings.ini : {key}={existing[key]} (install.toml : {cfg.get(key)})"
                )
    gn_config = config_dir / "geonature_config.toml"
    if gn_config.exists():
        m = re.search(r'^SQLALCHEMY_DATABASE_URI\s*=\s*"([^"]*)"', gn_config.read_text(), re.M)
        if m:
            uri = urlsplit(m.group(1))
            found = {
                "db_name": uri.path.lstrip("/"),
                "user_pg": unquote(uri.username or ""),
                "db_port": str(uri.port or 5432),
            }
            for key, value in found.items():
                if value != str(cfg.get(key)):
                    problems.append(
                        f"geonature_config.toml : {key}={value} (install.toml : {cfg.get(key)})"
                    )
    return problems


def write_file(path, content, force=False, mode=0o600):
    """Écrit le fichier sauf s'il existe déjà (sans `force`). Retourne True si écrit."""
    path = Path(path)
    if path.exists() and not force:
        return False
    path.parent.mkdir(parents=True, exist_ok=True)
    fd = os.open(path, os.O_WRONLY | os.O_CREAT | os.O_TRUNC, mode)
    with os.fdopen(fd, "w") as f:
        f.write(content)
    os.chmod(path, mode)
    return True


def render_all(root, user_cfg, force=False, settings_only=False):
    """Génère config/settings.ini (et config/geonature_config.toml sauf `settings_only`).

    Retourne les fichiers écrits.
    """
    config_dir = Path(root) / "config"
    settings_path = config_dir / "settings.ini"
    cfg = resolve_config(user_cfg, settings_path)

    written = []
    settings = {k: cfg[k] for k in SETTINGS_KEYS if k in cfg}
    if write_file(settings_path, format_ini(settings), force):
        written.append(settings_path)
    if settings_only:
        return written

    app_url, api_url = application_urls(
        cfg["my_url"],
        cfg.get("url_application_prefix_path"),
        dev_backend_port=cfg["dev_backend_port"] if cfg.get("MODE") == "dev" else None,
    )
    gn_path = config_dir / "geonature_config.toml"
    gn_values = {
        "SQLALCHEMY_DATABASE_URI": database_uri(cfg),
        "URL_APPLICATION": app_url,
        "API_ENDPOINT": api_url,
        "SECRET_KEY": secrets.token_hex(32),
        "DEFAULT_LANGUAGE": cfg.get("default_language", "fr"),
    }
    gn_sample = (config_dir / "geonature_config.toml.sample").read_text()
    if write_file(gn_path, set_toml_values(gn_sample, gn_values), force):
        written.append(gn_path)
    return written
