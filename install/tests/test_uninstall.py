import sys
from pathlib import Path
from types import SimpleNamespace

sys.path.insert(0, str(Path(__file__).resolve().parents[1]))

from installer import uninstall
from installer.state import State

ALL = set(uninstall.OWN_FILES + uninstall.SHARED_FILES + uninstall.APACHE_FILES) | {
    "/etc/apache2/sites-enabled/geonature.conf",
    "/etc/apache2/sites-enabled/geonature_maintenance.conf",
}


def cmds(plan):
    return [" ".join(cmd) for _, cmd, _ in plan]


def test_nothing_installed_gives_empty_plan():
    assert uninstall.build_plan(exists=lambda p: False) == []


def test_plan_never_touches_the_database_or_config():
    joined = " ".join(cmds(uninstall.build_plan(True, exists=lambda p: p in ALL)))
    for forbidden in ("psql", "dropdb", "DROP", "postgres", "settings.ini", "/config", "rm -rf"):
        assert forbidden not in joined


def test_shared_systemd_files_are_kept_unless_requested():
    without = " ".join(cmds(uninstall.build_plan(False, exists=lambda p: p in ALL)))
    with_shared = " ".join(cmds(uninstall.build_plan(True, exists=lambda p: p in ALL)))
    assert "geonature-generator" not in without and "geonature-reload@.path" not in without
    assert "geonature-generator" in with_shared and "geonature-reload@.path" in with_shared


def test_services_stopped_before_files_removed_and_apache_reloaded_last():
    steps = cmds(uninstall.build_plan(False, exists=lambda p: p in ALL))
    assert steps[0].endswith("disable --now geonature.service")
    first_rm = next(i for i, c in enumerate(steps) if " rm " in c)
    assert first_rm > 1
    assert steps.index("sudo systemctl daemon-reload") > first_rm
    assert steps[-2:] == ["sudo apachectl configtest", "sudo systemctl reload apache2"]


def test_only_existing_files_are_listed():
    only_service = {"/etc/systemd/system/geonature.service"}
    steps = cmds(uninstall.build_plan(False, exists=lambda p: p in only_service))
    assert "sudo rm -f /etc/systemd/system/geonature.service" in steps
    assert not any("apache" in c for c in steps)


def test_run_executes_plan_and_clears_state_markers(tmp_path):
    calls = []
    runner = SimpleNamespace(run=lambda cmd, check=True: calls.append((cmd, check)))
    state = State(tmp_path / ".state")
    state.mark_done("backend")
    ctx = SimpleNamespace(runner=runner, state=state, log=lambda m: None)
    plan = uninstall.build_plan(False, exists=lambda p: p in ALL)
    uninstall.run(ctx, plan)
    assert len(calls) == len(plan)
    assert not state.is_done("backend")
    assert all(check is False for cmd, check in calls if "disable" in cmd or "a2dissite" in cmd)
