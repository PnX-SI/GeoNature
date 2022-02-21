import click
from flask import Blueprint, current_app

from geonature.utils.env import db


routes = Blueprint("sensitivity", __name__)


@routes.cli.command()
def update_synthese():
    count = db.session.execute("SELECT gn_synthese.update_sensitivity()").scalar()
    db.session.commit()
    click.echo(f"Sensitivity updated for {count} rows")
