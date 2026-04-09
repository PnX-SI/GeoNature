import pathlib
from contextlib import ExitStack, nullcontext
from io import TextIOWrapper
from zipfile import ZipFile

import click
from flask import Blueprint, current_app
from geonature.utils.env import db
from sqlalchemy import func, select
from sqlalchemy.orm import aliased
from sqlalchemy.schema import Table
from utils_flask_sqla.utils import remote_file

from geonature.core.sensitivity.models import SensitivityRule
from apptax.taxonomie.models import Taxref, TaxrefTree
from geonature.core.sensitivity.utils import (
    insert_sensitivity_referential,
    remove_sensitivity_referential,
)

routes = Blueprint("sensitivity", __name__)


@routes.cli.command()
def info():
    """
    Affiche différentes statistiques sur les règles de sensibilitées
    """
    SensitivityRuleCache = Table(
        "t_sensitivity_rules_cd_ref",
        db.metadata,
        schema="gn_sensitivity",
        autoload_with=db.session.connection(),
    )
    total_count = db.session.scalar(select(func.count("*")).select_from(SensitivityRule))

    click.echo(f"Nombre total de règles de sensibilité : {total_count}")
    click.echo(
        "Nombre de règles actives : {}".format(
            db.session.scalar(
                select(func.count("*")).select_from(SensitivityRule).filter_by(active=True)
            )
        )
    )
    click.echo(
        "Nombre de taxons concernés par les règles actives : {}".format(
            db.session.scalar(select(func.count(func.distinct(SensitivityRuleCache.c.cd_ref))))
        )
    )

    if total_count:
        click.echo("Nombre de règles de sensibilité par source (actives / total):")
        q = (
            select(
                SensitivityRule.source,
                func.count(SensitivityRule.id).label("active_count"),
                func.count(SensitivityRule.id).label("total_count"),
            )
            .where(SensitivityRule.active == True)
            .group_by(SensitivityRule.source)
            .order_by(SensitivityRule.source)
        )
        for source, active_count, total_count in db.session.execute(q).all():
            click.echo(f"\t{source} : {active_count} / {total_count}")


@routes.cli.command()
@click.option("--source-name", required=True)
@click.option("--csvfile", required=True)
@click.option("--url", help="Le fichier ou l’archive est à télécharger")
@click.option("--zipfile", help="Le fichier CSV est contenu dans une archive")
@click.option("--encoding")
def add_referential(source_name, csvfile, url, zipfile, encoding):
    """
    Ajoute les règles pour une source données
    """
    filepath = zipfile or csvfile
    with ExitStack() as stack:
        if url:
            filepath = stack.enter_context(remote_file(url, filepath))
        else:
            filepath = pathlib.Path(filepath)
        if zipfile:
            archive = stack.enter_context(ZipFile(filepath))
            csvfile = stack.enter_context(
                TextIOWrapper(archive.open(csvfile, "r"), encoding=encoding)
            )
        else:
            csvfile = stack.enter_context(filepath.open("r", encoding=encoding))
        click.echo(f"Ajout de règles de sensibilité '{source_name}'")
        count = insert_sensitivity_referential(source_name, csvfile)
    db.session.commit()
    click.echo(f"{count} règles ajoutées")


@routes.cli.command()
@click.argument("source")
def remove_referential(source):
    """
    Supprime les règles d’une source données
    """
    click.echo(f"Suppression des règles de sensibilité '{source}'")
    count = remove_sensitivity_referential(source)
    db.session.commit()
    click.echo(f"{count} règles supprimées")


@routes.cli.command()
def refresh_rules_cache():
    """
    Rafraichie la vue matérialisée extrapolant les règles aux taxons enfants.
    """
    db.session.execute("REFRESH MATERIALIZED VIEW gn_sensitivity.t_sensitivity_rules_cd_ref")
    db.session.commit()


@routes.cli.command()
def update_synthese():
    """
    Recalcule la sensibilité des observations de la synthèse.
    """
    count = db.session.execute("SELECT gn_synthese.update_sensitivity()").scalar()
    db.session.commit()
    click.echo(f"Sensitivity updated for {count} rows")
