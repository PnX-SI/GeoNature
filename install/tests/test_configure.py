import sys
import tomllib
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parents[1]))

from installer import configure

REPO = Path(__file__).resolve().parents[2]
NASTY = 'p"a#s\\s w$'


def sample(tmp_path):
    path = tmp_path / "install.toml"
    path.write_text((REPO / "install" / "install.sample.toml").read_text())
    return path


def answers(*values):
    it = iter(values)
    return lambda prompt: next(it)


def test_set_values_keeps_comments_and_replaces_only_that_key():
    text = 'mode = "prod"      # note\nmy_url = "http://a/"\n'
    out = configure.set_values(text, {"mode": "ci"})
    assert out == 'mode = "ci"      # note\nmy_url = "http://a/"\n'


def test_set_values_handles_hash_inside_string_and_appends_missing_key():
    text = 'user_pg_pass = "a#b"   # c\n'
    out = configure.set_values(text, {"user_pg_pass": NASTY, "db_port": 5433})
    parsed = tomllib.loads(out)
    assert parsed["user_pg_pass"] == NASTY and parsed["db_port"] == 5433
    assert "# c" in out


def test_configure_writes_valid_toml_with_typed_values(tmp_path):
    path = sample(tmp_path)
    # mode, url, prefixe, hôte, port, base, utilisateur ; mot de passe ; pas de personnalisation
    configure.configure(
        path,
        tomllib.loads(path.read_text()),
        input_fn=answers("ci", "http://gn.example.org", "", "db.local", "5433", "gn", "u", "n"),
        secret_fn=lambda p: NASTY,
        out=lambda m: None,
    )
    cfg = tomllib.loads(path.read_text())
    assert cfg["mode"] == "ci" and cfg["my_url"] == "http://gn.example.org/"
    assert cfg["url_application_prefix_path"] == "geonature"  # Entrée : valeur proposée
    assert (cfg["db_host"], cfg["db_port"], cfg["db_name"], cfg["user_pg"]) == (
        "db.local",
        5433,
        "gn",
        "u",
    )
    assert cfg["user_pg_pass"] == NASTY
    assert cfg["install_default_dem"] is True  # non personnalisé : inchangé
    assert path.stat().st_mode & 0o777 == 0o600


def test_enter_keeps_current_values_and_existing_password(tmp_path):
    path = sample(tmp_path)
    path.write_text(path.read_text().replace('user_pg_pass = ""', 'user_pg_pass = "secret"'))
    before = tomllib.loads(path.read_text())
    configure.configure(
        path,
        before,
        input_fn=answers(*[""] * 8),
        secret_fn=lambda p: "",
        out=lambda m: None,
    )
    assert tomllib.loads(path.read_text()) == before


def test_invalid_answers_are_asked_again(tmp_path):
    path = sample(tmp_path)
    messages = []
    configure.configure(
        path,
        tomllib.loads(path.read_text()),
        input_fn=answers(
            "bogus", "dev", "mon.domaine", "http://x.fr/", *[""] * 4, "abc", "5432", "", "n"
        ),
        secret_fn=lambda p: "",
        out=messages.append,
    )
    cfg = tomllib.loads(path.read_text())
    assert cfg["mode"] == "dev" and cfg["my_url"] == "http://x.fr/" and cfg["db_port"] == 5432
    assert sum("!" in m for m in messages) == 3


def test_customize_asks_data_and_modules(tmp_path):
    path = sample(tmp_path)
    configure.configure(
        path,
        tomllib.loads(path.read_text()),
        input_fn=answers(*[""] * 7, "o", "2154", "n", "n", "n", "n", "n", "n", "n", "o"),
        secret_fn=lambda p: "",
        out=lambda m: None,
    )
    cfg = tomllib.loads(path.read_text())
    assert cfg["install_sig_layers"] is False and cfg["install_module_occhab"] is True


def test_dash_sets_an_empty_value(tmp_path):
    path = sample(tmp_path)
    configure.configure(
        path,
        tomllib.loads(path.read_text()),
        input_fn=answers("", "", "-", *[""] * 5),
        secret_fn=lambda p: "",
        out=lambda m: None,
    )
    assert tomllib.loads(path.read_text())["url_application_prefix_path"] == ""
