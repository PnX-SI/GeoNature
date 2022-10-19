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


def import_gn_module(module_object):
    module_code = module_object.module_code
    module_dist = get_dist_from_code(module_code)
    module_dir = GN_EXTERNAL_MODULE / module_object.module_path
    frontend_path = os.environ.get(
        f"GEONATURE_{module_code}_FRONTEND_PATH", str(module_dir / "frontend")
    )
    module_config = {
        "MODULE_CODE": module_code,
        "MODULE_URL": "/" + module_object.module_path,
        "FRONTEND_PATH": frontend_path,
    }

    try:
        module_schema = load_entry_point(module_dist, "gn_module", "config_schema")
    except ImportError:
        pass
    else:
        config_path = get_module_config_path(module_object.module_code)
        module_config.update(load_and_validate_toml(str(config_path), module_schema))

    blueprint_entry_point = get_entry_info(module_dist, "gn_module", "blueprint")
    if blueprint_entry_point:
        module_blueprint = blueprint_entry_point.load()
        module_blueprint.config = module_config
    else:
        module_blueprint = None
    return (module_object, module_config, module_blueprint)


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
