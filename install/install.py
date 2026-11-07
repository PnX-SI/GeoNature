#!/usr/bin/env python3
"""Installateur GeoNature. Bibliothèque standard uniquement : il tourne avant l'existence du venv.

python3 install/install.py --check [--config install.toml] [--offline]
python3 install/install.py --configure --config install/install.toml
python3 install/install.py --render-config --config install/install.toml [--force]
eval "$(python3 install/install.py --print-settings)"   # variables de install.toml pour un script shell
python3 install/install.py --config install/install.toml [--from-step NOM | --only NOM]
                           [--confirm-drop BASE] [--skip-check] [--reset-state]
python3 install/install.py update <tag|branche> [--dry-run] [--backup-dir DIR]
python3 install/install.py uninstall [--dry-run] [--yes] [--include-shared]
python3 install/install.py update --rollback [--backup DIR] [--restore-db --confirm-restore BASE]
"""

import argparse
import subprocess
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))

from installer import configure, preflight, render, steps, summary, uninstall, update  # noqa: E402
from installer.run import CommandError, Runner  # noqa: E402
from installer.state import State  # noqa: E402

ROOT = Path(__file__).resolve().parent.parent


def flag_usershub(cfg):
    return str(cfg.get("install_usershub_app", "")).lower() == "true"


def load_config(path):
    if not path:
        return {}
    try:
        import tomllib  # Python >= 3.11
    except ImportError:
        sys.exit("--config nécessite Python >= 3.11 (module tomllib) pour lancer l'installateur")

    with open(path, "rb") as f:
        return tomllib.load(f)


def update_main(argv):
    parser = argparse.ArgumentParser(
        prog="install.py update", description="Met à jour GeoNature sur place (git)"
    )
    parser.add_argument("ref", nargs="?", help="tag ou branche cible (ex. 2.18.0)")
    parser.add_argument(
        "--dry-run", action="store_true", help="liste les étapes sans rien modifier"
    )
    parser.add_argument(
        "--rollback",
        action="store_true",
        help="revient à la version d'avant la dernière mise à jour",
    )
    parser.add_argument(
        "--backup", help="sauvegarde à utiliser pour --rollback (défaut : la plus récente)"
    )
    parser.add_argument(
        "--restore-db", action="store_true", help="avec --rollback : restaure aussi la base"
    )
    parser.add_argument(
        "--confirm-restore",
        metavar="BASE",
        help="nom de la base à écraser (obligatoire avec --restore-db)",
    )
    parser.add_argument(
        "--backup-dir",
        default=str(Path.home() / "geonature_backups"),
        help="dossier des sauvegardes",
    )
    args = parser.parse_args(argv)
    if not args.ref and not args.rollback:
        parser.error("indiquez la version cible, ou --rollback")

    settings = ROOT / "config" / "settings.ini"
    toml = ROOT / "install" / "install.toml"
    if not settings.exists() and not toml.exists():
        print(f"{toml} introuvable : GeoNature ne semble pas installé ici.", file=sys.stderr)
        return 1
    ctx = steps.Context(
        root=ROOT,
        # install.toml fait foi ; settings.ini (anciennes installations) ne sert que de repli
        cfg=(
            render.resolve_config(load_config(toml) if toml.exists() else {}, settings)
            if toml.exists()
            else render.read_ini(settings)
        ),
        runner=Runner(ROOT / "install" / "update.log", cwd=ROOT),
        state=State(ROOT / "install" / ".state"),
    )
    try:
        if args.rollback:
            update.rollback(
                ctx, args.backup_dir, args.backup, args.restore_db, args.confirm_restore
            )
            print("Rollback terminé.")
        else:
            done = update.run_update(ctx, args.ref, args.backup_dir, dry_run=args.dry_run)
            print("\nMise à jour terminée." if done else "\nRien à faire.")
    except (update.UpdateError, CommandError, RuntimeError) as e:
        print(f"\n\033[91mÉchec : {e}\033[0m", file=sys.stderr)
        return 1
    return 0


def uninstall_main(argv):
    parser = argparse.ArgumentParser(
        prog="install.py uninstall",
        description="Retire les services systemd et la configuration Apache écrits par l'installateur "
        "(jamais la base de données)",
    )
    parser.add_argument(
        "--dry-run", action="store_true", help="liste les actions sans rien modifier"
    )
    parser.add_argument("--yes", action="store_true", help="ne demande pas de confirmation")
    parser.add_argument(
        "--include-shared",
        action="store_true",
        help="retire aussi le générateur systemd et les unités geonature-reload, partagés avec "
        "d'anciens montages à instances",
    )
    args = parser.parse_args(argv)

    plan = uninstall.build_plan(args.include_shared)
    if not plan:
        print("Aucun service ni configuration Apache de GeoNature à retirer.")
        return 0
    print("Actions prévues :")
    for label, _, _ in plan:
        print(f"  - {label}")
    print("Conservés : " + " ; ".join(uninstall.KEPT) + ".")
    if args.dry_run:
        return 0
    if not args.yes:
        if not sys.stdin.isatty():
            print("Confirmation impossible sans terminal : relancez avec --yes.", file=sys.stderr)
            return 1
        if input("Continuer ? [o/N] ").strip().lower() not in ("o", "oui", "y", "yes"):
            print("Abandon.")
            return 1
    ctx = steps.Context(
        root=ROOT,
        cfg={},
        runner=Runner(ROOT / "install" / "uninstall.log", cwd=ROOT),
        state=State(ROOT / "install" / ".state"),
    )
    try:
        uninstall.run(ctx, plan)
    except (CommandError, RuntimeError) as e:
        print(f"\n\033[91mÉchec : {e}\033[0m", file=sys.stderr)
        return 1
    print("\nDésinstallation terminée. La base de données n'a pas été touchée.")
    return 0


def print_settings(config):
    if not Path(config).exists():
        print(f"{config} introuvable : installez GeoNature ou précisez --config.", file=sys.stderr)
        return 1
    cfg = persist_password(config, load_config(config))
    sys.stdout.write(render.settings_text(cfg, ROOT / "config" / "settings.ini"))
    return 0


def persist_password(path, cfg):
    """Écrit dans install.toml le mot de passe PostgreSQL généré : il y reste, il n'est jamais régénéré."""
    if not path or cfg.get("user_pg_pass"):
        return cfg
    password = render.resolve_config(cfg, ROOT / "config" / "settings.ini")["user_pg_pass"]
    path = Path(path)
    path.write_text(configure.set_values(path.read_text(), {"user_pg_pass": password}))
    path.chmod(0o600)
    print(f"Mot de passe PostgreSQL généré et conservé dans {path}", file=sys.stderr)
    return {**cfg, "user_pg_pass": password}


def refresh_sudo():
    """`sudo -v` sur le terminal : le mot de passe est demandé avant la ligne de progression, jamais dessous."""
    if sys.stdin.isatty():
        subprocess.run(["sudo", "-v"], check=False)


def configure_main(args, parser):
    if not args.config:
        parser.error("--config install.toml est requis")
    path = Path(args.config)
    if not path.exists():
        path.write_text((ROOT / "install" / "install.sample.toml").read_text())
    if not sys.stdin.isatty():
        print("--configure demande un terminal interactif : éditez le fichier à la main.")
        return 1
    configure.configure(path, load_config(path))
    print(f"\nConfiguration écrite dans {path}")
    return 0


def main(argv=None):
    argv = sys.argv[1:] if argv is None else argv
    if argv and argv[0] == "update":
        return update_main(argv[1:])
    if argv and argv[0] == "uninstall":
        return uninstall_main(argv[1:])
    parser = argparse.ArgumentParser(description="Installateur GeoNature")
    parser.add_argument("--check", action="store_true", help="vérifie les prérequis puis s'arrête")
    parser.add_argument(
        "--config", help="fichier install.toml (active les contrôles locale/PostgreSQL)"
    )
    parser.add_argument(
        "--configure",
        action="store_true",
        help="demande interactivement les principaux paramètres et les écrit dans --config",
    )
    parser.add_argument(
        "--offline", action="store_true", help="ne teste pas l'accès aux domaines externes"
    )
    parser.add_argument(
        "--render-config",
        action="store_true",
        help="génère config/geonature_config.toml",
    )
    parser.add_argument(
        "--print-settings",
        action="store_true",
        help="affiche les variables de install.toml (clé=valeur, à passer à eval) pour les scripts shell",
    )
    parser.add_argument(
        "--force", action="store_true", help="écrase les fichiers de configuration existants"
    )
    parser.add_argument(
        "--from-step", help=f"reprend à cette étape ({', '.join(s.name for s in steps.STEPS)})"
    )
    parser.add_argument("--only", help="n'exécute que cette étape")
    parser.add_argument(
        "--confirm-drop", metavar="BASE", help="autorise la suppression de la base nommée"
    )
    parser.add_argument("--skip-check", action="store_true", help="n'exécute pas le pré-vol")
    parser.add_argument(
        "--reset-state",
        action="store_true",
        help="oublie les étapes terminées (seulement celle de --only s'il est donné)",
    )
    args = parser.parse_args(argv)

    if args.configure:
        return configure_main(args, parser)

    if args.print_settings:
        return print_settings(args.config or str(ROOT / "install" / "install.toml"))

    cfg = load_config(args.config)
    if args.check:
        ok = preflight.report(preflight.run_all(cfg, network=not args.offline))
        return 0 if ok else 1

    if not args.config:
        parser.error("--config install.toml est requis")
    cfg = persist_password(args.config, cfg)
    written = render.render_all(ROOT, cfg, force=args.force)
    for path in written:
        print(f"écrit : {path}")
    if not written:
        print("Fichiers de configuration déjà présents, rien à faire (--force pour les régénérer).")
    if args.render_config:
        return 0

    problems = render.config_mismatches(
        ROOT, render.resolve_config(cfg, ROOT / "config" / "settings.ini")
    )
    if problems and not args.force:
        print("Les fichiers de configuration existants ne correspondent pas à install.toml :")
        for problem in problems:
            print(f"  - {problem}")
        print(
            "Ils ne sont jamais réécrits : les commandes utiliseraient l'ancienne configuration.\n"
            "Alignez install.toml sur ces fichiers, lancez l'installation dans une copie propre du dépôt, "
            "ou relancez avec --force pour les régénérer (écrase config/geonature_config.toml)."
        )
        return 1

    resolved = render.resolve_config(cfg, ROOT / "config" / "settings.ini")
    if not args.skip_check and not preflight.report(
        preflight.run_all(resolved, network=not args.offline)
    ):
        print("Prérequis manquants : corrigez-les ou relancez avec --skip-check.")
        return 1

    state = State(ROOT / "install" / ".state")
    if args.reset_state:
        state.reset(args.only)
    ctx = steps.Context(
        root=ROOT,
        cfg=resolved,
        runner=Runner(ROOT / "install" / "install.log", cwd=ROOT),
        state=state,
        confirm_drop=args.confirm_drop,
        before_step=refresh_sudo,
    )
    try:
        done = steps.run_steps(ctx, from_step=args.from_step, only=args.only)
    except (CommandError, RuntimeError, ValueError) as e:
        print(f"\n\033[91mÉchec : {e}\033[0m", file=sys.stderr)
        return 1
    print(f"\nTerminé ({len(done)} étape(s) exécutée(s)).")
    if not args.only:
        print(summary.format_summary(resolved, ROOT, done))
    if flag_usershub(resolved):
        print(
            "UsersHub (install_usershub_app) n'est pas géré ici : installez-le séparément (https://usershub.readthedocs.io)."
        )
    return 0


if __name__ == "__main__":
    sys.exit(main())
