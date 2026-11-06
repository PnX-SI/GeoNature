import json
import shutil
import subprocess
import sys
from pathlib import Path
from types import SimpleNamespace

import pytest

sys.path.insert(0, str(Path(__file__).resolve().parents[1]))

from installer import steps, update
from installer.run import Runner
from installer.state import State


def sh(cwd, *cmd):
    subprocess.run(cmd, cwd=cwd, check=True, capture_output=True)


@pytest.fixture
def repo(tmp_path):
    """Vrai dépôt git avec un tag 2.15.0 puis 2.16.0, dans un dossier unique."""
    root = tmp_path / "gn"
    (root / "config").mkdir(parents=True)
    sh(root, "git", "init", "-q", "-b", "main")
    sh(root, "git", "config", "user.email", "t@t")
    sh(root, "git", "config", "user.name", "t")
    for version in ("2.15.0", "2.16.0"):
        (root / "VERSION").write_text(version + "\n")
        sh(root, "git", "add", "VERSION")
        sh(root, "git", "commit", "-q", "-m", version)
        sh(root, "git", "tag", version)
    sh(root, "git", "checkout", "-q", "2.15.0")
    (root / "config" / "geonature_config.toml").write_text("SECRET_KEY = 'short'\n")
    (root / "config" / "settings.ini").write_text("db_name=gn2\n")
    (root / "environ").write_text("X=1\n")
    (root / "custom").mkdir()
    (root / "custom" / "a.css").write_text("a{}")
    return root


class Rec(Runner):
    """Vrai Runner pour git, mais enregistre sans exécuter les commandes système."""

    def __init__(self, *a, **k):
        super().__init__(*a, **k)
        self.sys = []

    def run(self, cmd, **k):
        if cmd[0] in ("sudo", "bash"):
            self.sys.append(cmd)
            if k.get("stdout_path"):
                Path(k["stdout_path"]).write_bytes(b"DUMP")
            return SimpleNamespace(returncode=0)
        return super().run(cmd, **k)

    def capture(self, cmd, **k):
        if cmd[0] == "systemctl":
            return SimpleNamespace(
                returncode=0 if cmd[2].startswith("geonature") else 1, stdout="", stderr=""
            )
        return super().capture(cmd, **k)


@pytest.fixture
def ctx(repo, tmp_path):
    return steps.Context(
        root=repo,
        cfg={"db_name": "gn2"},
        runner=Rec(tmp_path / "u.log", cwd=repo),
        state=State(tmp_path / "st"),
        log=lambda m: None,
    )


def test_parse_version():
    assert update.parse_version("2.17.5\n") == (2, 17, 5)
    assert update.parse_version("2.18.0-rc1") == (2, 18, 0)
    assert update.parse_version("n/a") is None


def test_transition_rules():
    ok = update.check_transition((2, 15, 0), (2, 16, 0), False)
    assert ok.status == "OK"
    assert update.check_transition((2, 15, 0), (2, 15, 0), True).status == "FAIL"
    assert update.check_transition((2, 16, 0), (2, 15, 0), False).status == "FAIL"
    old = update.check_transition((2, 12, 0), (2, 16, 0), False)
    assert old.status == "FAIL" and "2.15.0" in old.detail
    assert update.check_transition(None, (2, 16, 0), False).status == "FAIL"


def test_dirty_tree_ignores_untracked_but_flags_tracked(ctx, repo):
    assert update.tracked_changes(ctx) == []  # config/, environ, custom/ non suivis
    (repo / "VERSION").write_text("2.15.0 modifié\n")
    assert update.tracked_changes(ctx)


def test_version_at(ctx):
    assert update.version_at(ctx, "2.16.0") == (2, 16, 0)
    assert update.version_at(ctx, "inexistant") is None


def test_backup_contents_and_manifest(ctx, repo, tmp_path):
    backup = update.make_backup(ctx, "2.16.0", tmp_path / "bk")
    assert (backup / "config" / "geonature_config.toml").exists()
    assert (backup / "environ").read_text() == "X=1\n"
    assert (backup / "custom" / "a.css").exists()
    assert (backup / "database.dump").read_bytes() == b"DUMP"
    assert oct(backup.stat().st_mode & 0o777) == "0o700"
    m = update.read_manifest(backup)
    assert m["from_version"] == "2.15.0" and m["to_ref"] == "2.16.0" and m["db_name"] == "gn2"
    assert len(m["from_commit"]) == 40
    pg_dump = [c for c in ctx.runner.sys if "pg_dump" in c][0]
    assert pg_dump[:4] == ["sudo", "-u", "postgres", "pg_dump"]


def test_resume_requires_same_target(ctx, repo, tmp_path):
    bk = tmp_path / "bk"
    backup, resumed = update.start_or_resume(ctx, "2.16.0", bk)
    assert resumed is False
    again, resumed = update.start_or_resume(ctx, "2.16.0", bk)
    assert resumed is True and again == backup
    with pytest.raises(update.UpdateError, match="en cours"):
        update.start_or_resume(ctx, "2.17.0", bk)


def test_secret_key_regenerated_only_if_short(tmp_path):
    f = tmp_path / "c.toml"
    f.write_text("SECRET_KEY = 'short'\nOTHER = 'x'\n[A]\nSECRET_KEY = 'keep'\n")
    assert update.ensure_secret_key(f) is True
    import tomllib

    data = tomllib.loads(f.read_text())
    assert (
        len(data["SECRET_KEY"]) == 64 and data["OTHER"] == "x" and data["A"]["SECRET_KEY"] == "keep"
    )
    assert update.ensure_secret_key(f) is False


def test_checkout_step_moves_this_single_directory(ctx, repo):
    ctx.extra["ref"] = "2.16.0"
    update.step_checkout(ctx)
    assert (repo / "VERSION").read_text().strip() == "2.16.0"
    assert (repo / "config" / "geonature_config.toml").exists()  # fichiers non versionnés conservés


def test_rollback_restores_commit_and_files_without_touching_db(ctx, repo, tmp_path, monkeypatch):
    backup = update.make_backup(ctx, "2.16.0", tmp_path / "bk")
    ctx.extra["ref"] = "2.16.0"
    update.step_checkout(ctx)
    (repo / "environ").write_text("X=changed\n")
    (repo / "config" / "geonature_config.toml").write_text("SECRET_KEY = 'new'\n")
    update.pointer_file(repo).parent.mkdir(parents=True, exist_ok=True)
    update.pointer_file(repo).write_text(str(backup))

    monkeypatch.setattr(steps.Context, "geonature", lambda self, *a, **k: None)
    monkeypatch.setattr(steps, "step_backend", lambda c: None)
    monkeypatch.setattr(steps, "step_systemd", lambda c: None)
    monkeypatch.setattr(update, "step_frontend_deps", lambda c: None)
    update.rollback(ctx, tmp_path / "bk")

    assert (repo / "VERSION").read_text().strip() == "2.15.0"
    assert (repo / "environ").read_text() == "X=1\n"
    assert "short" in (repo / "config" / "geonature_config.toml").read_text()
    assert not update.pointer_file(repo).exists()
    assert not any("pg_restore" in c for cmd in ctx.runner.sys for c in cmd)
    assert update.read_manifest(backup)["status"] == "rolled_back"


def test_restore_db_needs_exact_confirmation(ctx, repo, tmp_path):
    update.make_backup(ctx, "2.16.0", tmp_path / "bk")
    with pytest.raises(update.UpdateError, match="--confirm-restore gn2"):
        update.rollback(ctx, tmp_path / "bk", restore_db=True)
    with pytest.raises(update.UpdateError):
        update.rollback(ctx, tmp_path / "bk", restore_db=True, confirm_restore="autre")
    assert (repo / "VERSION").read_text().strip() == "2.15.0"  # rien n'a bougé


def test_dry_run_changes_nothing(ctx, repo, tmp_path):
    before = update.current_commit(ctx)
    assert update.run_update(ctx, "2.16.0", tmp_path / "bk", dry_run=True) == []
    assert update.current_commit(ctx) == before and not (tmp_path / "bk").exists()
    assert not update.pointer_file(repo).exists()


def test_update_step_order():
    names = [s.name for s in update.UPDATE_STEPS]
    assert names[0] == "stop" and names[1] == "checkout" and names[-1] == "start"
    assert names.index("backend") < names.index("database") < names.index("frontend")


def test_generated_lockfile_is_ignored_then_restored_before_checkout(ctx, repo):
    (repo / "uv.lock").write_text("v1\n")
    sh(repo, "git", "add", "uv.lock")
    sh(repo, "git", "commit", "-q", "-m", "lock")
    sh(repo, "git", "tag", "2.15.1")
    (repo / "uv.lock").write_text("réécrit par uv sync\n")
    assert update.tracked_changes(ctx) == []  # pas un blocage
    (repo / "VERSION").write_text("modifié à la main\n")
    changes = update.tracked_changes(ctx)  # mais un vrai changement en est un
    assert len(changes) == 1 and changes[0].endswith("VERSION")
    sh(repo, "git", "checkout", "--", "VERSION")
    ctx.extra["ref"] = "2.16.0"
    update.step_checkout(ctx)  # ne doit pas échouer à cause de uv.lock modifié
    assert (repo / "VERSION").read_text().strip() == "2.16.0"
