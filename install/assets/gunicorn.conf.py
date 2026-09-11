import os

from geonature.utils.env import CONFIG_FILE
from geonature.utils.module import iter_modules_config

reload = True
reload_extra_files = []
if os.path.exists(CONFIG_FILE):
    reload_extra_files.append(CONFIG_FILE)
reload_extra_files.extend(iter_modules_config())
