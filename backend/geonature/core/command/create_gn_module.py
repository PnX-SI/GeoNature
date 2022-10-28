import logging
from pkg_resources import iter_entry_points

import click
from flask_migrate import upgrade as db_upgrade

from geonature.utils.env import db

from geonature.core.command.main import main
from geonature.core.gn_commons.models import TModules
from geonature.utils.config import config
from geonature.utils.gn_module_import import (
    gn_module_activate,
    gn_module_deactivate,
    create_module_config,
)


log = logging.getLogger(__name__)


@main.command()
@click.argument("module_codes", metavar="[MODULE_CODE]...", nargs=-1)
def upgrade_modules(module_codes):
    for module_code_entry in iter_entry_points("gn_module", "code"):
        module_code = module_code_entry.resolve()
        if module_codes and module_code not in module_codes:
            continue
        if module_code in config["DISABLED_MODULES"]:
            click.echo(f"Skip disabled module {module_code}…")
            continue
        module_dist = module_code_entry.dist

        module = TModules.query.filter_by(module_code=module_code).one_or_none()
        if module is None:
            # add module to database
            try:
                module_picto = module_dist.load_entry_point("gn_module", "picto")
            except ImportError:
                module_picto = "fa-puzzle-piece"
            try:
                module_type = module_dist.load_entry_point("gn_module", "type")
            except ImportError:
                module_type = None
            module = TModules(
                type=module_type,
                module_code=module_code,
                module_label=module_code.capitalize(),
                module_path=module_code.lower(),
                module_target="_self",
                module_picto=module_picto,
                active_frontend=True,
                active_backend=True,
                ng_module=module_code.lower(),
            )
            db.session.add(module)
            db.session.commit()
            click.echo(f"Module {module_code} added to database")

        if "migrations" in module_dist.get_entry_map("gn_module"):
            try:
                alembic_branch = module_dist.load_entry_point("gn_module", "alembic_branch")
            except ImportError:
                alembic_branch = module_code.lower()
            db_upgrade(revision=alembic_branch + "@head")
            click.echo(f"Alembic branch '{alembic_branch}' of module {module_code} upgraded")


@click.option("--frontend", type=bool, required=False, default=True)
@click.option("--backend", type=bool, required=False, default=True)
@main.command()
@click.argument("module_code")
def activate_gn_module(module_code, frontend, backend):
    """
    Active un module gn installé

    Exemples:
    # Active que le backend du module occtax
    - geonature activate_gn_module occtax --frontend=false
    # Active que le frontend du module occtax)
    - geonature activate_gn_module occtax --backend=false

    """
    # TODO vérifier que l'utilisateur est root ou du groupe geonature
    gn_module_activate(module_code.upper(), frontend, backend)


@click.option("--frontend", type=bool, required=False, default=True)
@click.option("--backend", type=bool, required=False, default=True)
@main.command()
@click.argument("module_code")
def deactivate_gn_module(module_code, frontend, backend):
    """
    Desactive un module gn activé


    Exemples:
    # Désactive que le backend du module occtax
    - geonature deactivate_gn_module occtax --frontend=false
    # Désactive que le frontend du module occtax
    - geonature deactivate_gn_module occtax --backend=false (

    """
    # TODO vérifier que l'utilisateur est root ou du groupe geonature
    gn_module_deactivate(module_code.upper(), frontend, backend)


@main.command()
@click.argument("module_code")
@click.option(
    "--output",
    "output_file",
    type=click.File("w"),
)
def update_module_configuration(module_code, output_file):
    """
    Génère la config frontend d'un module

    Example:

    - geonature update-module-configuration OCCTAX

    """
    create_module_config(module_code, output_file)
    log.info("Pensez à rebuilder le frontend")
