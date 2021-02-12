import os
import sys
from pathlib import Path
from importlib import import_module
from pkg_resources import load_entry_point

from geonature.utils.utilstoml import load_and_validate_toml
from geonature.utils.config_schema import ManifestSchemaProdConf
from geonature.utils.env import GN_EXTERNAL_MODULE, \
                                GN_MODULE_FE_FILE, GN_MODULE_FILES
from geonature.core.gn_commons.models import TModules



def import_gn_module(mod):
    sys.path.insert(0, str(GN_EXTERNAL_MODULE))  # to be able to import non-packaged modules
    try:
        module_name = mod.module_path
        module = import_module(module_name)
        module_path = Path(module.__file__).parent
        manifest_path = module_path / 'manifest.toml'
        module_config = {
            'ID_MODULE': mod.id_module,
            'MODULE_CODE': mod.module_code,
            'BACKEND_PATH': str(module_path / 'backend'),
            'FRONTEND_PATH': str(module_path / 'frontend'),
        }
        if manifest_path.is_file():  # non-packaged module
            module_manifest = load_and_validate_toml(module_path / 'manifest.toml', ManifestSchemaProdConf)
            module_schema = import_module(f'{module_name}.config.conf_schema_toml').GnModuleSchemaConf
            module_blueprint = import_module(f'{module_name}.backend.blueprint').blueprint
            config_path = str(module_path / "config/conf_gn_module.toml")
            module_config.update({
                'MODULE_URL': '/' + mod.module_path.replace(' ', ''),
            })
        else:
            module_blueprint = load_entry_point(module_name, 'gn_module', 'blueprint')
            module_schema = load_entry_point(module_name, 'gn_module', 'config_schema')
            config_path = os.environ.get(f'GEONATURE_{mod.module_code}_CONFIG_FILE')
            if not config_path:  # fallback to legacy conf path guessing
                # .parent.parent goes up 'backend/{module_name}'
                config_path = str(module_path.parent.parent / 'config/conf_gn_module.toml')
            module_config.update({
                'MODULE_URL': '/' + mod.module_code.lower(),
            })
        module_config.update(load_and_validate_toml(config_path, module_schema))
        #app.config[mod.module_code] = module_config
        module_blueprint.config = module_config
        return module, module_blueprint
    finally:
        sys.path.pop(0)


def import_backend_enabled_modules():
    enabled_modules = TModules.query.filter(TModules.active_backend == True).all()
    for mod in enabled_modules:
        try:
            module, module_blueprint = import_gn_module(mod)
        except ModuleNotFoundError:
            # probably an internal module which we do not require to import
            # (we miss a method to differentiate internal module with imported module)
            continue
        yield module, module_blueprint


def import_frontend_enabled_modules():
    """
        Get all the module frontend enabled from gn_commons.t_modules
        and return the url path and the module_code
    """
    enabled_modules = TModules.query.filter(TModules.active_frontend == True).all()
    for mod in enabled_modules:
        try:
            module, blueprint = import_gn_module(mod)
        except ModuleNotFoundError:
            # probably an internal module which we do not require to import
            # (we miss a method to differentiate internal module with imported module)
            continue
        yield blueprint.config['MODULE_URL'], mod.module_code
