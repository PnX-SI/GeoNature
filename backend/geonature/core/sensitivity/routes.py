import click
from flask import Blueprint, current_app

from geonature.utils.env import db


routes = Blueprint("sensitivity", __name__)


@routes.cli.command()
def update_synthese():
    count = db.session.execute("""
    WITH updated_rows AS (
        UPDATE gn_synthese.synthese s
            -- sensitivity update trigger is watching the cd_nom
            SET cd_nom = s.cd_nom
        WHERE
            s.id_nomenclature_sensitivity != ref_nomenclatures.get_id_nomenclature('SENSIBILITE', '0') -- non sensible
        OR
            taxonomie.find_cdref(s.cd_nom) IN (SELECT DISTINCT cd_ref FROM gn_sensitivity.t_sensitivity_rules_cd_ref)
        RETURNING 1
    )
    SELECT count(*) FROM updated_rows
    """).scalar()
    click.echo(f"Sensitivity recalculated for {count} rows (not necessary changed!)")
    db.session.commit()
