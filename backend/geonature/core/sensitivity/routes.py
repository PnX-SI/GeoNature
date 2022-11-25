import click
from flask import Blueprint, current_app
from sqlalchemy import func
from sqlalchemy.schema import Table

from geonature.utils.env import db

from .models import SensitivityRule


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
    total_count = SensitivityRule.query.count()

    click.echo("Nombre de règle de sensibilité :")
    click.echo("\tTotal : {}".format(total_count))
    click.echo(
        "\tRègles actives : {}".format(SensitivityRule.query.filter_by(active=True).count())
    )
    click.echo(
        "\tRègles actives extrapolées aux taxons enfants : {}".format(
            db.session.query(func.count(SensitivityRuleCache.c.id_sensitivity)).scalar()
        )
    )

    if total_count:
        click.echo("Nombre de règles de sensibilité par source (actives / total):")
        q = (
            db.session.query(
                SensitivityRule.source,
                func.count(SensitivityRule.id)
                .filter(SensitivityRule.active == True)
                .label("active_count"),
                func.count(SensitivityRule.id).label("total_count"),
            )
            .group_by(SensitivityRule.source)
            .order_by(SensitivityRule.source)
        )
        for source, active_count, total_count in q.all():
            click.echo(f"\t{source} : {active_count} / {total_count}")

    click.echo(f"Nombre de taxons :")
    click.echo(
        "\tTotal : {}".format(SensitivityRule.query.distinct(SensitivityRule.cd_nom).count())
    )
    click.echo(
        "\tRègles actives : {}".format(
            SensitivityRule.query.filter_by(active=True).distinct(SensitivityRule.cd_nom).count()
        )
    )
    click.echo(
        "\tRègles actives extrapolées aux taxons enfants : {}".format(
            db.session.query(
                func.count(func.distinct(SensitivityRuleCache.c.cd_nom)).label("count")
            ).scalar()
        )
    )


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
