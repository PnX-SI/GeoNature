import os
from pathlib import Path
from pkg_resources import load_entry_point, get_entry_info, iter_entry_points

from alembic.script import ScriptDirectory
from alembic.migration import MigrationContext
from flask import current_app
from flask_migrate import upgrade as db_upgrade

from geonature.utils.utilstoml import load_and_validate_toml
from geonature.utils.env import db, CONFIG_FILE
from geonature.core.gn_commons.models import TModules


class NoManifestFound(Exception):
    pass


def get_module_config_path(module_code):
    config_path = os.environ.get(f"GEONATURE_{module_code}_CONFIG_FILE")
    if config_path:
        return Path(config_path)
    dist = get_dist_from_code(module_code)
    config_path = Path(dist.module_path).parent / "config" / "conf_gn_module.toml"
    if config_path.exists():
        return config_path
    config_path = Path(CONFIG_FILE).parent / f"{module_code.lower()}_config.toml"
    if config_path.exists():
        return config_path
    return None


def get_module_config(module_dist):
    module_code = load_entry_point(module_dist, "gn_module", "code")
    config_schema = load_entry_point(module_dist, "gn_module", "config_schema")
    config = {"MODULE_CODE": module_code, "MODULE_URL": f"/{module_code.lower()}"}
    config.update(load_and_validate_toml(get_module_config_path(module_code), config_schema))
    return config


def get_dist_from_code(module_code):
    for entry_point in iter_entry_points("gn_module", "code"):
        if module_code == entry_point.load():
            return entry_point.dist
    raise Exception(f"Module with code {module_code} not installed in venv")


def iterate_revisions(script, base_revision):
    """
    Iterate revisions without following depends_on directive.
    Useful to find all revisions of a given branch.
    """
    yelded = set()
    todo = {base_revision}
    while todo:
        rev = todo.pop()
        yield rev
        yelded.add(rev)
        rev = script.get_revision(rev)
        todo |= rev.nextrev - yelded


def alembic_branch_in_use(branch_name, directory, x_arg):
    """
    Return true if at least one revision of the given branch is applied.
    """
    db = current_app.extensions["sqlalchemy"].db
    migrate = current_app.extensions["migrate"].migrate
    config = migrate.get_config(directory, x_arg)
    script = ScriptDirectory.from_config(config)
    base_revision = script.get_revision(script.as_revision_number(branch_name))
    branch_revisions = set(iterate_revisions(script, base_revision.revision))
    migration_context = MigrationContext.configure(db.session.connection())
    current_heads = migration_context.get_current_heads()
    # get_current_heads does not return implicit revision through dependencies, get_all_current does
    current_heads = set(map(lambda rev: rev.revision, script.get_all_current(current_heads)))
    return not branch_revisions.isdisjoint(current_heads)


def module_db_upgrade(module_dist, directory=None, sql=False, tag=None, x_arg=[]):
    module_code = module_dist.load_entry_point("gn_module", "code")
    if "migrations" in module_dist.get_entry_map("gn_module"):
        try:
            alembic_branch = module_dist.load_entry_point("gn_module", "alembic_branch")
        except ImportError:
            alembic_branch = module_code.lower()
    else:
        alembic_branch = None
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
    elif alembic_branch and not alembic_branch_in_use(alembic_branch, directory, x_arg):
        """
        The module branch is not known to be applied by Alembic,
        but the module is present in gn_commons.t_modules table.
        Refusing to upgrade the Alembic branch.
        Upgrading of old module requiring manual stamp?
        """
        return False
    if alembic_branch:
        revision = alembic_branch + "@head"
        db_upgrade(directory, revision, sql, tag, x_arg)
    return True
