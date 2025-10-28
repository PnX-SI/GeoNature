from geonature.core.imports.models import BibFields, TImports
from marshmallow import Schema, fields
from pypnusershub.db.models import User
import sqlalchemy as sa
from flask import jsonify
from geonature.utils.env import db


def user_matching(imprt: TImports, csv_column: BibFields):
    """
    Find matching user for a given transient table and csv column.

    Parameters
    ----------
    imprt : TImports
        The import object which contains the transient table.
    csv_column : BibFields
        The csv column to use for matching.

    Returns
    -------
    dict
        A dictionary of user_to_match as key and a dictionary of matching information as value.
        The matching information contains id_role, identifiant, nom_complet.

    Notes
    -----
    The matching is done by computing the similarity between the user_to_match and the nom_complet of the users.
    The similarity is computed using the Levenshtein distance.
    The matching is done by selecting the user with the highest similarity.
    If multiple users have the same highest similarity, the first one is selected.
    """
    transient_table = imprt.destination.get_transient_table()
    column_transient = transient_table.c[csv_column.source_field]
    cte_user_to_match = (
        sa.select(
            sa.func.distinct(sa.func.unnest(sa.func.string_to_array(column_transient, ","))).label(
                "user_to_match"
            )
        )
        .where(column_transient != None)
        .cte("cte_user_to_match")
    )

    cte_user_nom_complet = sa.select(
        User.id_role,
        User.identifiant,
        User.nom_complet,
    ).cte("cte_user_nom_complet")

    matches = sa.select(
        cte_user_to_match.c.user_to_match,
        cte_user_nom_complet.c.id_role,
        cte_user_nom_complet.c.identifiant,
        cte_user_nom_complet.c.nom_complet,
        sa.func.similarity(
            cte_user_to_match.c.user_to_match, cte_user_nom_complet.c.nom_complet
        ).label("similarity"),
        sa.func.row_number()
        .over(
            partition_by=cte_user_to_match.c.user_to_match,
            order_by=sa.desc(
                sa.func.similarity(
                    cte_user_to_match.c.user_to_match, cte_user_nom_complet.c.nom_complet
                )
            ),
        )
        .label("rang"),
    ).cte()

    query = sa.select(matches).where(matches.c.rang == 1, matches.c.similarity > 0.5)

    result = db.session.execute(query).all()

    class UserMatchingSchema(Schema):
        user_to_match = fields.String()
        id_role = fields.Integer()
        identifiant = fields.String()
        nom_complet = fields.String()

    result = UserMatchingSchema(many=True, unknown="exclude").dump(result)
    final = {}
    for res in result:
        final[res["user_to_match"]] = res

    imprt.observermapping = final
    db.session.commit()

    return final
