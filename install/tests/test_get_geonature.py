import os
import subprocess
import sys
from pathlib import Path

import pytest

SCRIPT = Path(__file__).resolve().parents[1] / "get-geonature.sh"

pytestmark = pytest.mark.skipif(sys.version_info < (3, 11), reason="le script exige Python >= 3.11")


def sh(cwd, *cmd):
    subprocess.run(cmd, cwd=cwd, check=True, capture_output=True)


@pytest.fixture
def origin(tmp_path):
    """Faux dépôt GeoNature avec un install.py factice et plusieurs tags."""
    repo = tmp_path / "origin"
    (repo / "install").mkdir(parents=True)
    sh(repo, "git", "init", "-q", "-b", "main")
    sh(repo, "git", "config", "user.email", "t@t")
    sh(repo, "git", "config", "user.name", "t")
    (repo / "install" / "install.sample.toml").write_text('my_url = "http://x/"\n')
    for tag in ("2.9.0", "2.10.0", "2.17.5", "2.18.0-rc1", "2.18.0"):
        (repo / "install" / "install.py").write_text(
            f"import sys\nprint('stub {tag}', sys.argv[1:])\nsys.exit(int(open('{tmp_path}/exit').read()))\n"
        )
        sh(repo, "git", "add", "-A")
        sh(repo, "git", "commit", "-q", "-m", tag)
        sh(repo, "git", "tag", tag)
    (tmp_path / "exit").write_text("0")
    return repo


@pytest.fixture
def env(tmp_path, origin):
    shim = tmp_path / "bin"
    shim.mkdir()
    (shim / "python3").symlink_to(sys.executable)
    home = tmp_path / "home"
    home.mkdir()
    return {
        **os.environ,
        "PATH": f"{shim}:{os.environ['PATH']}",
        "HOME": str(home),
        "GEONATURE_REPO": str(origin),
        "GEONATURE_DIR": str(tmp_path / "geonature"),
    }


def run(env, script=None):
    return subprocess.run(
        ["sh", "-s"], input=script or SCRIPT.read_text(), env=env, capture_output=True, text=True
    )


def test_clones_latest_stable_tag_ignoring_rc_and_sorting_numerically(env, tmp_path):
    r = run(env)
    assert r.returncode == 0, r.stderr
    gn = tmp_path / "geonature"
    assert "Récupération de GeoNature 2.18.0 " in r.stdout
    assert (
        subprocess.run(
            ["git", "describe", "--tags"], cwd=gn, capture_output=True, text=True
        ).stdout.strip()
        == "2.18.0"
    )


def test_explicit_version(env, tmp_path):
    r = run({**env, "GEONATURE_VERSION": "2.17.5"})
    assert r.returncode == 0, r.stderr
    assert "stub 2.17.5" in r.stdout


def test_prepares_private_config_and_runs_preflight(env, tmp_path):
    r = run(env)
    toml = tmp_path / "geonature" / "install" / "install.toml"
    assert toml.read_text() == 'my_url = "http://x/"\n' and toml.stat().st_mode & 0o777 == 0o600
    assert "--check" in r.stdout and "Lancez l'installation" in r.stdout
    assert "2. Lancez l'installation" in r.stdout


def test_failing_preflight_is_reported_not_fatal(env, tmp_path):
    (tmp_path / "exit").write_text("1")  # lu par l'install.py cloné
    r = run(env)
    assert r.returncode == 0
    assert "Corrigez les prérequis" in r.stdout and "3. Lancez l'installation" in r.stdout


def test_refuses_existing_directory_and_leaves_it_alone(env, tmp_path):
    gn = tmp_path / "geonature"
    gn.mkdir()
    (gn / "precieux").write_text("x")
    r = run(env)
    assert r.returncode != 0 and "existe déjà" in r.stderr
    assert (gn / "precieux").read_text() == "x" and len(list(gn.iterdir())) == 1


def test_unknown_version_fails_cleanly(env, tmp_path):
    r = run({**env, "GEONATURE_VERSION": "9.9.9"})
    assert r.returncode != 0 and "échec du clonage" in r.stderr


def test_truncated_download_does_nothing(env, tmp_path):
    truncated = "\n".join(SCRIPT.read_text().splitlines()[:-1])  # sans l'appel final à main
    r = run(env, truncated)
    assert r.returncode == 0 and r.stdout == ""
    assert not (tmp_path / "geonature").exists()
