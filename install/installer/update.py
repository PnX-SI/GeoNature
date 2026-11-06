"""Mise à jour de GeoNature sur place (un seul dossier, jamais de second clone ni d'archive).

    git fetch --tags ; git checkout <tag> ; git submodule update

Avant toute modification : sauvegarde de la base (pg_dump) et des fichiers non versionnés, et
enregistrement du commit courant. `rollback` revient à ce commit ; la base n'est restaurée que sur
demande explicite.
"""

import json
import re
import secrets
import shutil
import time
from pathlib import Path

from . import preflight, render, steps
from .preflight import FAIL, OK, WARN, Check
from .run import CommandError
from .state import State

SERVICES = ("geonature", "geonature-worker", "usershub")
# En dessous, la mise à jour suppose de déplacer des dossiers (static -> media, TaxHub, module d'import) :
# cela relève des procédures des anciennes versions (ancien install/migration/migration.sh, deux dossiers).
MIN_VERSION = (2, 15, 0)
# Fichiers versionnés réécrits par les outils eux-mêmes (uv sync) : ignorés au pré-vol, restaurés avant le checkout.
GENERATED_FILES = ("uv.lock",)
BACKUP_FILES = ("environ", "frontend/src/assets/config.json")
IN_PROGRESS = "update_in_progress"


class UpdateError(RuntimeError):
    pass


def parse_version(text):
    m = re.search(r"(\d+)\.(\d+)\.(\d+)", text or "")
    return tuple(int(x) for x in m.groups()) if m else None


def fmt(v):
    return ".".join(map(str, v)) if v else "inconnue"


# --- git -------------------------------------------------------------------------------------


# Certains sous-modules imbriqués (Utils-Flask-SQLAlchemy-Geo) déclarent une URL SSH : sans clé GitHub,
# le clonage échoue. Réécriture en HTTPS pour cette commande uniquement, rien n'est écrit dans la config.
SUBMODULE_UPDATE = [
    "-c",
    "url.https://github.com/.insteadOf=git@github.com:",
    "submodule",
    "update",
    "--init",
    "--recursive",
]


def fetch_command(shallow):
    """Un clone superficiel (get-geonature.sh) le reste : sans --depth, `--tags` rapatrie tout l'historique."""
    return ["git", "fetch", "--tags", "--force", *(["--depth", "1"] if shallow else []), "origin"]


def git(ctx, *args, check=True):
    return ctx.runner.run(["git", *args], cwd=ctx.root, check=check)


def git_out(ctx, *args):
    r = ctx.runner.capture(["git", *args], cwd=ctx.root)
    if r.returncode != 0:
        raise UpdateError(f"git {' '.join(args)} : {r.stderr.strip()}")
    return r.stdout.strip()


def current_commit(ctx):
    return git_out(ctx, "rev-parse", "HEAD")


def tracked_changes(ctx):
    """Fichiers versionnés modifiés (les fichiers ignorés ou non suivis, comme config/, sont hors sujet)."""
    lines = git_out(ctx, "status", "--porcelain", "--untracked-files=no").splitlines()
    # git_out() retire les blancs de tête : on lit le nom après le code d'état, sans position fixe
    return [l for l in lines if l and l.split(None, 1)[1] not in GENERATED_FILES]


def version_at(ctx, ref):
    r = ctx.runner.capture(["git", "show", f"{ref}:VERSION"], cwd=ctx.root)
    return parse_version(r.stdout) if r.returncode == 0 else None


# --- pré-vol ---------------------------------------------------------------------------------


def check_transition(current, target, same_commit):
    if same_commit:
        return Check("Version cible", FAIL, "déjà sur ce commit, rien à mettre à jour")
    if current is None or target is None:
        return Check(
            "Version cible",
            FAIL,
            f"version illisible (actuelle {fmt(current)}, cible {fmt(target)})",
        )
    if current < MIN_VERSION:
        return Check(
            "Version actuelle",
            FAIL,
            f"{fmt(current)} < {fmt(MIN_VERSION)} : passez d'abord à {fmt(MIN_VERSION)} avec la procédure "
            f"de cette version (git show {fmt(MIN_VERSION)}:install/migration/migration.sh), puis relancez",
        )
    if target < current:
        return Check(
            "Version cible",
            FAIL,
            f"{fmt(target)} est plus ancienne que {fmt(current)} (utilisez --rollback)",
        )
    return Check("Version cible", OK, f"{fmt(current)} → {fmt(target)}")


def run_preflight(ctx, ref):
    checks = []
    if not (ctx.root / ".git").exists():
        return [Check("Dépôt git", FAIL, f"{ctx.root} n'est pas un clone git")]
    checks.append(Check("Dépôt git", OK))
    dirty = tracked_changes(ctx)
    checks.append(
        Check(
            "Arbre git",
            FAIL,
            f"{len(dirty)} fichier(s) versionné(s) modifié(s) : {dirty[0]} … (commitez ou annulez)",
        )
        if dirty
        else Check("Arbre git", OK, "propre")
    )
    shallow = ctx.runner.capture(["git", "rev-parse", "--is-shallow-repository"], cwd=ctx.root)
    fetched = ctx.runner.run(
        fetch_command(shallow.stdout.strip() == "true"), cwd=ctx.root, check=False
    )
    checks.append(
        Check("git fetch", OK)
        if fetched.returncode == 0
        else Check("git fetch", FAIL, "origine injoignable")
    )
    resolved = ctx.runner.capture(
        ["git", "rev-parse", "--verify", "--quiet", f"{ref}^{{commit}}"], cwd=ctx.root
    )
    if resolved.returncode != 0:
        checks.append(Check("Référence", FAIL, f"'{ref}' introuvable (tag ou branche)"))
        return checks
    target_commit = resolved.stdout.strip()
    checks.append(Check("Référence", OK, f"{ref} → {target_commit[:10]}"))
    checks.append(
        check_transition(
            version_at(ctx, "HEAD"),
            version_at(ctx, target_commit),
            target_commit == current_commit(ctx),
        )
    )
    free_gb = shutil.disk_usage(Path.home()).free // 1024**3
    checks.append(
        Check(
            "Disque (sauvegarde)",
            OK if free_gb >= 5 else WARN,
            f"{free_gb} Go libres dans {Path.home()}",
        )
    )
    return checks


# --- sauvegarde ------------------------------------------------------------------------------


def make_backup(ctx, ref, backup_root, now=None):
    """Sauvegarde base + fichiers non versionnés + commit courant. Retourne le dossier créé."""
    cfg = ctx.cfg
    stamp = time.strftime("%Y%m%d-%H%M%S", now or time.localtime())
    backup = Path(backup_root) / f"{stamp}_{safe_name(ref)}"
    backup.mkdir(parents=True, mode=0o700)

    config_dir = backup / "config"
    config_dir.mkdir()
    for pattern in ("*.ini", "*.toml"):
        for f in (ctx.root / "config").glob(pattern):
            shutil.copy2(f, config_dir / f.name)
    for rel in BACKUP_FILES:
        src = ctx.root / rel
        if src.is_file():
            shutil.copy2(src, backup / Path(rel).name)
    if (ctx.root / "custom").is_dir():
        shutil.copytree(ctx.root / "custom", backup / "custom")

    dump = backup / "database.dump"
    ctx.runner.run(["sudo", "-u", "postgres", "pg_dump", "-Fc", cfg["db_name"]], stdout_path=dump)
    dump.chmod(0o600)

    manifest = {
        "from_commit": current_commit(ctx),
        "from_version": fmt(version_at(ctx, "HEAD")),
        "to_ref": ref,
        "db_name": cfg["db_name"],
        "date": stamp,
        "status": "in_progress",
        "not_backed_up": ["backend/media (non versionné, non modifié par la mise à jour)"],
    }
    write_manifest(backup, manifest)
    return backup


def safe_name(ref):
    return re.sub(r"[^A-Za-z0-9._-]", "_", ref)


def write_manifest(backup, manifest):
    (backup / "manifest.json").write_text(json.dumps(manifest, indent=2, ensure_ascii=False))


def read_manifest(backup):
    return json.loads((Path(backup) / "manifest.json").read_text())


def latest_backup(backup_root):
    candidates = sorted(p for p in Path(backup_root).glob("*") if (p / "manifest.json").exists())
    if not candidates:
        raise UpdateError(f"Aucune sauvegarde trouvée dans {backup_root}")
    return candidates[-1]


# --- étapes ----------------------------------------------------------------------------------


def existing_services(ctx):
    return [
        s
        for s in SERVICES
        if ctx.runner.capture(["systemctl", "cat", f"{s}.service"]).returncode == 0
    ]


def step_stop(ctx):
    for service in existing_services(ctx):
        ctx.runner.run(["sudo", "systemctl", "stop", service])


def step_checkout(ctx):
    for name in GENERATED_FILES:
        git(ctx, "checkout", "--", name, check=False)
    git(ctx, "checkout", ctx.extra["ref"])
    git(ctx, *SUBMODULE_UPDATE)


def ensure_secret_key(path):
    """Régénère SECRET_KEY si elle fait moins de 20 caractères. Retourne True si modifiée."""
    import tomllib

    path = Path(path)
    text = path.read_text()
    if len(tomllib.loads(text).get("SECRET_KEY", "")) >= 20:
        return False
    path.write_text(render.set_toml_values(text, {"SECRET_KEY": secrets.token_hex(32)}))
    return True


def step_secret(ctx):
    if ensure_secret_key(ctx.root / "config" / "geonature_config.toml"):
        ctx.log("SECRET_KEY trop courte : régénérée (les sessions en cours sont invalidées).")


def step_frontend_deps(ctx):
    ctx.runner.run(
        [
            "bash",
            "-c",
            steps.NVM_SHELL + 'cd "$1" && nvm use && npm ci --omit=dev',
            "_",
            str(ctx.root / "frontend"),
        ]
    )


def step_database(ctx):
    # Occtax doit être au moins en 4c97453a2d1a *avant* GeoNature (NOT NULL sur id_source dans la synthèse),
    # cf. https://github.com/PnX-SI/GeoNature/issues/2186#issuecomment-1337684933
    heads = steps.geonature_output(ctx, "db", "heads")
    if "(occtax)" in heads:
        ctx.geonature("db", "upgrade", "occtax@4c97453a2d1a")
    ctx.geonature("db", "autoupgrade")
    ctx.geonature("upgrade-modules-db")
    if "(validation)" in heads:  # branche Alembic ajoutée avec GN 2.13
        ctx.geonature("db", "upgrade", "validation@head")


def step_completion(ctx):
    ctx.geonature("generate-completion", "--output", str(ctx.venv / "bin" / steps.COMPLETION_NAME))


def step_frontend(ctx):
    config = ctx.root / "frontend" / "src" / "assets" / "config.json"
    config.write_text(
        steps.frontend_config_json(steps.geonature_output(ctx, "get-config", "API_ENDPOINT"))
    )
    ctx.geonature("update-configuration")


def step_start(ctx):
    for service in existing_services(ctx):
        ctx.runner.run(["sudo", "systemctl", "start", service])


UPDATE_STEPS = [
    steps.Step("stop", "Arrêt des services", step_stop),
    steps.Step("checkout", "Récupération de la nouvelle version (git)", step_checkout),
    steps.Step("secret", "Contrôle de la SECRET_KEY", step_secret),
    steps.Step("nvm", "Node (nvm)", steps.step_nvm),
    steps.Step("backend", "Backend Python (uv) et paquets npm", steps.step_backend),
    steps.Step("frontend_deps", "Dépendances npm du frontend", step_frontend_deps),
    steps.Step("systemd", "Services systemd", steps.step_systemd),
    steps.Step("database", "Migrations de la base", step_database),
    steps.Step("completion", "Autocomplétion", step_completion),
    steps.Step("frontend", "Configuration et build du frontend", step_frontend),
    steps.Step("apache", "Apache", steps.step_apache),
    steps.Step("start", "Redémarrage des services", step_start),
]


# --- orchestration ---------------------------------------------------------------------------


def pointer_file(root):
    return Path(root) / "install" / ".state" / IN_PROGRESS


def start_or_resume(ctx, ref, backup_root, log=print):
    """Retourne (dossier de sauvegarde, reprise?). Une mise à jour interrompue doit être reprise avec la même cible."""
    pointer = pointer_file(ctx.root)
    if pointer.exists():
        backup = Path(pointer.read_text().strip())
        manifest = read_manifest(backup)
        if manifest["to_ref"] != ref:
            raise UpdateError(
                f"Une mise à jour vers '{manifest['to_ref']}' est en cours (sauvegarde : {backup}). "
                f"Relancez-la avec la même cible, ou annulez avec --rollback."
            )
        log(f"Reprise de la mise à jour vers {ref} (sauvegarde : {backup}).")
        return backup, True
    backup = make_backup(ctx, ref, backup_root)
    pointer.parent.mkdir(parents=True, exist_ok=True)
    pointer.write_text(str(backup))
    log(f"Sauvegarde créée : {backup}")
    return backup, False


def run_update(ctx, ref, backup_root, dry_run=False):
    if dry_run:
        for s in UPDATE_STEPS:
            ctx.log(f"[dry-run] {s.title}")
        return []
    resuming = pointer_file(ctx.root).exists()
    if not resuming and not preflight.report(run_preflight(ctx, ref)):
        raise UpdateError("Pré-vol en échec, aucune modification effectuée.")
    backup, _ = start_or_resume(ctx, ref, backup_root, ctx.log)
    ctx.extra["ref"] = ref
    ctx.state = State(backup / "steps")
    try:
        done = steps.run_steps(ctx, UPDATE_STEPS)
    except (CommandError, RuntimeError) as e:
        raise UpdateError(
            f"{e}\n\nLa mise à jour est interrompue : relancez la même commande pour reprendre, ou "
            f"`update --rollback` pour revenir en arrière (sauvegarde : {backup})."
        ) from e
    manifest = read_manifest(backup)
    write_manifest(backup, {**manifest, "status": "done"})
    pointer_file(ctx.root).unlink(missing_ok=True)
    return done


def rollback(ctx, backup_root, backup=None, restore_db=False, confirm_restore=None):
    """Revient au commit d'avant la mise à jour et restaure les fichiers. La base n'est touchée que sur demande."""
    backup = Path(backup) if backup else latest_backup(backup_root)
    manifest = read_manifest(backup)
    db = manifest["db_name"]
    if restore_db and confirm_restore != db:
        raise UpdateError(
            f"La restauration écrase la base '{db}' et perd les données saisies depuis la sauvegarde. "
            f"Relancez avec --restore-db --confirm-restore {db}."
        )
    ctx.log(f"Retour à {manifest['from_commit'][:10]} (version {manifest['from_version']}).")
    step_stop(ctx)
    git(ctx, "checkout", manifest["from_commit"])
    git(ctx, *SUBMODULE_UPDATE)
    for f in (backup / "config").glob("*"):
        shutil.copy2(f, ctx.root / "config" / f.name)
    if (backup / "environ").is_file():
        shutil.copy2(backup / "environ", ctx.root / "environ")
    if (backup / "config.json").is_file():
        shutil.copy2(
            backup / "config.json", ctx.root / "frontend" / "src" / "assets" / "config.json"
        )
    if (backup / "custom").is_dir():
        shutil.copytree(backup / "custom", ctx.root / "custom", dirs_exist_ok=True)
    if restore_db:
        ctx.log(f"Restauration de la base '{db}'…")
        ctx.runner.run(
            [
                "sudo",
                "-u",
                "postgres",
                "pg_restore",
                "--clean",
                "--if-exists",
                "--no-owner",
                "-d",
                db,
            ],
            stdin_path=backup / "database.dump",
        )
    steps.step_backend(ctx)
    step_frontend_deps(ctx)
    steps.step_systemd(ctx)
    ctx.geonature("update-configuration")
    step_start(ctx)
    pointer_file(ctx.root).unlink(missing_ok=True)
    write_manifest(backup, {**manifest, "status": "rolled_back", "db_restored": bool(restore_db)})
    if not restore_db:
        ctx.log(
            "Code restauré, base laissée telle quelle. Si l'ancienne version ne démarre pas à cause du schéma migré, "
            f"relancez avec --restore-db --confirm-restore {db}."
        )
