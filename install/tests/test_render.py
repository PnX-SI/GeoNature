import shlex
import shutil
import subprocess
import sys
import tomllib
from pathlib import Path

import pytest

sys.path.insert(0, str(Path(__file__).resolve().parents[1]))

from installer import render

REPO = Path(__file__).resolve().parents[2]
NASTY = "p/a&s#s'w\"$o rd@:%"


@pytest.fixture
def root(tmp_path):
    (tmp_path / "config").mkdir()
    for name in ("geonature_config.toml.sample",):
        shutil.copy(REPO / "config" / name, tmp_path / "config" / name)
    return tmp_path


def sourced(text, key):
    """Valeur vue par un script shell qui fait `eval "$(install.py --print-settings)"`."""
    out = subprocess.run(
        ["bash", "-c", f'eval "$1" && printf %s "${key}"', "_", text],
        capture_output=True,
        text=True,
        check=True,
    )
    return out.stdout


def test_special_password_survives_shell_and_toml(root):
    user = {"my_url": "http://x.org/", "user_pg_pass": NASTY}
    render.render_all(root, user)
    text = render.settings_text(user)
    assert sourced(text, "user_pg_pass") == NASTY
    assert sourced(text, "db_name") == "geonature2db"

    uri = tomllib.loads((root / "config" / "geonature_config.toml").read_text())[
        "SQLALCHEMY_DATABASE_URI"
    ]
    assert NASTY not in uri and "@localhost:5432/" in uri
    from urllib.parse import unquote, urlsplit

    assert unquote(urlsplit(uri).password) == NASTY


def test_ini_values_are_shell_quoted_one_per_line():
    out = render.format_ini({"user_pg": "x y", "proxy_http": "http://p:3128"})
    assert "user_pg='x y'\n" in out and "proxy_http=http://p:3128\n" in out
    assert out.startswith("##")


def test_defaults_fill_missing_keys():
    text = render.settings_text({"my_url": "http://x.org/"})
    assert sourced(text, "srid_local") == "2154"
    assert sourced(text, "MODE") == "prod"
    assert sourced(text, "install_module_occhab") == "true"


def test_settings_ini_is_no_longer_generated(root):
    written = render.render_all(root, {"my_url": "http://x.org/"})
    assert written == [root / "config" / "geonature_config.toml"]
    assert not (root / "config" / "settings.ini").exists()


def test_legacy_settings_ini_password_is_still_read(root):
    (root / "config" / "settings.ini").write_text("user_pg_pass=ancien\n")
    cfg = render.resolve_config({"my_url": "http://x.org/"}, root / "config" / "settings.ini")
    assert cfg["user_pg_pass"] == "ancien"


def test_existing_files_not_overwritten(root):
    render.render_all(root, {"my_url": "http://x.org/"})
    before = (root / "config" / "geonature_config.toml").read_text()
    assert render.render_all(root, {"my_url": "http://autre.org/"}) == []
    assert (root / "config" / "geonature_config.toml").read_text() == before


def test_secret_files_are_private(root):
    render.render_all(root, {"my_url": "http://x.org/"})
    assert (root / "config" / "geonature_config.toml").stat().st_mode & 0o777 == 0o600


@pytest.mark.parametrize(
    "my_url,prefix,expected",
    [
        ("http://x.org/", "geonature", "http://x.org/geonature"),
        ("http://x.org", "/saisie/", "http://x.org/saisie"),
        ("http://x.org/", "", "http://x.org"),
    ],
)
def test_application_urls(my_url, prefix, expected):
    app, api = render.application_urls(my_url, prefix)
    assert (app, api) == (expected, expected + "/api")


def test_empty_prefix_is_kept_as_root(root):
    render.render_all(root, {"my_url": "http://x.org/", "url_application_prefix_path": ""})
    gn = tomllib.loads((root / "config" / "geonature_config.toml").read_text())
    assert gn["URL_APPLICATION"] == "http://x.org"


def test_sample_install_toml_is_valid_and_complete():
    cfg = tomllib.loads((REPO / "install" / "install.sample.toml").read_text())
    cfg["MODE"] = cfg.pop("mode")
    unknown = set(cfg) - set(render.SETTINGS_KEYS)
    assert not unknown


def test_existing_config_pointing_elsewhere_is_reported(root):
    render.render_all(root, {"my_url": "http://x.org/", "db_name": "autre"})
    (root / "config" / "settings.ini").write_text("db_name=autre\n")  # ancienne installation
    cfg = render.resolve_config({"my_url": "http://x.org/"})
    problems = render.config_mismatches(root, cfg)
    assert any("settings.ini : db_name=autre" in p for p in problems)
    assert any("geonature_config.toml : db_name=autre" in p for p in problems)


def test_matching_config_has_no_mismatch(root):
    user = {"my_url": "http://x.org/", "db_name": "gn", "user_pg": "u", "user_pg_pass": "p@ss/w"}
    render.render_all(root, user)
    assert render.config_mismatches(root, render.resolve_config(user)) == []


def test_dev_mode_api_endpoint_is_the_backend_port(root):
    cfg = {"my_url": "http://127.0.0.1:4200/", "mode": "dev", "url_application_prefix_path": ""}
    render.render_all(root, cfg)
    gn = tomllib.loads((root / "config" / "geonature_config.toml").read_text())
    assert gn["URL_APPLICATION"] == "http://127.0.0.1:4200"
    assert gn["API_ENDPOINT"] == "http://127.0.0.1:8000"  # pas d'Apache ni de proxy en dev


def test_prod_api_endpoint_unchanged_by_dev_port(root):
    render.render_all(root, {"my_url": "http://x.org/", "dev_backend_port": 9999})
    gn = tomllib.loads((root / "config" / "geonature_config.toml").read_text())
    assert gn["API_ENDPOINT"] == "http://x.org/geonature/api"


def test_generated_password_is_persisted_in_install_toml(tmp_path, monkeypatch):
    import importlib

    sys.path.insert(0, str(REPO / "install"))
    install = importlib.import_module("install")
    monkeypatch.setattr(install, "ROOT", tmp_path)
    toml = tmp_path / "install.toml"
    toml.write_text('my_url = "http://x.org/"\nuser_pg_pass = ""  # généré\n')
    cfg = install.persist_password(toml, tomllib.loads(toml.read_text()))
    saved = tomllib.loads(toml.read_text())["user_pg_pass"]
    assert saved and cfg["user_pg_pass"] == saved and toml.stat().st_mode & 0o777 == 0o600
    assert "# généré" in toml.read_text()
    # relance : rien n'est régénéré, install.toml fait foi sans settings.ini
    again = install.persist_password(toml, tomllib.loads(toml.read_text()))
    assert again["user_pg_pass"] == saved
    assert render.resolve_config(again)["user_pg_pass"] == saved


def test_legacy_settings_ini_password_is_migrated_into_install_toml(tmp_path, monkeypatch):
    import importlib

    sys.path.insert(0, str(REPO / "install"))
    install = importlib.import_module("install")
    monkeypatch.setattr(install, "ROOT", tmp_path)
    (tmp_path / "config").mkdir()
    (tmp_path / "config" / "settings.ini").write_text("user_pg_pass=ancien\n")
    toml = tmp_path / "install.toml"
    toml.write_text('my_url = "http://x.org/"\nuser_pg_pass = ""\n')
    install.persist_password(toml, tomllib.loads(toml.read_text()))
    assert tomllib.loads(toml.read_text())["user_pg_pass"] == "ancien"
