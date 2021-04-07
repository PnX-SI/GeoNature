import os
import sys
from pathlib import Path
from importlib import import_module
from pkg_resources import load_entry_point, iter_entry_points

from sqlalchemy.orm.exc import NoResultFound

from geonature.utils.utilstoml import load_and_validate_toml
from geonature.utils.config_schema import ManifestSchemaProdConf
from geonature.utils.env import GN_EXTERNAL_MODULE, \
                                GN_MODULE_FE_FILE, GN_MODULE_FILES
from geonature.utils.config import config
from geonature.core.gn_commons.models import TModules


class NoManifestFound(Exception):
    pass



def import_legacy_module(module_object):
    sys.path.insert(0, str(GN_EXTERNAL_MODULE))  # to be able to import non-packaged modules
    try:
        module_dir = GN_EXTERNAL_MODULE / module_object.module_path
        manifest_path = module_dir / 'manifest.toml'
        module_config = {
            'ID_MODULE': module_object.id_module,
            'MODULE_CODE': module_object.module_code,
        }
        if not manifest_path.is_file():
            raise NoManifestFound()
        module_manifest = load_and_validate_toml(manifest_path, ManifestSchemaProdConf)
        # module dist is module_code.lower() because the symlink is created like this
        # in utils.gn_module_import.copy_in_external_mods
        module_dist = module_object.module_code.lower()
        module_schema = import_module(f'{module_dist}.config.conf_schema_toml').GnModuleSchemaConf
        module_blueprint = import_module(f'{module_dist}.backend.blueprint').blueprint
        config_path = module_dir / "config/conf_gn_module.toml"
        module_config.update({
            'MODULE_URL': '/' + module_object.module_path.replace(' ', ''),
            'FRONTEND_PATH': str(module_dir / 'frontend'),
        })
        module_config.update(load_and_validate_toml(config_path, module_schema))
        module_blueprint.config = module_config
        return module_config, module_blueprint
    finally:
        sys.path.pop(0)


def get_dist_from_code(module_code):
    for entry_point in iter_entry_points('gn_module', 'code'):
        if module_code == entry_point.load():
            return entry_point.dist
    raise Exception(f"No installed module with code '{module_code}' found.")


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

    module_schema = load_entry_point(module_dist, 'gn_module', 'config_schema')
    config_path = os.environ.get(f'GEONATURE_{module_object.module_code}_CONFIG_FILE')
    if not config_path:  # fallback to legacy conf path guessing
        config_path = str(module_dir / 'config/conf_gn_module.toml')
    module_config.update(load_and_validate_toml(config_path, module_schema))

    try:
        module_blueprint = load_entry_point(module_dist, 'gn_module', 'blueprint')
    except ImportError:
        # this module has no backend
        module_blueprint = None
    else:
        module_blueprint.config = module_config
    return (module_object, module_config, module_blueprint)


def import_backend_enabled_modules():
    # ⇒ import packaged modules
    for module_code in config['ENABLED_MODULES']:
        module_dist = get_dist_from_code(module_code)
        try:
            module_object = TModules.query.filter_by(module_code=module_code).one()
        except NoResultFound:
            raise Exception(f"Module with code '{module_code}' not found in database; "
                             "have you installed its database schema "
                             "(flask db upgread module_name@head)?")
        module_object, module_config, module_blueprint = import_packaged_module(module_dist, module_object)
        if not module_blueprint:  # module without backend routes
            continue
        yield module_object, module_config, module_blueprint
    # ⇒ import legacy modules
    enabled_modules = TModules.query.filter(TModules.active_backend == True).all()
    for module_object in enabled_modules:
        try:
            module_config, module_blueprint = import_legacy_module(module_object)
        except NoManifestFound:
            # an internal module which we do not require to be imported
            # or a packaged module (in both case without legacy manifest)
            continue
        yield module_object, module_config, module_blueprint


def import_frontend_module(module_object):
    module_config = None
    # try to find a packaged module with the given code
    try:
        module_dist = get_dist_from_code(module_object.module_code)
    except Exception:
        pass
    else:
        _, module_config, _ = import_packaged_module(module_dist, module_object)
    if not module_config:
        # if no packaged module found, try to load a legacy module
        module_config, _ = import_legacy_module(module_object)
    return module_config


def import_frontend_enabled_modules():
    """
        Get all the module frontend enabled from gn_commons.t_modules
        and return the url path and the module_code
    """
    enabled_modules = TModules.query.filter(TModules.active_frontend == True).all()
    for module_object in enabled_modules:
        # some modules are front-enabled in database, but without frontend dir (e.g. admin)
        if not Path(GN_EXTERNAL_MODULE / module_object.module_path).exists():
            continue
        yield import_frontend_module(module_object)
