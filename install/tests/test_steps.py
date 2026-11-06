import sys
from pathlib import Path
from types import SimpleNamespace

import pytest

sys.path.insert(0, str(Path(__file__).resolve().parents[1]))

from installer import pg, steps
from installer.state import State

BASE = {"srid_local": "2154", "taxref_region": "fr"}


def names(cmds):
    return [" ".join(c[:2]) + (" " + c[2] if c[0] == "db" and len(c) > 2 else "") for c in cmds]


def test_minimal_populate():
    cmds = steps.populate_commands(BASE, taxref_present=True, sensitivity_present=True)
    assert cmds[0] == ["db", "upgrade", "geonature@head", "-x", "local-srid=2154"]
    assert cmds[-1] == ["db", "autoupgrade", "-x", "local-srid=2154"]
    assert not any(c[0] == "taxref" for c in cmds)


def test_taxref_import_variants():
    with_statuts = steps.populate_commands({**BASE, "install_bdc_statuts": "true"}, False, True)
    assert ["taxref", "import-v18", "--taxref-region=fr"] in with_statuts
    assert ["db", "upgrade", "ref_geo_fr_departments@head"] in with_statuts
    without = steps.populate_commands({**BASE, "install_bdc_statuts": "false"}, False, True)
    assert ["taxref", "import-v18", "--skip-bdc-statuts"] in without


def test_grids_all_or_individual():
    allg = steps.populate_commands({**BASE, "install_grid_layer": "true"}, True, True)
    assert sum("ref_geo_inpn_grids" in c[2] for c in allg if c[:2] == ["db", "upgrade"]) == 6
    one = steps.populate_commands({**BASE, "install_grid_layer_10": "true"}, True, True)
    assert ["db", "upgrade", "ref_geo_inpn_grids_10@head"] in one
    assert not any("grids_5@" in " ".join(c) for c in one)


def test_sensitivity_skipped_when_present():
    cfg = {**BASE, "install_ref_sensitivity": "true"}
    assert any(c[0] == "sensitivity" for c in steps.populate_commands(cfg, True, False))
    assert not any(c[0] == "sensitivity" for c in steps.populate_commands(cfg, True, True))


def test_dedupe_keeps_autoupgrade_but_drops_repeated_upgrades():
    cfg = {
        **BASE,
        "install_bdc_statuts": "true",
        "install_sig_layers": "true",
        "install_ref_sensitivity": "true",
    }
    out = steps.dedupe(steps.populate_commands(cfg, False, False))
    deps = [c for c in out if c == ["db", "upgrade", "ref_geo_fr_departments@head"]]
    assert len(deps) == 1
    assert sum(c[:2] == ["db", "autoupgrade"] for c in out) == 2


def test_dem_vector_only_if_requested():
    cfg = {**BASE, "install_default_dem": "true"}
    assert [
        "db",
        "upgrade",
        "ign_bd_alti@head",
        "-x",
        "local-srid=2154",
    ] in steps.populate_commands(cfg, True, True)
    assert not any("vector" in " ".join(c) for c in steps.populate_commands(cfg, True, True))


def test_patch_activate_once(tmp_path):
    f = tmp_path / "activate"
    f.write_text("# activate\n")
    assert steps.patch_activate(f) is True
    assert steps.patch_activate(f) is False
    assert f.read_text().count("GeoNature command completion") == 1


def make_ctx(tmp_path, **cfg):
    full = {
        "db_name": "gn",
        "user_pg": "u",
        "user_pg_pass": "p",
        "my_local": "fr_FR.UTF-8",
        **BASE,
        **cfg,
    }
    return steps.Context(
        root=tmp_path,
        cfg=full,
        runner=SimpleNamespace(env=None),
        state=State(tmp_path / "st"),
        log=lambda m: None,
    )


def test_run_steps_skips_done_and_resumes(tmp_path):
    ctx = make_ctx(tmp_path)
    calls = []
    plan = [steps.Step(n, n, lambda c, n=n: calls.append(n)) for n in ("a", "b", "c")]
    assert steps.run_steps(ctx, plan) == ["a", "b", "c"]
    assert steps.run_steps(ctx, plan) == []
    ctx.state.reset("b")
    assert steps.run_steps(ctx, plan) == ["b"]
    assert steps.run_steps(ctx, plan, from_step="c", only=None) == []
    with pytest.raises(ValueError):
        steps.run_steps(ctx, plan, only="zzz")


def test_failed_step_is_not_marked_done(tmp_path):
    ctx = make_ctx(tmp_path)

    def boom(c):
        raise RuntimeError("x")

    with pytest.raises(RuntimeError):
        steps.run_steps(ctx, [steps.Step("a", "a", boom)])
    assert not ctx.state.is_done("a")


class FakePg:
    def __init__(self):
        self.log, self.exists = [], False


@pytest.fixture
def fake_pg(monkeypatch):
    fake = FakePg()
    monkeypatch.setattr(pg, "database_exists", lambda r, n: fake.exists)
    for fn in (
        "create_role",
        "create_database",
        "add_extensions",
        "grant_reference_tables",
        "drop_database",
    ):
        monkeypatch.setattr(pg, fn, lambda *a, _f=fn, **k: fake.log.append(_f))
    monkeypatch.setattr(steps, "probe_table", lambda geonature, table: True)
    monkeypatch.setattr(
        steps.Context, "geonature", lambda self, *a, check=True: fake.log.append("gn " + a[0])
    )
    return fake


def test_existing_db_without_drop_is_left_alone(tmp_path, fake_pg):
    fake_pg.exists = True
    steps.step_database(make_ctx(tmp_path, drop_apps_db="false"))
    assert fake_pg.log == []


def test_interrupted_population_resumes_without_recreating(tmp_path, fake_pg):
    ctx = make_ctx(tmp_path)
    steps.step_database(ctx)  # première exécution : crée la base
    assert "create_database" in fake_pg.log and ctx.state.is_done("database_created")
    fake_pg.log.clear()
    fake_pg.exists = True  # relance après un échec de peuplement
    steps.step_database(ctx)
    assert "create_database" not in fake_pg.log and "drop_database" not in fake_pg.log
    assert "gn db" in fake_pg.log


def test_drop_needs_confirmation(tmp_path, monkeypatch):
    ctx = make_ctx(tmp_path, drop_apps_db="true")
    monkeypatch.setattr(pg, "database_exists", lambda r, n: True)
    with pytest.raises(pg.DatabaseExistsError):
        steps.step_database(ctx)


# --- gabarits, systemd, modules, frontend, apache -------------------------------------------

REPO = Path(__file__).resolve().parents[2]


def test_envsubst_replaces_only_listed_names():
    text = "u=${USER} d=${BASE_DIR} keep=${GUNICORN_PROC_NAME} pid=$MAINPID"
    out = steps.envsubst(text, {"USER": "bob", "BASE_DIR": "/x"}, {"USER"})
    assert out == "u=bob d=${BASE_DIR} keep=${GUNICORN_PROC_NAME} pid=$MAINPID"


def test_real_service_template_keeps_runtime_variables():
    text = (REPO / "install/assets/geonature.service").read_text()
    out = steps.envsubst(
        text,
        {"USER": "bob", "BASE_DIR": "/srv/gn", "VENV_PATH": "backend/venv"},
        {"USER", "BASE_DIR", "VENV_PATH"},
    )
    assert "User=bob" in out and "/srv/gn/backend/venv/bin/gunicorn" in out
    assert "${GUNICORN_NUM_WORKERS}" in out and "${USER}" not in out and "${BASE_DIR}" not in out


def test_real_apache_template_fully_resolved():
    text = (REPO / "install/assets/geonature_apache.conf").read_text()
    values = {k: f"/{k.lower()}" for k in steps.APACHE_VARS}
    out = steps.envsubst(text, values, steps.APACHE_VARS)
    assert "${" not in out


@pytest.mark.parametrize(
    "url,expected",
    [
        ("http://mon.domaine.com/", "mon.domaine.com"),
        ("https://a.b", "a.b"),
        ("http://1.2.3.4:8080/", "1.2.3.4:8080"),
    ],
)
def test_domain_name(url, expected):
    assert steps.domain_name(url) == expected


def test_frontend_config_json_strips_http_scheme_and_is_valid_json():
    import json

    out = steps.frontend_config_json("http://x.org/geonature/api")
    assert json.loads(out) == {"API_ENDPOINT": "//x.org/geonature/api"}
    assert json.loads(steps.frontend_config_json('https://x.org/a"b'))["API_ENDPOINT"].endswith(
        'a"b'
    )


def test_frontend_prefix():
    assert steps.frontend_prefix("http://x.org/geonature") == "/geonature"
    assert steps.frontend_prefix("http://x.org") == ""


def test_modules_commands_follow_flags():
    cmds = steps.modules_commands(
        {
            "add_sample_data": "true",
            "install_module_occhab": "true",
            "install_module_validation": "false",
        },
        Path("/gn"),
    )
    flat = [" ".join(c[:3]) for c in cmds]
    assert flat[0].startswith("install-gn-module /gn/contrib/occtax OCCTAX")
    assert "db upgrade occtax-samples@head" in flat and "db upgrade occhab-samples@head" in flat
    assert not any("VALIDATION" in " ".join(c) for c in cmds)
    assert cmds[-1][0] == "permissions"
    only = steps.modules_commands({}, Path("/gn"))
    assert [c[0] for c in only] == ["install-gn-module", "permissions"]


class SudoRunner:
    def __init__(self):
        self.calls = []

    def run(self, cmd, input=None, **k):
        self.calls.append((cmd, input))


def test_sudo_write_skips_identical_content(tmp_path):
    ctx = make_ctx(tmp_path)
    ctx.runner = SudoRunner()
    target = tmp_path / "f.conf"
    assert steps.sudo_write(ctx, target, "abc") is True
    assert ["sudo", "tee", str(target)] in [c for c, _ in ctx.runner.calls]
    target.write_text("abc")
    ctx.runner.calls.clear()
    assert steps.sudo_write(ctx, target, "abc") is False and ctx.runner.calls == []


def test_systemd_skipped_in_dev(tmp_path):
    ctx = make_ctx(tmp_path, MODE="dev")
    ctx.runner = SudoRunner()
    steps.step_systemd(ctx)
    assert ctx.runner.calls == []


def test_step_order_matches_legacy_scripts():
    order = [s.name for s in steps.STEPS]
    assert (
        order.index("systemd")
        < order.index("database")
        < order.index("modules")
        < order.index("frontend")
        < order.index("apache")
        < order.index("services")
    )


def test_ensure_uv_finds_user_local_install_without_reinstalling(tmp_path, monkeypatch):
    home = tmp_path / "home"
    (home / ".local" / "bin").mkdir(parents=True)
    uv = home / ".local" / "bin" / "uv"
    uv.write_text("#!/bin/sh\n")
    uv.chmod(0o755)
    monkeypatch.setattr(steps.Path, "home", lambda: home)
    monkeypatch.setenv("PATH", "/usr/bin:/bin")
    ctx = make_ctx(tmp_path)
    ctx.runner = SudoRunner()
    ctx.runner.env = None
    steps.ensure_uv(ctx)
    assert ctx.runner.calls == []  # déjà installé : pas de pip
    assert ctx.runner.env["PATH"].startswith(str(home / ".local" / "bin"))


def test_geonature_runs_with_an_activated_venv_environment(tmp_path):
    # install-gn-module appelle `uv pip install` : sans VIRTUAL_ENV il échoue ("No virtual environment found")
    seen = []
    ctx = make_ctx(tmp_path)
    ctx.runner = SimpleNamespace(
        env={"PATH": "/home/u/.local/bin:/usr/bin"},
        run=lambda cmd, **kw: seen.append((cmd, kw)),
    )
    ctx.geonature("install-gn-module", "x")
    cmd, kw = seen[0]
    assert cmd[0] == str(ctx.venv / "bin" / "geonature")
    assert kw["env"]["VIRTUAL_ENV"] == str(ctx.venv)
    # ~/.local/bin (uv) est présent même si le PATH du runner n'a pas été complété (étape backend déjà faite)
    local_bin = Path.home() / ".local" / "bin"
    assert kw["env"]["PATH"] == f"{ctx.venv / 'bin'}:{local_bin}:/home/u/.local/bin:/usr/bin"


def test_npm_commands_get_generous_retries():
    # un réseau instable ne doit pas faire échouer `npm ci` après 2 essais
    assert "npm_config_fetch_retries=8" in steps.NVM_SHELL
    assert steps.NVM_SHELL.rstrip().endswith('. "$NVM_DIR/nvm.sh";')


def test_ci_and_dev_backend_sync_keeps_installed_modules(tmp_path, monkeypatch):
    # `uv sync` exact désinstallait occtax/occhab/validation (ajoutés par install-gn-module) à chaque mise à jour
    calls = []
    runner = SimpleNamespace(
        env=None,
        run=lambda cmd, **kw: calls.append(cmd) or SimpleNamespace(returncode=0),
        capture=lambda cmd, **kw: SimpleNamespace(stdout=""),
    )
    monkeypatch.setattr(steps, "ensure_uv", lambda ctx: None)
    monkeypatch.setattr(steps, "patch_activate", lambda f: False)
    for mode in ("ci", "dev"):
        calls.clear()
        ctx = make_ctx(tmp_path, MODE=mode)
        ctx.runner = runner
        ctx.venv.mkdir(parents=True, exist_ok=True)
        steps.step_backend(ctx)
        sync = next(c for c in calls if c[:2] == ["uv", "sync"])
        assert "--inexact" in sync
