import os
from pathlib import Path
from pkg_resources import load_entry_point, get_entry_info, iter_entry_points

from flask import current_app

from geonature.utils.utilstoml import load_and_validate_toml
from geonature.utils.env import GN_EXTERNAL_MODULE
from geonature.core.gn_commons.models import TModules


class NoManifestFound(Exception):
    pass


def get_module_config_path(module_code):
    config_path = os.environ.get(f"GEONATURE_{module_code.lower()}_CONFIG_FILE")
    if config_path:  # fallback to legacy conf path guessing
        config_path = Path(config_path)
    else:
        config_path = GN_EXTERNAL_MODULE / module_code.lower() / "config" / "conf_gn_module.toml"
    return config_path


def get_dist_from_code(module_code):
    for entry_point in iter_entry_points("gn_module", "code"):
        if module_code == entry_point.load():
            return entry_point.dist
    raise Exception(f"Module with code {module_code} not installed in venv")


def list_frontend_enabled_modules():
    """
    yield module_config
    for frontend-enabled modules in gn_commons.t_modules
    """
    enabled_modules = TModules.query.filter_by(active_frontend=True).all()
    for module_object in enabled_modules:
        # ignore internal module (i.e. without symlink in external module directory)
        if not Path(GN_EXTERNAL_MODULE / module_object.module_code.lower()).exists():
            continue
        if module_object.module_code in current_app.config["DISABLED_MODULES"]:
            continue
        yield module_object
