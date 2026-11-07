"""Résumé affiché à la fin de l'installation : où l'application répond, avec quoi se connecter, et la suite."""

from pathlib import Path

from . import render
from .style import PLAIN


def format_summary(cfg, root, done=(), style=PLAIN):
    """Texte du résumé ; `cfg` est la configuration résolue (cf. render.resolve_config)."""
    root = Path(root)
    mode = cfg.get("MODE", "prod")
    dev = mode == "dev"
    port = cfg.get("dev_backend_port") or render.DEFAULTS.get("dev_backend_port", 8000)
    app_url, api_url = render.application_urls(
        cfg["my_url"], cfg.get("url_application_prefix_path"), port if dev else None
    )
    venv = root / cfg.get("venv_path", "backend/venv")
    st = style

    def row(label, value):
        return f"{st.gray(f'{label:<20}')}: {value}"

    title = "🎉 Résumé de l'installation" if st.enabled else "Résumé de l'installation"
    lines = ["", st.bold(title), st.gray("=" * 24)]
    lines.append(row("Mode", mode))
    lines.append(row("Application (dev)" if dev else "Application", st.cyan(f"{app_url}/")))
    lines.append(row("API", st.cyan(api_url)))
    lines.append(
        row(
            "Base PostgreSQL",
            f"{cfg['db_name']} sur {cfg['db_host']}:{cfg['db_port']}"
            f" (utilisateur {cfg['user_pg']}, mot de passe dans install/install.toml)",
        )
    )
    lines.append(row("Dossier", root))
    lines.append(row("Configuration", f"{root / 'config'} (geonature_config.toml)"))
    lines.append(row("Journal", root / "install" / "install.log"))
    lines.append("")
    lines.append(
        f"Connexion : {st.bold('admin / admin')} "
        + st.yellow("(compte de démonstration : changez ce mot de passe).")
    )
    lines.append("")
    lines.append(st.bold("Pour la suite :"))
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
