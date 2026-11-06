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


def sourced(path, key):
    """Valeur vue par les anciens scripts bash qui font `. settings.ini`."""
    out = subprocess.run(
        ["bash", "-c", f'. "{path}" && printf %s "${key}"'],
        capture_output=True,
        text=True,
        check=True,
    )
    return out.stdout


def test_special_password_survives_ini_and_toml(root):
    render.render_all(root, {"my_url": "http://x.org/", "user_pg_pass": NASTY})
    settings = root / "config" / "settings.ini"
    assert sourced(settings, "user_pg_pass") == NASTY
    assert sourced(settings, "db_name") == "geonature2db"

    uri = tomllib.loads((root / "config" / "geonature_config.toml").read_text())[
        "SQLALCHEMY_DATABASE_URI"
    ]
    assert NASTY not in uri and "@localhost:5432/" in uri
    from urllib.parse import unquote, urlsplit

    assert unquote(urlsplit(uri).password) == NASTY


def test_ini_values_are_shell_quoted_one_per_line():
    out = render.format_ini({"user_pg": "x y", "proxy_http": "http://p:3128"})
    assert "user_pg='x y'\n" in out and "proxy_http=http://p:3128\n" in out
    assert out.startswith("##")  # en-tête : fichier généré


def test_defaults_fill_missing_keys(root):
    render.render_all(root, {"my_url": "http://x.org/"})
    settings = root / "config" / "settings.ini"
    assert sourced(settings, "srid_local") == "2154"
    assert sourced(settings, "MODE") == "prod"
    assert sourced(settings, "install_module_occhab") == "true"


def test_settings_only_does_not_touch_geonature_config(root):
    written = render.render_all(root, {"my_url": "http://x.org/"}, settings_only=True)
    assert written == [root / "config" / "settings.ini"]
    assert not (root / "config" / "geonature_config.toml").exists()


def test_password_generated_once_then_kept(root):
    cfg = {"my_url": "http://x.org/"}
    render.render_all(root, cfg)
    first = render.read_ini_value(root / "config" / "settings.ini", "user_pg_pass")
    assert len(first) >= 16
    # même un rendu forcé reprend le mot de passe déjà appliqué à la base
    render.render_all(root, cfg, force=True)
    assert render.read_ini_value(root / "config" / "settings.ini", "user_pg_pass") == first


def test_existing_files_not_overwritten(root):
    render.render_all(root, {"my_url": "http://x.org/"})
    before = (root / "config" / "settings.ini").read_text()
    assert render.render_all(root, {"my_url": "http://autre.org/"}) == []
    assert (root / "config" / "settings.ini").read_text() == before


def test_secret_files_are_private(root):
    render.render_all(root, {"my_url": "http://x.org/"})
    assert (root / "config" / "settings.ini").stat().st_mode & 0o777 == 0o600


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
    cfg = render.resolve_config({"my_url": "http://x.org/"}, root / "config" / "settings.ini")
    problems = render.config_mismatches(root, cfg)
    assert any("settings.ini : db_name=autre" in p for p in problems)
    assert any("geonature_config.toml : db_name=autre" in p for p in problems)


def test_matching_config_has_no_mismatch(root):
    user = {"my_url": "http://x.org/", "db_name": "gn", "user_pg": "u", "user_pg_pass": "p@ss/w"}
    render.render_all(root, user)
    cfg = render.resolve_config(user, root / "config" / "settings.ini")
    assert render.config_mismatches(root, cfg) == []


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
