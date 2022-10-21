import os
from pathlib import Path
from pkg_resources import load_entry_point, get_entry_info, iter_entry_points

from flask import current_app

from geonature.utils.utilstoml import load_and_validate_toml
from geonature.utils.env import CONFIG_FILE, GN_EXTERNAL_MODULE
from geonature.core.gn_commons.models import TModules


class NoManifestFound(Exception):
    pass


def get_module_config_path(module_code):
    config_path = os.environ.get(f"GEONATURE_{module_code}_CONFIG_FILE")
    if config_path:
        return Path(config_path)
    dist = get_dist_from_code(module_code)
    config_path = Path(dist.module_path).parent / "config" / "conf_gn_module.toml"
    if config_path.exists():
        return config_path
    config_path = Path(CONFIG_FILE).parent / f"{module_code.lower()}_config.toml"
    if config_path.exists():
        return config_path
    return None


def get_module_config(module_dist):
    module_code = load_entry_point(module_dist, "gn_module", "code")
    config_schema = load_entry_point(module_dist, "gn_module", "config_schema")
    return load_and_validate_toml(get_module_config_path(module_code), config_schema)


def get_dist_from_code(module_code):
    for entry_point in iter_entry_points("gn_module", "code"):
        if module_code == entry_point.load():
            return entry_point.dist
    raise Exception(f"Module with code {module_code} not installed in venv")


def import_backend_enabled_modules():
    """
    yield (module_object, module_config, module_blueprint)
    for backend-enabled modules in gn_commons.t_modules
    """
    enabled_modules = (
        TModules.query.with_entities(
            TModules.module_code, TModules.id_module, TModules.module_path
        )
        .filter_by(active_backend=True)
        .all()
    )
    for module_object in enabled_modules:
        # ignore internal module (i.e. without symlink in external module directory)
        if not Path(GN_EXTERNAL_MODULE / module_object.module_code.lower()).exists():
            continue
        if module_object.module_code in current_app.config["DISABLED_MODULES"]:
            continue
        logging.debug(f"Loading module {module_object.module_code}…")
        try:
            yield import_gn_module(module_object)
        except Exception as e:
            logging.exception(e)
            logging.warning(f"Unable to load module {module_object.module_code}, skipping…")
            current_app.config["DISABLED_MODULES"].append(module_object.module_code)


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
