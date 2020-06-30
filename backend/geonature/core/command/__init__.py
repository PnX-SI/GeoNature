import os
import sys
from pathlib import Path

from geonature.core.command.main import main
import geonature.core.command.create_gn_module


# Load modules commands
from geonature.utils.env import ROOT_DIR


def import_cmd(dirname):
    try:
        print("Import module {}".format(dirname))

        module_cms = __import__(
            "{}.backend.commands.geonature_cmd".format(dirname)
        )

        print(" ... Module imported".format(dirname))
    except FileNotFoundError as e:
        # Si l'erreur est liée à un fichier inexistant
        #       création du fichier et réimport de la commande
        print(" ... FileNotFoundError", e.filename)
        Path(os.path.dirname(e.filename)).mkdir(
            parents=True, exist_ok=True
        )
        import_cmd(dirname)

plugin_folder = os.path.join(str(ROOT_DIR), 'external_modules')
sys.path.insert(0, os.path.join(plugin_folder))

for dirname in os.listdir(plugin_folder):
    cmd_file = os.path.join(
        plugin_folder,
        dirname,
        'backend',
        'commands',
        'geonature_cmd.py'
    )

    if (os.path.isfile(cmd_file)):
        import_cmd(dirname)

