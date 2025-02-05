"""
Entry point for the command line 'geonature'
"""

import logging
from os import environ
from collections import ChainMap

import toml
import click
from flask.cli import run_command
from sqlalchemy import select, delete, exists
from sqlalchemy.sql.selectable import CTE

from geonature.core.gn_meta.models import TAcquisitionFramework, TDatasets
from geonature.core.gn_meta.mtd import MTDInstanceApi
from geonature.utils.env import GEONATURE_VERSION, db
from geonature.utils.module import iter_modules_dist
from geonature import create_app
from geonature.utils.config import config
from geonature.utils.config_schema import GnGeneralSchemaConf, GnPySchemaConf
from geonature.utils.command import (
    create_frontend_module_config,
    build_frontend,
)

from flask.cli import FlaskGroup

log = logging.getLogger()


def normalize(name):
    return name.replace("_", "-")


@click.group(
    cls=FlaskGroup,
    create_app=create_app,
    context_settings={"token_normalize_func": normalize},
)
@click.version_option(version=GEONATURE_VERSION)
@click.pass_context
def main(ctx):
    pass


@main.command()
@click.option("--host", default="0.0.0.0")
@click.option("--port", default=8000)
@click.pass_context
def dev_back(ctx, host, port):
    """
    Lance l'api du backend avec flask

    Exemples

    - geonature dev_back

    - geonature dev_back --port=8080 --port=0.0.0.0
    """
    if not environ.get("FLASK_DEBUG"):
        environ["FLASK_DEBUG"] = "true"
    ctx.invoke(run_command, host=host, port=port)


@main.command()
@click.argument("module_code")
@click.option(
    "--output",
    "output_file",
    type=click.File("w"),
)
def generate_frontend_module_config(module_code, output_file):
    """
    Génère la config frontend d'un module

    Example:

    - geonature generate-frontend-module-config OCCTAX

    """
    create_frontend_module_config(module_code, output_file)
    click.echo(
        "Configuration générée. Pensez à rebuilder le frontend pour la production.", err=True
    )


@main.command()
@click.option("--modules", type=bool, required=False, default=True)
@click.option("--build", type=bool, required=False, default=True)
def update_configuration(modules, build):
    """
    Régénère la configuration du front et lance le rebuild.
    """
    click.echo("Génération de la configuration du frontend :")
    click.echo("  GeoNature … ", nl=False)
    click.secho("OK", fg="green")
    if modules:
        for dist in iter_modules_dist():
            module_code = dist.entry_points["code"].load()
            click.echo(f"  Module {module_code} … ", nl=False)
            if module_code in config["DISABLED_MODULES"]:
                click.secho("désactivé, ignoré", fg="white")
                continue
            create_frontend_module_config(module_code)
            click.secho("OK", fg="green")
    if build:
        click.echo("Rebuild du frontend …")
        build_frontend()
        click.secho("Rebuild du frontend terminé.", fg="green")


@main.command()
def default_config():
    """
    Afficher l’ensemble des paramètres et leur valeur par défaut.
    """
    required_fields = (
        "URL_APPLICATION",
        "API_ENDPOINT",
        "API_TAXHUB",
        "SECRET_KEY",
        "SQLALCHEMY_DATABASE_URI",
    )
    backend_defaults = GnPySchemaConf().load({}, partial=required_fields)
    frontend_defaults = GnGeneralSchemaConf().load({}, partial=required_fields)
    defaults = ChainMap(backend_defaults, frontend_defaults)
    print(toml.dumps(defaults))


@click.argument("key", type=str, required=False)
@main.command()
def get_config(key=None):
    """
    Afficher l’ensemble des paramètres
    """
    printed_config = config.copy()
    if key:
        try:
            printed_config = printed_config[key]
        except KeyError:
            click.secho(f"The key {key} does not exist in config", fg="red")
            return
    if type(printed_config) is dict:
        print(toml.dumps(printed_config))
    else:
        print(printed_config)


@main.command()
@click.option("--delete-incorrect-data", is_flag=True, required=False, default=False)
def check_acquisition_framework_metadata(delete_incorrect_data):
    """
    Only for instance using only INPN Metadonnée. We check which AF are valid or not. You can delete most of the invalid
    with --delete-incorrect-data.
    """

    def get_cte_acquisition_frameworks(ids: [int], in_ids: bool):
        """
        Return a list of acquisition frameworks

        If in_ids is True, return only acquisition frameworks in ids
        if in_ids is False, return only acquisition frameworks not in ids
        """
        if not in_ids:
            return (
                select(TAcquisitionFramework).where(
                    TAcquisitionFramework.unique_acquisition_framework_id.not_in(ids)
                )
            ).cte()
        else:
            return (
                select(TAcquisitionFramework.unique_acquisition_framework_id).where(
                    TAcquisitionFramework.unique_acquisition_framework_id.in_(ids)
                )
            ).cte()

    mtd_instance = MTDInstanceApi(config["MTD_API_ENDPOINT"], config["MTD"]["ID_INSTANCE_FILTER"])
    acquisition_frameworks_id = [
        af["unique_acquisition_framework_id"] for af in mtd_instance.get_af_list()
    ]

    cte_invalid_acquisition_frameworks = get_cte_acquisition_frameworks(
        acquisition_frameworks_id, in_ids=False
    )
    cte_valid_acquisition_frameworks = get_cte_acquisition_frameworks(
        acquisition_frameworks_id, in_ids=True
    )

    valid_acquisition_frameworks = (
        db.session.execute(select(cte_valid_acquisition_frameworks)).unique().all()
    )
    invalid_acquisition_frameworks = (
        db.session.execute(select(cte_invalid_acquisition_frameworks)).unique().all()
    )

    click.secho(
        f"You have {len(valid_acquisition_frameworks)} valid acquisition frameworks and "
        f"{len(invalid_acquisition_frameworks)} invalid acquisition frameworks.",
        fg="yellow",
        bold=True,
    )

    def get_subset_acquisition_frameworks_query(
        acquisition_framework_cte: CTE, linked_to_dataset: bool
    ):
        """
        If lined_to_dataset is True, return all af that have at least one dataset linked. Else, return the one
        which have none.
        """
        if linked_to_dataset:
            return select(acquisition_framework_cte).where(
                exists().where(
                    TDatasets.id_acquisition_framework
                    == acquisition_framework_cte.c.id_acquisition_framework
                )
            )
        else:
            return select(acquisition_framework_cte).where(
                ~exists().where(
                    TDatasets.id_acquisition_framework
                    == acquisition_framework_cte.c.id_acquisition_framework
                )
            )

    invalid_acquisition_frameworks_with_dataset_query = get_subset_acquisition_frameworks_query(
        cte_invalid_acquisition_frameworks, linked_to_dataset=True
    )
    invalid_acquisition_frameworks_with_dataset = (
        db.session.execute(invalid_acquisition_frameworks_with_dataset_query).scalars().all()
    )
    invalid_acquisition_frameworks_without_dataset_query = get_subset_acquisition_frameworks_query(
        cte_invalid_acquisition_frameworks, linked_to_dataset=False
    )
    invalid_acquisition_frameworks_without_dataset = (
        db.session.execute(invalid_acquisition_frameworks_without_dataset_query).scalars().all()
    )

    click.echo(
        f"Following {len(invalid_acquisition_frameworks_without_dataset)} acquisition frameworks are invalid "
        f"and can be deleted: {invalid_acquisition_frameworks_without_dataset}"
    )

    click.secho(
        f"Following {len(invalid_acquisition_frameworks_with_dataset)} acquisition frameworks are invalid "
        f"but can't be deleted because they are linked with dataset : {invalid_acquisition_frameworks_with_dataset} ",
        fg="red",
        bold=True,
    )

    if delete_incorrect_data:
        question = click.style(
            f"⚠  Confirm deletion of {len(invalid_acquisition_frameworks_without_dataset)} entries  ⚠",
            fg="red",
            bold=True,
        )
        if click.confirm(question):
            delete_query = delete(TAcquisitionFramework).where(
                TAcquisitionFramework.id_acquisition_framework.in_(
                    invalid_acquisition_frameworks_without_dataset
                )
            )
            db.session.execute(delete_query)
            db.session.commit()
            click.echo(f"Deleted {len(invalid_acquisition_frameworks_without_dataset)} entries")
        else:
            click.echo("No deletion performed")
