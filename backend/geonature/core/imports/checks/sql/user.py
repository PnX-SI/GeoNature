import sqlalchemy as sa
from flask import jsonify
from geonature.core.imports.checks.errors import ImportCodeError
from geonature.core.imports.checks.sql.utils import report_erroneous_rows
from geonature.core.imports.models import BibFields, Entity, TImports
from geonature.utils.env import db
from marshmallow import Schema, fields
from pypnusershub.db.models import User
from sqlalchemy.dialects.postgresql import JSONB, ARRAY


class UserMatchingSchema(Schema):
    user_to_match = fields.String()
    id_role = fields.Integer()
    identifiant = fields.String()
    nom_complet = fields.String()


def user_matching(imprt: TImports, field: BibFields):
    """
    Find matching user for a given transient table and csv column.

    Parameters
    ----------
    imprt : TImports
        The import object which contains the transient table.
    field : BibFields
        field use to fetch user name strings

    Returns
    -------
    dict
        A dictionary of users name (as it apears in the source file) as key and a dictionary of matching information as value.
        The matching information contains id_role, identifiant, nom_complet.

    Notes
    -----
    The matching is done by computing the similarity between the source file usernames and the
    nom_complet of the users in the `utilisateurs.t_roles` table.
    """
    transient_table = imprt.destination.get_transient_table()
    column_transient = transient_table.c[field.source_column]
    if isinstance(column_transient.type, JSONB):
        return {}
    select_ = sa.func.string_to_array(column_transient, ",")

    cte_user_to_match = (
        sa.select(sa.func.distinct(sa.func.unnest(select_)).label("user_to_match"))
        .where(column_transient != None)
        .where(transient_table.c.id_import == imprt.id_import)
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

    query = sa.select(matches).where(
        matches.c.rang == 1,
    )

    result = UserMatchingSchema(
        many=True,
        unknown="exclude",
    ).dump(db.session.execute(query).all())

    return {res["user_to_match"]: res for res in result}


def map_observer_matching(imprt: TImports, entity: Entity, observer_field: BibFields):
    user_matching = imprt.observermapping
    if not user_matching:
        return
    transient_table = imprt.destination.get_transient_table()

    observers_jsonb = (
        sa.func.jsonb_each(TImports.observermapping.cast(JSONB))
        .table_valued("key", "value")
        .alias("observer_jsonb")
    )

    observer_string_id_role = (
        sa.select(
            sa.literal_column("observer_jsonb.key").label("observer_string"),
            sa.cast(sa.literal_column("(observer_jsonb.value->>'id_role')"), sa.Integer).label(
                "id_role"
            ),
        )
        .select_from(
            TImports,
            observers_jsonb,
        )
        .where(TImports.id_import == imprt.id_import)
        .cte("observer_string_id_role")
    )

    query = (
        sa.update(transient_table)
        .where(
            transient_table.c.id_import == imprt.id_import,
            transient_table.c[observer_field.source_column]
            == observer_string_id_role.c.observer_string,
        )
        .values({observer_field.dest_column: observer_string_id_role.c.id_role})
    )

    db.session.execute(query)

    report_erroneous_rows(
        imprt,
        entity,
        error_type=ImportCodeError.INVALID_ATTACHMENT_CODE,
        error_column=observer_field.name_field,
        whereclause=(transient_table.c[observer_field.dest_column] == None),
    )
