"""Résumé affiché à la fin de l'installation : où l'application répond, avec quoi se connecter, et la suite."""

from pathlib import Path

from . import render


def format_summary(cfg, root, done=()):
    """Texte du résumé ; `cfg` est la configuration résolue (cf. render.resolve_config)."""
    root = Path(root)
    mode = cfg.get("MODE", "prod")
    dev = mode == "dev"
    port = cfg.get("dev_backend_port") or render.DEFAULTS.get("dev_backend_port", 8000)
    app_url, api_url = render.application_urls(
        cfg["my_url"], cfg.get("url_application_prefix_path"), port if dev else None
    )
    venv = root / cfg.get("venv_path", "backend/venv")
    lines = ["", "Résumé de l'installation", "========================"]
    lines.append(f"Mode                : {mode}")
    lines.append(
        f"Application         : {app_url}/" if not dev else f"Application (ng serve) : {app_url}/"
    )
    lines.append(f"API                 : {api_url}")
    lines.append(
        f"Base PostgreSQL     : {cfg['db_name']} sur {cfg['db_host']}:{cfg['db_port']}"
        f" (utilisateur {cfg['user_pg']}, mot de passe dans config/settings.ini)"
    )
    lines.append(f"Dossier             : {root}")
    lines.append(f"Configuration       : {root / 'config'} (settings.ini, geonature_config.toml)")
    lines.append(f"Journal             : {root / 'install' / 'install.log'}")
    lines.append("")
    lines.append("Connexion : admin / admin (compte de démonstration : changez ce mot de passe).")
    lines.append("")
    lines.append("Pour la suite :")
    if dev:
        lines += [
            f"  - backend  : source {venv}/bin/activate && geonature dev-back --port {port}",
            f"  - frontend : cd {root / 'frontend'} && npm run start",
        ]
    else:
        lines += [
            "  - état des services : sudo systemctl status geonature geonature-worker",
            "  - journaux          : journalctl -u geonature -f",
        ]
    lines.append(f"  - mise à jour : python3 {root / 'install' / 'install.py'} update X.Y.Z")
    return "\n".join(lines)
