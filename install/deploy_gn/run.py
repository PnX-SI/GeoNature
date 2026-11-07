import io
import json
import sys

from config import *
from connection import connect

RAW = "https://raw.githubusercontent.com/PnX-SI/GeoNature"


def install_toml():
    """install.toml de test : les autres paramètres prennent les valeurs par défaut de l'installateur."""
    values = {
        "mode": "prod",
        "my_url": DOMAIN,
        "db_name": DB_NAME,
        "drop_apps_db": bool(DROP_DB),
        "install_default_dem": False,
    }
    return "\n".join(f"{k} = {json.dumps(v)}" for k, v in values.items()) + "\n"


def deploy():
    conn = connect()
    # Le script clone GeoNature (clone superficiel) et prépare install/install.toml ; les questions sont
    # désactivées car le fichier est écrit ici. Le serveur doit autoriser `sudo` sans mot de passe.
    conn.run(
        f"curl -LsSf {RAW}/{GN_VERSION}/install/get-geonature.sh | "
        f"GEONATURE_REPO={GN_REPO} GEONATURE_VERSION={GN_VERSION} GEONATURE_DIR=$HOME/{GN_DIR} "
        "GEONATURE_NO_PROMPT=1 sh"
    )
    conn.put(io.StringIO(install_toml()), f"{GN_DIR}/install/install.toml")
    confirm = f" --confirm-drop {DB_NAME}" if DROP_DB else ""
    conn.run(
        f"cd {GN_DIR} && python3 install/install.py --config install/install.toml{confirm} "
        "2>&1 | tee install.log"
    )


def clean():
    """Retire les services et la configuration Apache, puis le dossier. La base n'est pas supprimée."""
    conn = connect()
    conn.run(f"cd {GN_DIR} && python3 install/install.py uninstall --yes", warn=True)
    conn.run(f"rm -rf {GN_DIR} install.log")


if __name__ == "__main__":
    if len(sys.argv) == 1:
        print("Pass 'deploy' or 'clean' argument to the script")
    elif len(sys.argv) > 1:
        arg1 = sys.argv[1]
        if arg1 == "deploy":
            deploy()
        elif arg1 == "clean":
            clean()
        else:
            print("Pass 'deploy' or 'clean' argument to the script")
