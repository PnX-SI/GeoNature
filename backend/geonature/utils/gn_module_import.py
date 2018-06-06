'''
    Fonctions utilisés pour l'installation et le chargement
    d'un nouveau module geonature
'''
import inspect
import subprocess
import logging
import os
import json
import sys


from pathlib import Path
from packaging import version
from sqlalchemy.orm.exc import NoResultFound

from geonature.utils.config_schema import ManifestSchemaProdConf
from geonature.utils import utilstoml
from geonature.utils.errors import GeoNatureError
from geonature.utils.command import (
    get_app_for_cmd,
    build_geonature_front
)


from geonature.utils.env import (
    GEONATURE_VERSION,
    GN_MODULE_FILES,
    GN_MODULES_ETC_AVAILABLE,
    GN_MODULES_ETC_ENABLED,
    GN_MODULES_ETC_FILES,
    GN_MODULE_FE_FILE,
    ROOT_DIR,
    DB,
    DEFAULT_CONFIG_FIlE,
    load_config,
    import_requirements,
    frontend_routes_templating
)
from geonature.utils.config_schema import (
    ManifestSchemaConf
)
from geonature.utils.utilstoml import load_and_validate_toml
from geonature.core.users.models import TApplications
from geonature.core.gn_commons.models import TModules

log = logging.getLogger(__name__)


def check_gn_module_file(module_path):
    log.info("checking file")
    for file in GN_MODULE_FILES:
        if not (Path(module_path) / file).is_file():
            raise GeoNatureError("Missing file {}".format(file))
    log.info("...ok\n")


def check_manifest(module_path):
    '''
        Verification de la version de geonature par rapport au manifest
    '''
    log.info("checking manifest")
    configs_py = load_and_validate_toml(
        str(Path(module_path) / "manifest.toml"),
        ManifestSchemaConf
    )

    gn_v = version.parse(GEONATURE_VERSION)
    if (
            gn_v < version.parse(configs_py['min_geonature_version']) and
            gn_v > version.parse(configs_py['max_geonature_version'])
    ):
        raise GeoNatureError(
            "Geonature version {} is imcompatible with module"
            .format(GEONATURE_VERSION)
        )
    for e_gn_v in configs_py['exclude_geonature_versions']:
        if gn_v == version.parse(e_gn_v):
            raise GeoNatureError(
                "Geonature version {} is imcompatible with module"
                .format(GEONATURE_VERSION)
            )
    log.info("...ok\n")
    return configs_py['module_name']


def gn_module_register_config(module_name, module_path, url, id_app):
    '''
        Enregistrement du module dans les variables etc
    '''
    log.info("Register module")

    # TODO utiliser les commande os de python
    cmd = "sudo mkdir -p {}/{}".format(GN_MODULES_ETC_AVAILABLE, module_name)
    subprocess.call(cmd.split(" "))
    for m_conf_file in GN_MODULES_ETC_FILES:
        if (Path(module_path) / m_conf_file).is_file():
            cmd = "sudo cp {}/{} {}/{}/{}".format(
                module_path,
                m_conf_file,
                GN_MODULES_ETC_AVAILABLE,
                module_name,
                m_conf_file
            )
            subprocess.call(cmd.split(" "))

    cmds = [
        {
            'cmd': 'sudo tee -a {}/{}/manifest.toml'.format(
                GN_MODULES_ETC_AVAILABLE,
                module_name),
            'msg': "module_path = '{}'\n".format(Path(module_path).resolve()).encode('utf8')
        },
        {
            'cmd': 'sudo tee -a {}/{}/conf_gn_module.toml'.format(GN_MODULES_ETC_AVAILABLE, module_name),
            'msg': "api_url = '/{}'\n".format(url.lstrip('/')).encode('utf8')
        },
        {
            'cmd': 'sudo tee -a {}/{}/conf_gn_module.toml'.format(GN_MODULES_ETC_AVAILABLE, module_name),
            'msg': "id_application = {}\n".format(id_app).encode('utf-8')
        }
    ]
    for cmd in cmds:
        proc = subprocess.Popen(
            cmd['cmd'].split(" "),
            stdin=subprocess.PIPE,
            stdout=subprocess.DEVNULL
        )
        proc.stdin.write(cmd['msg'])
        proc.stdin.close()
        proc.wait()

    log.info("...ok\n")


def gn_module_import_requirements(module_path):
    req_p = Path(module_path) / "requirements.txt"
    if req_p.is_file():
        log.info("import_requirements")
        import_requirements(str(req_p))
        log.info("...ok\n")


def gn_module_activate(module_name):
    # TODO utiliser les commande os de python
    log.info("Activate module")

    # TODO gestion des erreurs
    if (GN_MODULES_ETC_AVAILABLE / module_name).is_dir():
        if not (GN_MODULES_ETC_ENABLED / module_name).is_symlink():
            cmd = "sudo ln -s {}/{} {}".format(
                GN_MODULES_ETC_AVAILABLE,
                module_name,
                GN_MODULES_ETC_ENABLED
            )
            subprocess.call(cmd.split(" "))
            log.info("...ok\n")
    else:
        raise GeoNatureError(
            "Module {} is not installed"
            .format(module_name)
        )

    log.info("Generate frontend routes")
    try:
        frontend_routes_templating()
        log.info("...ok\n")
    except Exception:
        raise

def gn_module_deactivate(module_name):
    log.info('Desactivate module')
    try:
        app = get_app_for_cmd(DEFAULT_CONFIG_FIlE)
        with app.app_context():
            module = DB.session.query(TModules).filter(TModules.module_name == module_name).one()
            module.active = False
            DB.session.merge(module)
            DB.session.commit()
    except NoResultFound:
        raise GeoNatureError(
            'The module does not exist. \n Check the gn_commons.t_module to get the module name'
        )
    if (GN_MODULES_ETC_ENABLED / module_name).is_symlink():
        cmd = "sudo rm {}/{}".format(
            GN_MODULES_ETC_ENABLED,
            module_name
        )
        subprocess.call(cmd.split(" "))
        log.info("...ok\n")
    else:
        raise GeoNatureError(
            "Module {} is not enabled"
            .format(module_name)
        )
    log.info("Regenerate frontend routes")
    try:
        frontend_routes_templating()
        # set the module as inactive
        
        log.info("...ok\n")
    except Exception:
        raise



def check_codefile_validity(module_path, module_name):
    '''
        Vérification que les fichiers nécessaires
            au bon fonctionnement du module soient bien présents
            et avec la bonne signature
    '''
    log.info('Checking file conformity')
    # Installation
    gn_file = Path(module_path) / "install_gn_module.py"
    if gn_file.is_file():
        try:
            from install_gn_module import gnmodule_install_app as fonc
            if not inspect.getargspec(fonc).args == ['gn_db', 'gn_app']:
                raise GeoNatureError('Invalid variable')
            log.info('      install_gn_module  OK')
        except (ImportError, GeoNatureError):
            raise GeoNatureError(
                """Module {}
                    File {} must have a function call :
                        gnmodule_install_app
                        with 2 parameters :
                        gn_db  :  database
                        gn_app :  application reference
                """.format(module_name, gn_file)
            )
    # Backend
    gn_file = Path(module_path) / "backend/blueprint.py"
    if gn_file.is_file():
        try:
            from backend.blueprint import blueprint
        except (ImportError, GeoNatureError):
            raise GeoNatureError(
                """Module {}
                    File {} must have a variable call :
                        blueprint instance of Blueprint
                """.format(module_name, gn_file)
            )
        from flask import Blueprint
        if isinstance(blueprint, Blueprint) is False:
            raise GeoNatureError(
                """Module {}
                        File {} :
                            blueprint is not an instance of Blueprint
                """.format(module_name, gn_file)
            )
        log.info('      backend/blueprint/blueprint.py  OK')
    # Font-end
    gn_file = Path(module_path) / "{}.ts".format(GN_MODULE_FE_FILE)
    if gn_file.is_file():
        if 'export class GeonatureModule' in open(str(gn_file)).read():
            log.info('      {}  OK'.format(GN_MODULE_FE_FILE))
        else:
            raise GeoNatureError(
                """Module {} ,
                    File {} must have a function call :
                        export class GeonatureModule
                """.format(module_name, gn_file)
            )

    log.info('...ok\n')


def create_external_assets_symlink(module_path, module_name):
    """
        Create a symlink for the module assets
    """
    module_assets_dir = os.path.join(module_path, "frontend/assets")
    
    # test if module have frontend
    if not Path(module_assets_dir).is_dir():
        log.info('no frontend for this module \n')
        return
    
    geonature_asset_symlink = os.path.join(
        str(ROOT_DIR),
        'frontend/src/external_assets',
        module_name
    )
    # create the symlink if not exist
    try:
        if not os.path.isdir(geonature_asset_symlink):
            log.info('Create a symlink for assets \n')
            subprocess.call(
                ['ln', '-s', module_assets_dir, module_name],
                cwd=str(ROOT_DIR / 'frontend/src/external_assets')
            )
        else:
            log.info('symlink already exist \n')

        log.info('...ok \n')
    except Exception as e:
        log.info('...error when create symlink externalassets \n')
        raise GeoNatureError(e)

def add_application_db(module_name, url):
    log.info('Register the module in t_application ... \n')
    app_conf = load_config(DEFAULT_CONFIG_FIlE)
    id_application_geonature = app_conf['ID_APPLICATION_GEONATURE']
    app = get_app_for_cmd(DEFAULT_CONFIG_FIlE)
    try:
        with app.app_context():
            # check if the module in TApplications
            try:
                id_app = None
                exist_app = DB.session.query(TApplications).filter(
                    TApplications.nom_application == module_name
                ).one()
            except NoResultFound:
                # if no result, write in TApplication
                new_application = TApplications(
                    nom_application=module_name,
                    id_parent=id_application_geonature
                )
                DB.session.add(new_application)
                DB.session.commit()
                DB.session.flush()
                id_app = new_application.id_application
            else:
                log.info('the module is already in t_application')
            finally:
                id_app = id_app if id_app is not None else exist_app.id_application
            try:
                module = DB.session.query(TModules).filter(
                    TModules.module_name == module_name
                ).one()
            except NoResultFound:
                update_url = "{}/#/{}".format(app_conf['URL_APPLICATION'], url)
                new_module = TModules(
                    id_module=id_app,
                    module_name=module_name,
                    module_label=module_name.title(),
                    module_url=update_url,
                    module_target="_self",
                    module_picto="extension",
                    active=True
                )
                DB.session.add(new_module)
                DB.session.commit()
            else:
                log.info('the module is already in t_module, reactivate it')
                module.active = True
                DB.session.merge(module)
                DB.session.commit()

    except Exception as e:
        raise GeoNatureError(e)

    log.info('... ok \n')
    return id_app

def create_module_config(module_name, mod_path=GN_MODULES_ETC_ENABLED, build=True):
    """ Create the frontend config for a module and rebuild if build=True"""
    conf_manifest = load_and_validate_toml(
            str(mod_path / module_name / 'manifest.toml'),
            ManifestSchemaProdConf
        )

    # import du module dans le sys.path
    module_path = Path(conf_manifest['module_path'])
    module_parent_dir = str(module_path.parent)
    module_config_path = "{}.conf_schema_toml".format(module_path.name)
    sys.path.insert(0, module_parent_dir)
    module = __import__(module_config_path, globals=globals())
    front_module_conf_file = mod_path / module_name / 'conf_gn_module.toml'
    config_module = utilstoml.load_and_validate_toml(front_module_conf_file, module.conf_schema_toml.GnModuleSchemaConf)

    frontend_config_path = conf_manifest['module_path']+'/frontend/app/module.config.ts'
    with open(
        str(ROOT_DIR / frontend_config_path), 'w'
    ) as outputfile:
        outputfile.write("export const ModuleConfig = ")
        json.dump(config_module, outputfile, indent=True, sort_keys=True)
    
    if build:
        build_geonature_front()

