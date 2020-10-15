import os
import sys
from pathlib import Path

from geonature.core.command.main import main
import geonature.core.command.create_gn_module


# Load modules commands
from geonature.utils.env import ROOT_DIR


def import_cmd(dir_name):
    try:
        print("Import module {}".format(dir_name))

        module_cms = __import__("{}.backend.commands.geonature_cmd".format(dir_name))

        print(" ... Module imported".format(dir_name))
    except FileNotFoundError as e:
        # Si l'erreur est liée à un fichier inexistant
        #       création du fichier et réimport de la commande
        print(" ... FileNotFoundError", e.filename)
        Path(os.path.dir_name(e.filename)).mkdir(parents=True, exist_ok=True)
        import_cmd(dir_name)


plugin_folder = os.path.join(str(ROOT_DIR), "external_modules")
sys.path.insert(0, os.path.join(plugin_folder))

for dir_name in os.listdir(plugin_folder):
    cmd_file = os.path.join(plugin_folder, dir_name, "backend", "commands", "geonature_cmd.py")

    if os.path.isfile(cmd_file):
        import_cmd(dir_name)
