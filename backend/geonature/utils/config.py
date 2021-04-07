import os
import logging
from pathlib import Path
import sys

from collections import ChainMap

from pkg_resources import load_entry_point

from geonature.utils.config_schema import (
    GnGeneralSchemaConf,
    GnPySchemaConf,
)
from geonature.utils.utilstoml import load_and_validate_toml
from geonature.utils.env import (
    DEFAULT_CONFIG_FILE, DB, GN_EXTERNAL_MODULE,
    ROOT_DIR, MAIL
)

from geonature.utils.module import import_backend_enabled_modules

log = logging.getLogger(__name__)


config_path = os.environ.get("GEONATURE_CONFIG_FILE", DEFAULT_CONFIG_FILE)
config_backend = load_and_validate_toml(config_path, GnPySchemaConf)
config_frontend = load_and_validate_toml(config_path, GnGeneralSchemaConf)
config = ChainMap({}, config_frontend, config_backend)


# def get_updated_config(app):
#     """
#         Get config (pour pouvoir relire et mettre à jour la config)
#     """
#     # A factoriser avec app.py


#     config_backend = load_and_validate_toml(config_path, GnPySchemaConf)
#     config_frontend = load_and_validate_toml(config_path, GnGeneralSchemaConf)
#     config = ChainMap({}, config_frontend, config_backend)


#     config_modules = {}        
#     for module, blueprint in import_backend_enabled_modules():
#         config_modules[blueprint.config['MODULE_CODE']] = blueprint.config

#     # Update config app 
#     app.config.update({**config, **config_modules})

#     # parametre de mail ??
#     # MAIL.init_app(app)
#     # DB.init_app(app)

#     return config, config_backend, config_frontend, config_modules


# def get_updated_frontend_config(app):
#     '''

#     '''
    
#     _, _, config_frontend, config_modules = get_updated_config(app)
#     return {**config_frontend, **config_modules}


# def get_whole_frontend_config(app):
#     """
#         Config à envoyer au frontend
#     """

#     for module_object in DB.session.query(TModules).filter(
#         TModules.module_code != 'GEONATURE'):

#         module, module_blueprint = import_module(module_object)

#         module_conf = {module_code: module_conf}
#         config_ = {**config_, **module_conf}

#     return config_



# def get_modules_config(app):
#     """
#         Get module config
#     """
#     from geonature.core.gn_commons.models import TModules

#     with app.app_context():

#         for module_object in DB.session.query(TModules).filter(
#             TModules.module_code != 'GEONATURE').filter(
#                 TModules.active_frontend == True).all():
#             # Import module in sys.path
#             try:
#                 mod_path = os.readlink(
#                     str(GN_EXTERNAL_MODULE / module_object.module_code.lower())
#                 )

#                 module_parent_dir = str(Path(mod_path).parent)
#                 module_schema_conf = "{}.config.conf_schema_toml".format(
#                     Path(mod_path).name
#                 )
#                 sys.path.insert(0, module_parent_dir)
#                 module = __import__(module_schema_conf, globals=globals())
#                 front_module_conf_file = os.path.join(
#                     mod_path, "config/conf_gn_module.toml"
#                 )  # noqa
#                 config_module = load_and_validate_toml(
#                     front_module_conf_file,
#                     module.config.conf_schema_toml.GnModuleSchemaConf
#                 )

#                 # Set id_module and module_code
#                 config_module["ID_MODULE"] = module_object.id_module
#                 config_module["MODULE_CODE"] = module_object.module_code
#                 config_module["MODULE_URL"] = module_object.module_path.rstrip()

#                 # Mise à jour
         
#                 module_blueprint = load_entry_point(config_module["MODULE_URL"], 'gn_module', 'blueprint')
#                 print('config_module["MODULE_URL"]', module_bluprint.config)

#                 yield module_object.module_code, config_module
#             except FileNotFoundError:
#                 log.info("Skip module {} as its not in external module directory".format(
#                     module_object.module_code
#                 ))


# ???? A déplacer ailleurs ??
def process_manage_frontend_assets():
    '''
        Ici on cherche à rendre le build du frontend 'indépendant' de la config
        Pour cela on crée directement des fichiers dans les assets du frontend, 
        dans les repertoires 'frontend/dist' et 'frontend/src'

        Les fichiers concernés:
            - pour fournir API_ENDPOINT au frontend :
                - config/api.config.json
    '''

    for mode in ['src', 'dist']:
        assets_dir = str(ROOT_DIR / "frontend/{}/assets".format(mode))
        if not os.path.exists(assets_dir):
            os.makedirs(assets_dir)

        assets_config_dir =  assets_dir + "/config"
        if not os.path.exists(assets_config_dir):
            os.makedirs(assets_config_dir)

        path = assets_config_dir + "/api.config.json"
        with open(path, "w") as outputfile:
            outputfile.write('"{}"'.format(config['API_ENDPOINT']))
