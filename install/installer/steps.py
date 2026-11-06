"""Étapes de l'installation, dans l'ordre. Portage de install/00..03b_*.sh.

Chaque étape reçoit un `Context` ; `run_steps` saute celles déjà marquées terminées.
"""

import getpass
import json
import os
import re
import shutil
from dataclasses import dataclass, field
from pathlib import Path

from . import net, pg
from .state import State

APT_PACKAGES = (
    "unzip git postgresql-postgis postgis python3-pip python3-venv python3-dev libpq-dev "
    "libgdal-dev libffi-dev libpangocairo-1.0-0 apache2 redis gettext-base"
).split()
NVM_VERSION = "v0.39.1"
NVM_INSTALL_URL = f"https://raw.githubusercontent.com/nvm-sh/nvm/{NVM_VERSION}/install.sh"
PYTHON_VERSION = "3.13"
GRID_SIZES = (1, 5, 10, 2, 20, 50)
SENSITIVITY_URL = "https://geonature.fr/data/inpn/sensitivity/RefSensibiliteV18_20250904.zip"

# Charge nvm puis exécute "$@" : les chemins sont passés en arguments, jamais interpolés.
# npm réessaie 2 fois par défaut : trop peu sur un réseau instable ou derrière un proxy (ECONNRESET, EIDLETIMEOUT)
NPM_RETRY_ENV = (
    "export npm_config_fetch_retries=8 npm_config_fetch_retry_mintimeout=5000 "
    "npm_config_fetch_retry_maxtimeout=120000 npm_config_fetch_timeout=300000; "
)
NVM_SHELL = (
    'export NVM_DIR="${XDG_CONFIG_HOME:+$XDG_CONFIG_HOME/nvm}"; NVM_DIR="${NVM_DIR:-$HOME/.nvm}"; '
    + NPM_RETRY_ENV
    + '. "$NVM_DIR/nvm.sh"; '
)


@dataclass
class Context:
    root: Path
    cfg: dict
    runner: object
    state: State
    confirm_drop: str = None
    log: callable = print
    extra: dict = field(default_factory=dict)

    @property
    def install_dir(self):
        return self.root / "install"

    @property
    def venv(self):
        return self.root / self.cfg.get("venv_path", "backend/venv")

    @property
    def is_dev(self):
        return self.cfg.get("MODE") == "dev"

    def venv_env(self):
        """Environnement d'un venv activé : certaines commandes (install-gn-module) appellent `uv pip`."""
        path = (self.runner.env or {}).get("PATH") or os.environ.get("PATH", "")
        # uv est installé par `pip --user` : ~/.local/bin, même si l'étape backend est déjà faite (reprise)
        local_bin = Path.home() / ".local" / "bin"
        return {"VIRTUAL_ENV": str(self.venv), "PATH": f"{self.venv / 'bin'}:{local_bin}:{path}"}

    def geonature(self, *args, check=True):
        return self.runner.run(
            [str(self.venv / "bin" / "geonature"), *args],
            env=self.venv_env(),
            cwd=self.root,
            check=check,
        )


def geonature_output(ctx, *args):
    return ctx.runner.capture(
        [str(ctx.venv / "bin" / "geonature"), *args], env=ctx.venv_env(), cwd=ctx.root
    ).stdout.strip()


def flag(cfg, key):
    return str(cfg.get(key, "")).lower() == "true"


# --- apt -------------------------------------------------------------------------------------


def step_apt(ctx):
    packages = APT_PACKAGES + (["xvfb"] if ctx.is_dev else [])
    ctx.runner.run(["sudo", "apt-get", "install", "-y", *packages])
    for mod in ("rewrite", "proxy", "proxy_http"):
        ctx.runner.run(["sudo", "a2enmod", mod])
    ctx.runner.run(["sudo", "systemctl", "restart", "apache2"])


# --- nvm / node ------------------------------------------------------------------------------


def step_nvm(ctx):
    script = net.download(NVM_INSTALL_URL, ctx.root / "tmp" / "nvm-install.sh")
    ctx.runner.run(["bash", str(script)])
    nvmrc = (ctx.root / "frontend" / ".nvmrc").read_text().strip()
    ctx.runner.run(["bash", "-c", NVM_SHELL + 'nvm install "$1"', "_", nvmrc])


# --- backend ---------------------------------------------------------------------------------


def ensure_uv(ctx):
    local_bin = str(Path.home() / ".local" / "bin")
    search_path = f"{local_bin}:{os.environ['PATH']}"
    if not shutil.which("uv", path=search_path):
        ctx.log("Installation de uv…")
        # PEP 668 (Debian 12+) : --user cantonne l'installation à ~/.local ; le repli n'est utilisé qu'en cas d'échec.
        if (
            ctx.runner.run(
                ["python3", "-m", "pip", "install", "--user", "uv"], check=False
            ).returncode
            != 0
        ):
            ctx.runner.run(
                ["python3", "-m", "pip", "install", "--user", "--break-system-packages", "uv"]
            )
    ctx.runner.env = {**(ctx.runner.env or {}), "PATH": search_path}


COMPLETION_NAME = "geonature_completion"
COMPLETION_SNIPPET = f"""
# GeoNature command completion
if [[ -f "${{VIRTUAL_ENV}}/bin/{COMPLETION_NAME}" ]]; then
  source "${{VIRTUAL_ENV}}/bin/{COMPLETION_NAME}"
fi
"""


def patch_activate(activate_file):
    """Ajoute le chargement de l'autocomplétion au script activate (une seule fois). Retourne True si modifié."""
    activate_file = Path(activate_file)
    text = activate_file.read_text()
    if COMPLETION_NAME in text:
        return False
    activate_file.write_text(text + COMPLETION_SNIPPET)
    return True


def step_backend(ctx):
    ensure_uv(ctx)
    env = {"UV_PROJECT_ENVIRONMENT": str(ctx.venv), "VIRTUAL_ENV": str(ctx.venv)}
    if not ctx.venv.is_dir():
        ctx.runner.run(["uv", "venv", "--seed", "--python", PYTHON_VERSION, str(ctx.venv)], env=env)
    if ctx.cfg.get("MODE") in ("dev", "ci"):
        status = ctx.runner.capture(["git", "submodule", "status"], cwd=ctx.root).stdout
        if any(line.startswith("-") for line in status.splitlines()):
            raise RuntimeError(
                "Sous-modules non initialisés : lancez 'git submodule init && git submodule update'."
            )
        ctx.runner.run(
            [
                "uv",
                "sync",
                # sans --inexact, uv désinstalle les modules ajoutés par `install-gn-module` (occtax, occhab…)
                "--inexact",
                "--project",
                str(ctx.root),
                "--active",
                "--extra",
                "tests",
                "--extra",
                "lint",
            ],
            env=env,
            cwd=ctx.root,
        )
    else:
        # --no-sources : requirements.txt est compilé sans le workspace uv, sinon `usershub` (URL git)
        # entre en conflit avec [tool.uv.sources] de pyproject.toml
        ctx.runner.run(
            ["uv", "pip", "install", "--no-sources", "-e", str(ctx.root), "-r", "requirements.txt"],
            env=env,
            cwd=ctx.root / "backend",
        )
    patch_activate(ctx.venv / "bin" / "activate")
    ctx.runner.run(
        [
            "bash",
            "-c",
            NVM_SHELL + 'cd "$1" && nvm use && cd "$2" && npm ci',
            "_",
            str(ctx.root / "frontend"),
            str(ctx.root / "backend" / "static"),
        ]
    )


# --- base de données -------------------------------------------------------------------------


def populate_commands(cfg, taxref_present, sensitivity_present):
    """Commandes `geonature` pour peupler la base (ancien 03b_populate_db.sh), sous forme de listes."""
    srid = ["-x", f"local-srid={cfg['srid_local']}"]
    cmds = [["db", "upgrade", "geonature@head", *srid], ["db", "autoupgrade", *srid]]

    if not taxref_present:
        if flag(cfg, "install_bdc_statuts"):
            cmds += [
                ["db", "upgrade", "ref_geo_fr_departments@head"],
                ["taxref", "import-v18", f"--taxref-region={cfg.get('taxref_region') or 'fr'}"],
            ]
        else:
            cmds.append(["taxref", "import-v18", "--skip-bdc-statuts"])
    cmds.append(["db", "upgrade", "nomenclatures_taxonomie_data@head"])

    if flag(cfg, "add_sample_data"):
        cmds.append(["db", "upgrade", "geonature-samples@head"])
    if flag(cfg, "install_sig_layers"):
        cmds += [
            ["db", "upgrade", f"ref_geo_fr_{n}@head"]
            for n in ("departments", "municipalities", "regions")
        ]
    for size in GRID_SIZES:
        if flag(cfg, "install_grid_layer") or flag(cfg, f"install_grid_layer_{size}"):
            cmds.append(["db", "upgrade", f"ref_geo_inpn_grids_{size}@head"])

    if not sensitivity_present and flag(cfg, "install_ref_sensitivity"):
        cmds += [
            ["db", "upgrade", "ref_geo_fr_departments@head"],
            [
                "sensitivity",
                "add-referential",
                "--source-name",
                "Référentiel sensibilité TAXREF v18 20250904",
                "--url",
                SENSITIVITY_URL,
                "--zipfile",
                "RefSensibiliteV18_20250904.zip",
                "--csvfile",
                "RefSensibilite_18.csv",
                "--encoding=utf-8",
            ],
            ["sensitivity", "refresh-rules-cache"],
        ]
    if flag(cfg, "install_default_dem"):
        cmds.append(["db", "upgrade", "ign_bd_alti@head", *srid])
        if flag(cfg, "vectorise_dem"):
            cmds.append(["db", "upgrade", "ign_bd_alti_vector@head"])
    cmds.append(["db", "autoupgrade", *srid])
    return cmds


def dedupe(cmds):
    """Retire les `db upgrade` répétés à l'identique (ex. ref_geo_fr_departments demandé deux fois)."""
    seen, out = set(), []
    for c in cmds:
        if c[:2] == ["db", "upgrade"]:
            if tuple(c) in seen:
                continue
            seen.add(tuple(c))
        out.append(c)
    return out


def probe_table(geonature, table):
    sql = f"DO 'BEGIN ASSERT EXISTS (SELECT 1 FROM {table}); END'"
    return geonature("db", "exec", sql, check=False).returncode == 0


def populate_database(geonature, cfg, log=print):
    """Migrations et données de référence (TAXREF, sensibilité, grilles…), sans rejouer ce qui est déjà en base.

    `geonature(*args, check=True)` lance la commande ; partagé par l'installation et l'image Docker.
    """
    taxref = probe_table(geonature, "taxonomie.taxref")
    sensitivity = probe_table(geonature, "gn_sensitivity.t_sensitivity_rules")
    for cmd in dedupe(populate_commands(cfg, taxref, sensitivity)):
        log("geonature " + " ".join(cmd[:3]))
        geonature(*cmd)


def step_database(ctx):
    cfg = ctx.cfg
    runner, name = ctx.runner, cfg["db_name"]
    (ctx.root / "tmp").mkdir(exist_ok=True)
    (ctx.root / "var" / "log").mkdir(parents=True, exist_ok=True)

    resuming = ctx.state.is_done("database_created")
    if pg.database_exists(runner, name) and not resuming:
        if not flag(cfg, "drop_apps_db"):
            ctx.log(f"La base '{name}' existe déjà et drop_apps_db=false : création ignorée.")
            return
        pg.drop_database(runner, name, confirm_drop=ctx.confirm_drop)

    if resuming:
        ctx.log(f"Reprise du peuplement de la base '{name}' (créée par une exécution précédente).")
    else:
        if pg.create_role(runner, cfg["user_pg"], cfg["user_pg_pass"]):
            ctx.log(f"Rôle '{cfg['user_pg']}' créé.")
        pg.create_database(runner, name, cfg["user_pg"], cfg["my_local"])
        pg.add_extensions(runner, name, ctx.install_dir)
        pg.grant_reference_tables(runner, name, cfg["user_pg"])
        ctx.state.mark_done("database_created")

    if ctx.is_dev:
        (ctx.root / "cache").mkdir(exist_ok=True)
        ctx.runner.env = {**(ctx.runner.env or {}), "DATA_DIRECTORY": str(ctx.root / "cache")}

    populate_database(ctx.geonature, cfg, ctx.log)
    ctx.geonature("permissions", "supergrant", "--group", "--nom", "Grp_admin", "--yes")


# --- gabarits et fichiers système ------------------------------------------------------------


def envsubst(text, values, names):
    """Comme `envsubst '${A} ${B}'` : seules les variables de `names` sont remplacées, le reste est intact."""

    def repl(m):
        return str(values[m.group(1)]) if m.group(1) in names else m.group(0)

    return re.sub(r"\$\{([A-Za-z_][A-Za-z0-9_]*)\}", repl, text)


def domain_name(my_url):
    """http://mon.domaine.com/ -> mon.domaine.com (même calcul que l'ancien install_all.sh)."""
    return re.sub(r"^.*//", "", my_url).rstrip("/")


def sudo_write(ctx, path, content, executable=False):
    """Écrit un fichier système via sudo, sauf s'il a déjà exactement ce contenu. Retourne True si écrit."""
    try:
        if Path(path).read_text() == content:
            return False
    except OSError:
        pass
    ctx.runner.run(["sudo", "mkdir", "-p", str(Path(path).parent)])
    ctx.runner.run(["sudo", "tee", str(path)], input=content)
    if executable:
        ctx.runner.run(["sudo", "chmod", "+x", str(path)])
    return True


def asset(ctx, name):
    return (ctx.install_dir / "assets" / name).read_text()


# --- systemd (prod) --------------------------------------------------------------------------


def step_systemd(ctx):
    if ctx.is_dev:
        ctx.log("Mode dev : configuration systemd ignorée.")
        return
    user, base = getpass.getuser(), str(ctx.root)
    venv_path = ctx.cfg.get("venv_path", "backend/venv")

    def render(name, names):
        return envsubst(
            asset(ctx, name), {"USER": user, "BASE_DIR": base, "VENV_PATH": venv_path}, names
        )

    sudo_write(ctx, "/etc/tmpfiles.d/geonature.conf", render("tmpfiles-geonature.conf", {"USER"}))
    ctx.runner.run(["sudo", "systemd-tmpfiles", "--create", "/etc/tmpfiles.d/geonature.conf"])

    units = {
        "geonature.service": render("geonature.service", {"USER", "BASE_DIR", "VENV_PATH"}),
        "geonature-worker.service": render(
            "geonature-worker.service", {"USER", "BASE_DIR", "VENV_PATH"}
        ),
        "geonature-reload.service": asset(ctx, "geonature-reload.service"),
        "geonature-reload@.path": render("geonature-reload@.path", {"BASE_DIR"}),
    }
    for name, content in units.items():
        sudo_write(ctx, f"/etc/systemd/system/{name}", content)
    sudo_write(
        ctx,
        "/etc/systemd/system-generators/geonature-generator",
        render("geonature-generator", {"BASE_DIR"}),
        executable=True,
    )
    ctx.runner.run(["sudo", "systemctl", "daemon-reload"])
    sudo_write(ctx, "/etc/logrotate.d/geonature", render("log_rotate", {"USER"}))
    ctx.runner.run(["sudo", "systemctl", "enable", "geonature.service", "geonature-worker.service"])


# --- modules GeoNature -----------------------------------------------------------------------


def modules_commands(cfg, root):
    """Commandes `geonature` d'installation des modules livrés avec GeoNature (portage de 04)."""
    sample = flag(cfg, "add_sample_data")
    cmds = [["install-gn-module", str(root / "contrib" / "occtax"), "OCCTAX", "--build", "false"]]
    if sample:
        cmds.append(["db", "upgrade", "occtax-samples@head"])
    if flag(cfg, "install_module_occhab"):
        cmds.append(
            [
                "install-gn-module",
                str(root / "contrib" / "gn_module_occhab"),
                "OCCHAB",
                "--build",
                "false",
            ]
        )
        if sample:
            cmds.append(["db", "upgrade", "occhab-samples@head"])
    if flag(cfg, "install_module_validation"):
        cmds.append(
            [
                "install-gn-module",
                str(root / "contrib" / "gn_module_validation"),
                "VALIDATION",
                "--build",
                "false",
            ]
        )
    cmds.append(["permissions", "supergrant", "--group", "--nom", "Grp_admin", "--yes"])
    return cmds


def step_modules(ctx):
    for cmd in modules_commands(ctx.cfg, ctx.root):
        ctx.log("geonature " + " ".join(cmd[:2]))
        ctx.geonature(*cmd)
    ctx.geonature("generate-completion", "--output", str(ctx.venv / "bin" / COMPLETION_NAME))


# --- frontend --------------------------------------------------------------------------------


def frontend_config_json(api_endpoint):
    """Contenu de frontend/src/assets/config.json (schéma retiré, comme `${api_end_point/'http:'/''}`)."""
    return json.dumps({"API_ENDPOINT": api_endpoint.replace("http:", "", 1)}) + "\n"


def step_frontend(ctx):
    frontend = ctx.root / "frontend"
    config = frontend / "src" / "assets" / "config.json"
    config.write_text(frontend_config_json(geonature_output(ctx, "get-config", "API_ENDPOINT")))
    dev = ctx.is_dev  # en dev, `ng serve` remplace le build ; les devDependencies sont nécessaires
    script = (
        NVM_SHELL
        + 'cd "$1" && nvm use && '
        + ("npm ci" if dev else "npm ci --omit=dev && npm run build")
    )
    ctx.runner.run(["bash", "-c", script, "_", str(frontend)])


# --- Apache ----------------------------------------------------------------------------------


APACHE_VARS = {
    "BACKEND_PREFIX",
    "MEDIA_FOLDER",
    "MEDIA_URL",
    "STATIC_FOLDER",
    "CUSTOM_STATIC_FOLDER",
    "STATIC_URL",
    "FRONTEND_FOLDER",
    "FRONTEND_PREFIX",
    "GUNICORN_URL",
}


def frontend_prefix(url_application):
    from urllib.parse import urlsplit

    return urlsplit(url_application).path


def untraversable_dirs(path):
    """Dossiers parents de `path` sans droit de traversée (o+x) pour `www-data` (ex. /home/x en 0700)."""
    out = []
    for parent in reversed(Path(path).resolve().parents):
        if str(parent) != "/" and not parent.stat().st_mode & 0o001:
            out.append(parent)
    return out


def step_apache(ctx):
    get = lambda key: geonature_output(ctx, "get-config", key)
    values = {
        "BACKEND_PREFIX": get("APPLICATION_ROOT"),
        "MEDIA_FOLDER": get("MEDIA_FOLDER"),
        "MEDIA_URL": get("MEDIA_URL"),
        "STATIC_FOLDER": get("STATIC_FOLDER"),
        "CUSTOM_STATIC_FOLDER": get("CUSTOM_STATIC_FOLDER"),
        "STATIC_URL": get("STATIC_URL"),
        "FRONTEND_FOLDER": str(ctx.root / "frontend" / "dist"),
        "FRONTEND_PREFIX": frontend_prefix(get("URL_APPLICATION")),
        "GUNICORN_URL": "http://127.0.0.1:8000",
    }
    # Apache sert le frontend et les médias depuis le dossier de l'utilisateur : sans droit de
    # traversée sur ses parents (Debian crée /home/<user> en 0700), toutes les pages sont en 403.
    for folder in (values["FRONTEND_FOLDER"], values["MEDIA_FOLDER"], values["STATIC_FOLDER"]):
        for parent in untraversable_dirs(folder):
            ctx.log(
                f"Droit de traversée pour Apache sur {parent} (chmod o+x, sans droit de lecture)."
            )
            ctx.runner.run(["sudo", "chmod", "o+x", str(parent)])
    sudo_write(
        ctx,
        "/etc/apache2/conf-available/geonature.conf",
        envsubst(asset(ctx, "geonature_apache.conf"), values, APACHE_VARS),
    )
    for mod in ("rewrite", "proxy", "proxy_http", "deflate"):
        ctx.runner.run(["sudo", "a2enmod", mod])

    domain = {"DOMAIN_NAME": domain_name(ctx.cfg["my_url"])}
    sudo_write(
        ctx,
        "/etc/apache2/sites-available/geonature.conf",
        envsubst(asset(ctx, "vhost_apache.conf"), domain, {"DOMAIN_NAME"}),
    )
    sudo_write(
        ctx,
        "/etc/apache2/sites-available/geonature_maintenance.conf",
        envsubst(asset(ctx, "vhost_apache_maintenance.conf"), domain, {"DOMAIN_NAME"}),
    )
    sudo_write(ctx, "/var/www/geonature_maintenance/index.html", asset(ctx, "maintenance.html"))
    ctx.runner.run(["sudo", "a2ensite", "geonature"])
    # La configuration est validée avant le rechargement : une erreur n'interrompt pas Apache.
    ctx.runner.run(["sudo", "apachectl", "configtest"])
    ctx.runner.run(["sudo", "systemctl", "reload", "apache2"])


# --- démarrage des services (prod) -----------------------------------------------------------


def step_services(ctx):
    if ctx.is_dev:
        return
    for service in ("geonature", "geonature-worker"):
        ctx.runner.run(["sudo", "systemctl", "start", service])
        ctx.runner.run(["sudo", "systemctl", "enable", service])


@dataclass
class Step:
    name: str
    title: str
    run: callable


STEPS = [
    Step("apt", "Paquets système", step_apt),
    Step("nvm", "Node (nvm)", step_nvm),
    Step("backend", "Backend Python (uv) et paquets npm", step_backend),
    Step("systemd", "Services systemd", step_systemd),
    Step("database", "Base de données", step_database),
    Step("modules", "Modules GeoNature", step_modules),
    Step("frontend", "Frontend", step_frontend),
    Step("apache", "Apache", step_apache),
    Step("services", "Démarrage des services", step_services),
]


def run_steps(ctx, steps=STEPS, from_step=None, only=None):
    """Exécute les étapes non terminées. Retourne la liste des noms exécutés."""
    names = [s.name for s in steps]
    for wanted in (from_step, only):
        if wanted and wanted not in names:
            raise ValueError(f"Étape inconnue '{wanted}'. Étapes : {', '.join(names)}")
    started = from_step is None
    executed = []
    for step in steps:
        started = started or step.name == from_step
        if not started or (only and step.name != only):
            continue
        if ctx.state.is_done(step.name):
            ctx.log(f"✔ {step.title} (déjà fait)")
            continue
        ctx.log(f"▶ {step.title}…")
        step.run(ctx)
        ctx.state.mark_done(step.name)
        executed.append(step.name)
    return executed
