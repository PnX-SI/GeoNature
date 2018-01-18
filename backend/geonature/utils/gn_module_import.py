'''
    Fonctions utilisés pour l'installation et le chargement
    d'un nouveau module geonature
'''
import toml
import subprocess

from pathlib import Path
from packaging import version

from marshmallow import Schema, fields
from marshmallow.validate import OneOf, Regexp

from geonature.utils.errors import ConfigError
from geonature.utils.env import (
    GEONATURE_VERSION,
    GN_MODULE_FILES,
    GN_MODULES_ETC_AVAILABLE,
    GN_MODULES_ETC_ENABLED,
    GN_MODULES_ETC_FILES,
    import_requirements
)


class ManifestSchemaConf(Schema):
    package_format_version = fields.String(required=True)
    module_name = fields.String(required=True)
    module_version = fields.String(required=True)
    min_geonature_version = fields.String(required=True)
    max_geonature_version = fields.String(required=True)
    exclude_geonature_versions = fields.List(fields.String)


def check_gn_module_file(module_path):
    print("checking file")
    for file in GN_MODULE_FILES:
        if not (Path(module_path) / "manifest.toml").is_file():
            raise FileNotFoundError("Missing file {}".format(file))
    print("...ok")


def check_manifest(module_path):
    '''
        Verification de la version de geonature par rapport au manifest
    '''
    print("checking manifest")
    manifest_file = Path(module_path) / "manifest.toml"
    cm = toml.load(str(manifest_file))
    configs_py, configerrors = ManifestSchemaConf().load(cm)
    if configerrors:
        raise ConfigError(manifest_file, configerrors)

    gn_v = version.parse(GEONATURE_VERSION)
    if (
        gn_v < version.parse(configs_py['min_geonature_version']) and
        gn_v > version.parse(configs_py['max_geonature_version'])
    ):
        raise Exception(
            "Geonature version {} is imcompatible with module"
            .format(GEONATURE_VERSION)
        )
    for e_gn_v in configs_py['exclude_geonature_versions']:
        if gn_v == version.parse(e_gn_v):
            raise Exception(
                "Geonature version {} is imcompatible with module"
                .format(GEONATURE_VERSION)
            )
    print("...ok")
    return configs_py['module_name']


def gn_module_register_config(module_name, module_path):
    '''
        Enregistrement du module dans les variables etc
    '''
    print("Register module")
    cmd = "sudo mkdir -p {}/{}".format(GN_MODULES_ETC_AVAILABLE, module_name)
    subprocess.call(cmd.split(" "))
    for cf in GN_MODULES_ETC_FILES:
        if (Path(module_path) / cf).is_file():
            cmd = "sudo cp {}/{} {}/{}/{}".format(
                module_path,
                cf,
                GN_MODULES_ETC_AVAILABLE,
                module_name,
                cf
            )
            subprocess.call(cmd.split(" "))
    print("...ok")


def gn_module_import_requirements(module_path):
    req_p = Path(module_path) / "requirements.txt"
    if req_p.is_file():
        print("import_requirements")
        import_requirements(str(req_p))
        print("...ok")

def gn_module_activate(module_name):
    cmd = "sudo cp {}/{}* {}/{}".format(
        GN_MODULES_ETC_AVAILABLE,
        module_name,
        GN_MODULES_ETC_ENABLED,
        module_name
    )
    subprocess.call(cmd.split(" "))
