import click
from flask import Blueprint, current_app

from geonature.utils.env import db


routes = Blueprint("sensitivity", __name__)


@routes.cli.command()
def refresh_rules_cache():
    """
    Rafraichie la vue matérialisée associant les règles aux cd_ref.
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
