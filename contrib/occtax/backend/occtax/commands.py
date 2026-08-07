import click
from sqlalchemy import select

from geonature.utils.env import db
from geonature.utils.config_schema import AdditionalFields
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
    db.session.execute(ADD_SUBMODULE_PERMISSIONS_QUERY, {"module_code": module_code})


@click.command()
@click.argument("module_code", required=True)
def add_submodule_permissions(module_code):
    _add_submodule_permissions(module_code)
    db.session.commit()
    click.secho("DONE", fg="green")


@click.command()
@click.argument("module_code", required=True)
@click.argument("module_label", required=True)
@click.argument("module_path", required=True)
@click.option(
    "--module-picto",
    default="fa-paw",
    show_default=True,
    help="Pictogramme (classe FontAwesome) du module",
)
@click.option("--module-desc", default="", help="Description du module")
@click.option(
    "--source-name",
    default=None,
    help="Nom de la source Synthèse associée au module (par défaut dérivé de MODULE_LABEL)",
)
@click.option(
    "--source-desc",
    default=None,
    help="Description de la source Synthèse associée au module",
)
def create_duplicated_module(
    module_code,
    module_label,
    module_path,
    module_picto,
    module_desc,
    source_name,
    source_desc,
):
    """
    Duplique le module Occtax pour créer un nouveau module basé sur son moteur.

    Cette commande automatise la procédure décrite dans la documentation
    d'administration ("Dupliquer le module Occtax") :

    \b
    - création de la ligne dans gn_commons.t_modules,
    - création de la source associée dans gn_synthese.t_sources,
    - création des permissions disponibles pour le nouveau module.

    Il reste ensuite à associer des jeux de données au module depuis le
    module Métadonnées, et à ajouter le code du module dans la clé
    ADDITIONAL_FIELDS.IMPLEMENTED_MODULES du fichier de configuration
    (une suggestion est affichée en fin de commande).
    """
    module_code = module_code.upper()

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

    click.secho(f"Module '{module_code}' créé avec succès (id_module={module.id_module}).", fg="green")

    implemented_modules = [
        *AdditionalFields().load({})["IMPLEMENTED_MODULES"],
        module_code,
    ]
    click.secho(
        "\nPensez à :\n"
        "- associer les jeux de données concernés au nouveau module depuis le module Métadonnées ;\n"
        "- ajouter le code du module dans la configuration de GeoNature (geonature_config.toml) :\n",
        fg="yellow",
    )
    modules_toml_list = ", ".join(f'"{code}"' for code in implemented_modules)
    click.echo("[ADDITIONAL_FIELDS]")
    click.echo(f"  IMPLEMENTED_MODULES = [{modules_toml_list}]")
