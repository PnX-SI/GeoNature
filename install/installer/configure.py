"""Saisie interactive des principaux paramètres de `install.toml` (`install.py --configure`).

Le fichier est modifié ligne par ligne : seules les valeurs des clés de premier niveau changent, les
commentaires et la mise en forme de `install.sample.toml` sont conservés. Les valeurs sont écrites en
TOML (chaînes JSON) : aucun caractère spécial n'est interprété.
"""

import getpass
import json
import re
from pathlib import Path

from . import render
from .style import PLAIN

MODES = ("prod", "dev", "ci")
YES = ("o", "oui", "y", "yes", "true")
NO = ("n", "non", "no", "false")

# (clé, question, type) ; "mode" propose un choix, "secret" ne s'affiche pas à la frappe
MAIN_QUESTIONS = (
    ("mode", "Mode d'installation (prod, dev, ci)", "mode"),
    ("my_url", "URL publique de GeoNature (ex. http://mon.domaine.fr/)", "url"),
    ("url_application_prefix_path", "Préfixe de l'application (- : à la racine)", "str"),
    ("db_host", "Hôte PostgreSQL", "str"),
    ("db_port", "Port PostgreSQL", "int"),
    ("db_name", "Nom de la base de données", "str"),
    ("user_pg", "Utilisateur PostgreSQL de GeoNature", "str"),
    ("user_pg_pass", "Mot de passe PostgreSQL (vide : généré)", "secret"),
)

DATA_QUESTIONS = (
    ("srid_local", "SRID local (2154 : Lambert 93)", "int"),
    ("install_bdc_statuts", "Importer les statuts TAXREF (long)", "bool"),
    ("install_sig_layers", "Installer les couches SIG (communes, départements…)", "bool"),
    ("install_grid_layer", "Installer les mailles", "bool"),
    ("install_default_dem", "Installer le MNT par défaut", "bool"),
    ("add_sample_data", "Ajouter les données d'exemple", "bool"),
    ("install_ref_sensitivity", "Installer le référentiel de sensibilité", "bool"),
    ("install_module_validation", "Installer le module Validation", "bool"),
    ("install_module_occhab", "Installer le module Occhab", "bool"),
)

LINE = r"^(?P<head>{key}[ \t]*=[ \t]*)(?P<value>\"(?:[^\"\\]|\\.)*\"|'[^']*'|[^\s#]*)(?P<tail>.*)$"


def toml_value(value):
    if isinstance(value, bool):
        return "true" if value else "false"
    if isinstance(value, int):
        return str(value)
    return json.dumps(str(value), ensure_ascii=False)


def set_values(text, values):
    """Remplace `clé = valeur` (premier niveau) en gardant le commentaire de fin de ligne ; ajoute les clés absentes."""
    for key, value in values.items():
        pattern = re.compile(LINE.format(key=re.escape(key)), re.M)
        new = toml_value(value)
        if pattern.search(text):
            text = pattern.sub(lambda m: m["head"] + new + m["tail"], text, count=1)
        else:
            text = text.rstrip("\n") + f"\n{key} = {new}\n"
    return text


def _default(cfg, key):
    value = cfg.get(key, render.DEFAULTS.get("MODE" if key == "mode" else key))
    return "" if value is None else value


def _convert(kind, raw):
    """Retourne la valeur typée, ou lève ValueError avec le message à afficher."""
    if kind == "mode":
        if raw not in MODES:
            raise ValueError(f"choisissez parmi : {', '.join(MODES)}")
    elif kind == "url":
        if not re.match(r"^https?://[^\s/]+", raw):
            raise ValueError("l'URL doit commencer par http:// ou https://")
        return raw if raw.endswith("/") else raw + "/"
    elif kind == "int":
        if not raw.isdigit():
            raise ValueError("un nombre entier est attendu")
        return int(raw)
    elif kind == "str" and raw == "-":
        return ""  # Entrée garde la valeur proposée ; « - » force une valeur vide
    elif kind == "bool":
        if raw.lower() in YES:
            return True
        if raw.lower() in NO:
            return False
        raise ValueError("répondez par o (oui) ou n (non)")
    return raw


def ask(kind, question, default, input_fn, secret_fn, out, style=PLAIN):
    shown = default
    if kind == "bool":
        shown = "o" if str(default).lower() == "true" else "n"
    suffix = "" if kind == "secret" else " " + style.cyan(f"[{shown}]")
    while True:
        read = secret_fn if kind == "secret" else input_fn
        raw = read(f"{style.bold(question)}{suffix} : ").strip()
        if raw == "":
            if kind == "secret":
                return ""
            raw = str(shown)
        try:
            return _convert(kind, raw)
        except ValueError as e:
            out(style.yellow(f"  ! {e}"))


def configure(path, cfg, input_fn=input, secret_fn=getpass.getpass, out=print, style=PLAIN):
    """Pose les questions, écrit `path` et retourne les valeurs choisies."""
    answers = {}

    def run(questions):
        for key, question, kind in questions:
            default = _default({**cfg, **answers}, key)
            if kind == "bool":
                default = str(default).lower()
            value = ask(kind, question, default, input_fn, secret_fn, out, style)
            if kind == "secret" and value == "":
                continue  # mot de passe laissé tel quel (déjà dans le fichier, ou généré à l'installation)
            answers[key] = value

    out(
        style.bold(
            "⚙️  Configuration de l'installation"
            if style.enabled
            else "Configuration de l'installation"
        )
    )
    out(style.gray("Entrée : garder la valeur proposée\n"))
    run(MAIN_QUESTIONS)
    if ask(
        "bool", "Personnaliser les données et les modules", "false", input_fn, secret_fn, out, style
    ):
        run(DATA_QUESTIONS)

    path = Path(path)
    path.write_text(set_values(path.read_text(), answers))
    path.chmod(0o600)
    return answers
