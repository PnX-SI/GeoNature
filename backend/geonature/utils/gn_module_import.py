import json
from contextlib import ExitStack

from geonature.utils.config import config
from geonature.utils.module import get_dist_from_code, get_module_config
from geonature.utils.env import ROOT_DIR


def install_frontend_dependencies(module_path):
    """
    Install module frontend dependencies in the GN node_modules directory
    """
    log.info("Installing JS dependencies...")
    frontend_module_path = Path(module_path) / "frontend"
    if (frontend_module_path / "package.json").is_file():
        try:
            subprocess.check_call(
                ["/bin/bash", "-i", "-c", "nvm use"], cwd=str(ROOT_DIR / "frontend")
            )
            try:
                subprocess.check_call(
                    ["npm", "ci"],
                    cwd=str(frontend_module_path),
                )
            except subprocess.CalledProcessError:  # probably missing package-lock.json
                subprocess.check_call(
                    ["npm", "install"],
                    cwd=str(frontend_module_path),
                )
        except Exception as ex:
            log.info("Error while installing JS dependencies")
            raise GeoNatureError(ex)
    else:
        log.info("No package.json - skip js packages installation")
    log.info("...%s\n", MSG_OK)


def create_frontend_module_config(module_code, output_file=None):
    """
    Create the frontend config
    """
    module_code = module_code.upper()
    module_config = get_module_config(get_dist_from_code(module_code))
    with ExitStack() as stack:
        if output_file is None:
            frontend_config_path = (
                ROOT_DIR
                / "frontend"
                / "external_modules"
                / module_code.lower()
                / "app"
                / "module.config.ts"
            )
            output_file = stack.enter_context(open(str(frontend_config_path), "w"))
        output_file.write("export const ModuleConfig = ")
        json.dump(module_config, output_file, indent=True, sort_keys=True)
