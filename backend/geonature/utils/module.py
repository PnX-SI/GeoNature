import os
import sys
from pathlib import Path
from importlib import import_module
from pkg_resources import load_entry_point, get_entry_info, iter_entry_points

from geonature.utils.utilstoml import load_and_validate_toml
from geonature.utils.config_schema import ManifestSchemaProdConf
from geonature.utils.env import GN_EXTERNAL_MODULE
from geonature.core.gn_commons.models import TModules


class NoManifestFound(Exception):
    pass


def import_legacy_module(module_object):
    sys.path.insert(0, str(GN_EXTERNAL_MODULE))  # to be able to import non-packaged modules
    try:
        # module dist is module_code.lower() because the symlink is created like this
        # in utils.gn_module_import.copy_in_external_mods
        module_dist = module_object.module_code.lower()
        module_dir = GN_EXTERNAL_MODULE / module_dist
        manifest_path = module_dir / 'manifest.toml'
        if not manifest_path.is_file():
            raise NoManifestFound()
        module_manifest = load_and_validate_toml(manifest_path, ManifestSchemaProdConf)
        module_blueprint = import_module(f'{module_dist}.backend.blueprint').blueprint
        module_config = {
            'ID_MODULE': module_object.id_module,
            'MODULE_CODE': module_object.module_code,
            'MODULE_URL': '/' + module_object.module_path.replace(' ', ''),
            'FRONTEND_PATH': str(module_dir / 'frontend'),
        }
        module_schema = import_module(f'{module_object.module_code.lower()}.config.conf_schema_toml').GnModuleSchemaConf
        config_path = module_dir / "config/conf_gn_module.toml"
        module_config.update(load_and_validate_toml(config_path, module_schema))
        module_blueprint.config = module_config
        return module_config, module_blueprint
    finally:
        sys.path.pop(0)


def import_packaged_module(module_dist, module_object):
    module_code = module_object.module_code
    module_dir = GN_EXTERNAL_MODULE / module_object.module_path
    frontend_path = os.environ.get(f'GEONATURE_{module_code}_FRONTEND_PATH',
                                   str(module_dir / 'frontend'))
    module_config = {
        'MODULE_CODE': module_code,
        'MODULE_URL': '/' + module_object.module_path,
        'FRONTEND_PATH': frontend_path,
    }

    try:
        module_schema = load_entry_point(module_dist, 'gn_module', 'config_schema')
    except ImportError:
        pass
    else:
        config_path = os.environ.get(f'GEONATURE_{module_object.module_code}_CONFIG_FILE')
        if not config_path:  # fallback to legacy conf path guessing
            config_path = str(module_dir / 'config/conf_gn_module.toml')
        module_config.update(load_and_validate_toml(config_path, module_schema))

    blueprint_entry_point = get_entry_info(module_dist, 'gn_module', 'blueprint')
    if blueprint_entry_point:
        module_blueprint = blueprint_entry_point.load()
        module_blueprint.config = module_config
    else:
        module_blueprint = None
    return (module_object, module_config, module_blueprint)


def get_dist_from_code(module_code):
    for entry_point in iter_entry_points('gn_module', 'code'):
        if module_code == entry_point.load():
            return entry_point.dist


def import_gn_module(module_object):
    """
    return (module_object, module_config, module_blueprint)
    module_blueprint may be None in case of front-only module
    """
    # try to find a packaged module with the given code
    module_dist = get_dist_from_code(module_object.module_code)
    if module_dist:
        return import_packaged_module(module_dist, module_object)
    else:
        module_config, module_blueprint = import_legacy_module(module_object)
        return (module_object, module_config, module_blueprint)


def import_backend_enabled_modules():
    """
        yield (module_object, module_config, module_blueprint)
        for backend-enabled modules in gn_commons.t_modules
    """
    enabled_modules = TModules.query.filter_by(active_backend=True).all()
    for module_object in enabled_modules:
        # ignore internal module (i.e. without symlink in external module directory)
        if not Path(GN_EXTERNAL_MODULE / module_object.module_code.lower()).exists():
            continue
        yield import_gn_module(module_object)


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
        yield module_object
