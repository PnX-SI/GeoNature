import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parents[1]))

from installer import render, summary


def cfg(**user):
    return render.resolve_config({"my_url": "http://gn.example.org/", **user}, Path("/nonexistent"))


def test_prod_summary_gives_url_login_and_services():
    text = summary.format_summary(cfg(), "/srv/geonature")
    assert "http://gn.example.org/geonature/" in text
    assert "http://gn.example.org/geonature/api" in text
    assert "admin / admin" in text
    assert "systemctl status geonature geonature-worker" in text
    assert "/srv/geonature/install/install.log" in text


def test_summary_never_prints_the_database_password():
    text = summary.format_summary(cfg(user_pg_pass="s3cr3t-pass"), "/srv/geonature")
    assert "s3cr3t-pass" not in text and "install/install.toml" in text


def test_dev_summary_gives_dev_commands_and_backend_api():
    text = summary.format_summary(
        cfg(mode="dev", my_url="http://127.0.0.1:4200/", url_application_prefix_path=""),
        "/srv/geonature",
    )
    assert "geonature dev-back --port 8000" in text and "npm run start" in text
    assert "API                 : http://127.0.0.1:8000" in text
    assert "systemctl" not in text
