import pathlib
from io import TextIOWrapper
from contextlib import ExitStack, nullcontext
from zipfile import ZipFile

import click
from flask import Blueprint, current_app
from sqlalchemy import func, select
from sqlalchemy.schema import Table

from geonature.utils.env import db

from utils_flask_sqla.utils import remote_file

from .models import SensitivityRule
from .utils import remove_sensitivity_referential, insert_sensitivity_referential


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

    click.echo("Nombre de règle de sensibilité :")
    click.echo("\tTotal : {}".format(total_count))
    click.echo(
        "\tRègles actives : {}".format(
            db.session.scalar(
                select(func.count("*")).select_from(SensitivityRule).filter_by(active=True)
            )
        )
    )
    click.echo(
        "\tRègles actives extrapolées aux taxons enfants : {}".format(
            db.session.scalar(select(func.count(SensitivityRuleCache.c.id_sensitivity)))
        )
    )

    if total_count:
        click.echo("Nombre de règles de sensibilité par source (actives / total):")
        q = (
            select(
                SensitivityRule.source,
                func.count(SensitivityRule.id)
                .where(SensitivityRule.active == True)
                .label("active_count"),
                func.count(SensitivityRule.id).label("total_count"),
            )
            .group_by(SensitivityRule.source)
            .order_by(SensitivityRule.source)
        )
        for source, active_count, total_count in db.session.execute(q).all():
            click.echo(f"\t{source} : {active_count} / {total_count}")

    click.echo(f"Nombre de taxons :")
    click.echo(
        "\tTotal : {}".format(
            db.session.scalar(
                select(func.count("*"))
                .select_from(SensitivityRule)
                .distinct(SensitivityRule.cd_nom)
            )
        )
    )
    click.echo(
        "\tRègles actives : {}".format(
            db.session.scalar(
                select(func.count("*"))
                .select_from(SensitivityRule)
                .filter_by(active=True)
                .distinct(SensitivityRule.cd_nom)
            )
        )
    )
    click.echo(
        "\tRègles actives extrapolées aux taxons enfants : {}".format(
            db.session.scalar(
                func.count(func.distinct(SensitivityRuleCache.c.cd_nom)).label("count")
            )
        )
    )


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
