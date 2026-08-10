import click
from geonature.core.gn_permissions.models import PermObject
from sqlalchemy import text, select

from geonature.utils.env import db
from geonature.core.gn_commons.models.base import TModules
from geonature.core.gn_synthese.models import TSources

ADD_SUBMODULE_PERMISSIONS_QUERY = """
    INSERT INTO
        gn_permissions.t_permissions_available (
            id_module,
            id_object,
            id_action,
            label,
            scope_filter
        )
    SELECT
        m.id_module,
        o.id_object,
        a.id_action,
        v.label,
        v.scope_filter
    FROM
        (
            VALUES
                 (:module_code, 'ALL', 'C', True, 'Créer des relevés')
                ,(:module_code, 'INDIVIDUALS', 'C', True, 'Créer des individus')
                ,(:module_code, 'INDIVIDUALS', 'R', True, 'Voir les individus')
                ,(:module_code, 'ALL', 'R', True, 'Voir les relevés')
                ,(:module_code, 'ALL', 'U', True, 'Modifier les relevés')
                ,(:module_code, 'ALL', 'E', True, 'Exporter les relevés')
                ,(:module_code, 'ALL', 'D', True, 'Supprimer des relevés')
        ) AS v (module_code, object_code, action_code, scope_filter, label)
    JOIN
        gn_commons.t_modules m ON m.module_code = v.module_code
    JOIN
        gn_permissions.t_objects o ON o.code_object = v.object_code
    JOIN
        gn_permissions.bib_actions a ON a.code_action = v.action_code
    """


def _add_submodule_permissions(module_code):
    db.session.execute(text(ADD_SUBMODULE_PERMISSIONS_QUERY), {"module_code": module_code})


@click.command()
@click.argument("module_code", required=True)
@click.argument("module_label", required=True)
@click.option(
    "--module-picto",
    default="fa-puzzle-piece",
    show_default=True,
    help="Module pictogram (FontAwesome class)",
)
@click.option("--module-desc", default="", help="Module description")
@click.option(
    "--source-name",
    default=None,
    help="Name of the Synthese source associated with the module (defaults to a value derived from MODULE_LABEL)",
)
@click.option(
    "--source-desc",
    default=None,
    help="Description of the Synthese source associated with the module",
)
def create_duplicated_module(
    module_code,
    module_label,
    module_picto,
    module_desc,
    source_name,
    source_desc,
):
    """
    Duplicate the Occtax module to create a new module based on its engine.

    This command automates the procedure described in the administration
    documentation ("Dupliquer le module Occtax"):

    \b
    - creation of the row in gn_commons.t_modules,
    - creation of the associated source in gn_synthese.t_sources,
    - creation of the permissions available for the new module.

    You then still need to associate datasets with the module from the
    Metadata module.
    """
    module_code = module_code.upper()
    module_path = module_code.lower()

    existing_module = db.session.execute(
        select(TModules).filter_by(module_code=module_code)
    ).scalar_one_or_none()
    if existing_module is not None:
        raise click.UsageError(f"Un module avec le code '{module_code}' existe déjà.")

    module = TModules(
        module_code=module_code,
        module_label=module_label,
        module_picto=module_picto,
        module_desc=module_desc,
        module_path=module_path,
        active_frontend=True,
        active_backend=False,
        ng_module="occtax",
        support_additional_fields=True,
    )
    module.objects.append(
        db.session.execute(
            select(PermObject).where(PermObject.code_object == "INDIVIDUALS")
        ).scalar_one_or_none()
    )
    db.session.add(module)
    db.session.flush()

    source = TSources(
        name_source=source_name or f"{module_label} (sous-module Occtax)",
        desc_source=source_desc or f"Données issues du protocole {module_label}",
        entity_source_pk_field="pr_occtax.cor_counting_occtax.id_counting_occtax",
        url_source=f"#/{module_path}/info/id_counting",
        id_module=module.id_module,
    )
    db.session.add(source)

    _add_submodule_permissions(module_code)

    db.session.commit()

    click.secho(
        f"Module '{module_code}' created successfully (id_module={module.id_module}).", fg="green"
    )

    click.secho(
        "\nDon't forget to associate the relevant datasets with the new module "
        "from the Metadata module.",
        fg="yellow",
    )
