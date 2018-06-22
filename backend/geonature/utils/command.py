import sys
import logging
import subprocess
import json

from jinja2 import Template
from pathlib import Path

from server import get_app
from geonature.utils.env import (
    BACKEND_DIR,
    ROOT_DIR,
    GN_MODULE_FE_FILE,
    load_config,
    DB,
    GN_EXTERNAL_MODULE
)
from geonature.utils.errors import ConfigError
from geonature.utils.utilstoml import load_and_validate_toml
from geonature.utils.config_schema import GnGeneralSchemaConf 

log = logging.getLogger(__name__)

def start_gunicorn_cmd(uri, worker):
    cmd = 'gunicorn server:app -w {gun_worker} -b {gun_uri}'
    subprocess.call(
        cmd.format(gun_worker=worker, gun_uri=uri).split(" "),
        cwd=str(BACKEND_DIR)
    )


def get_app_for_cmd(config_file=None, with_external_mods=True):
    """ Return the flask app object, logging error instead of raising them"""
    try:
        conf = load_config(config_file)
        return get_app(conf, with_external_mods=with_external_mods)
    except ConfigError as e:
        log.critical(str(e) + "\n")
        sys.exit(1)


def supervisor_cmd(action, app_name):
    cmd = 'sudo supervisorctl {action} {app}'
    subprocess.call(cmd.format(action=action, app=app_name).split(" "))


def start_geonature_front():
    subprocess.call(['npm', 'run', 'start'], cwd=str(ROOT_DIR / 'frontend'))


def build_geonature_front(rebuild_sass=False):
    if rebuild_sass:
        subprocess.call(['npm', 'rebuild', 'node-sass', '--force'], cwd=str(ROOT_DIR / 'frontend'))
    subprocess.call(['npm', 'run', 'build'], cwd=str(ROOT_DIR / 'frontend'))


def frontend_routes_templating():
    from geonature.utils.env import list_frontend_enabled_modules
    from geonature.core.gn_commons.models import TModules
    with open(
        str(ROOT_DIR / 'frontend/src/app/routing/app-routing.module.ts.sample'),
        'r'
    ) as input_file:
        template = Template(input_file.read())
        routes = []
        for conf, manifest in list_frontend_enabled_modules():
            location = Path(GN_EXTERNAL_MODULE / manifest['module_name'])
            # test if module have frontend
            if (location / 'frontend').is_dir():   
                path = conf['api_url'].lstrip('/')
                location = '{}/{}#GeonatureModule'.format(
                    location.resolve(), GN_MODULE_FE_FILE
                )
                routes.append(
                    {'path': path, 'location': location, 'id_module': conf['id_application']}
                )

            # TODO test if two modules with the same name is okay for Angular

        route_template = template.render(routes=routes)

        with open(
            str(ROOT_DIR / 'frontend/src/app/routing/app-routing.module.ts'), 'w'
        ) as output_file:
            output_file.write(route_template)

def tsconfig_templating():
    with open(
        str(ROOT_DIR / 'frontend/tsconfig.json.sample'), 'r'
    ) as input_file:
        template = Template(input_file.read())
        tsconfig_templated = template.render(geonature_path=ROOT_DIR)

    with open(
        str(ROOT_DIR / 'frontend/tsconfig.json'), 'w'
    ) as output_file:
        output_file.write(tsconfig_templated)


def create_frontend_config(conf_file):
    configs_gn = load_and_validate_toml(conf_file, GnGeneralSchemaConf)

    with open(
        str(ROOT_DIR / 'frontend/src/conf/app.config.ts'), 'w'
    ) as outputfile:
        outputfile.write("export const AppConfig = ")
        json.dump(configs_gn, outputfile, indent=True)


def update_app_configuration(conf_file, build=True):
    subprocess.call(['sudo', 'supervisorctl', 'reload'])
    create_frontend_config(conf_file)
    if build:
        subprocess.call(['npm', 'run', 'build'], cwd=str(ROOT_DIR / 'frontend'))
