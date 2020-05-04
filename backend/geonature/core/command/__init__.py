import os
import sys

from geonature.core.command.main import main
import geonature.core.command.create_gn_module


# Load modules commands
from geonature.utils.env import ROOT_DIR
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
        module_cms = __import__(
            "{}.backend.commands.geonature_cmd".format(dirname)
        )