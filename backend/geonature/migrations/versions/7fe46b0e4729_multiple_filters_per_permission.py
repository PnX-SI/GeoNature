"""multiple filters per permission

Revision ID: 7fe46b0e4729
Revises: cf1c1fdbde77
Create Date: 2023-04-12 14:38:44.788935

"""
from alembic import op
import sqlalchemy as sa
from sqlalchemy import Column, ForeignKey, Integer
from sqlalchemy.types import ARRAY


# revision identifiers, used by Alembic.
revision = "7fe46b0e4729"
down_revision = "cf1c1fdbde77"
branch_labels = None
depends_on = None


def upgrade():
    op.drop_table(schema="gn_permissions", table_name="cor_filter_type_module")
    op.rename_table(
        schema="gn_permissions",
        old_table_name="cor_role_action_filter_module_object",
        new_table_name="t_permissions",
    )
    op.execute("DROP TRIGGER tri_check_no_multiple_scope_perm ON gn_permissions.t_permissions")
    # TODO: drop trigger function
    op.rename_table(
        schema="gn_permissions", old_table_name="t_filters", new_table_name="bib_filters_values"
    )
    op.alter_column(
        schema="gn_permissions",
        table_name="bib_filters_values",
        column_name="id_filter",
        new_column_name="id_filter_value",
    )
    op.create_table(
        "t_filters",
        Column(
            "id_permission",
            Integer,
            ForeignKey("gn_permissions.t_permissions.id_permission", ondelete="cascade"),
            primary_key=True,
        ),
        Column(
            "id_filter_type",
            Integer,
            ForeignKey("gn_permissions.bib_filters_type.id_filter_type"),
            primary_key=True,
        ),
        Column(
            "id_filter_value",
            Integer,
            ForeignKey("gn_permissions.bib_filters_values.id_filter_value"),
            nullable=True,
        ),
        Column("values", ARRAY(Integer), nullable=True),
        schema="gn_permissions",
    )
    op.alter_column(
        schema="gn_permissions",
        table_name="t_permissions",
        column_name="id_filter",
        nullable=True,
    )
    op.execute(
        """
        UPDATE
            gn_permissions.t_permissions
        SET
            id_filter = NULL
        WHERE
            id_filter = (
                SELECT
                    v.id_filter_value
                FROM
                    gn_permissions.bib_filters_values v
                JOIN
                    gn_permissions.bib_filters_type t USING (id_filter_type)
                WHERE
                    t.code_filter_type = 'SCOPE'
                AND
                    v.value_filter = '3'
            )
        """
    )
    op.execute(
        """
        DELETE FROM
            gn_permissions.bib_filters_values
        WHERE
            id_filter_type = (SELECT id_filter_type FROM gn_permissions.bib_filters_type WHERE code_filter_type = 'SCOPE')
        AND
            value_filter = '3'
        """
    )
    op.execute(
        """
        INSERT INTO
            gn_permissions.t_filters (
                id_permission,
                id_filter_type,
                id_filter_value
            )
        SELECT
            p.id_permission,
            t.id_filter_type,
            v.id_filter_value
        FROM
            gn_permissions.t_permissions p
        JOIN
            gn_permissions.bib_filters_values v ON p.id_filter = v.id_filter_value
        JOIN
            gn_permissions.bib_filters_type t ON v.id_filter_type = t.id_filter_type
        """
    )
    op.drop_column(schema="gn_permissions", table_name="t_permissions", column_name="id_filter")


def downgrade():
    if (
        op.get_bind()
        .execute(
            """
            SELECT EXISTS (
                SELECT
                    id_permission
                FROM
                    gn_permissions.t_filters
                WHERE
                    id_filter_value IS NULL
                GROUP BY
                    id_permission
                HAVING
                    COUNT(*) > 0
            )
            """
        )
        .scalar()
    ):
        raise Exception(
            "Certaines permissions ont des filtres avancées (id_filter_value IS NULL), impossible de revenir à l’ancienne structure."
        )
    if (
        op.get_bind()
        .execute(
            """
            SELECT EXISTS (
                SELECT
                    id_permission
                FROM
                    gn_permissions.t_filters
                GROUP BY
                    id_permission
                HAVING
                    COUNT(*) > 1
            )
            """
        )
        .scalar()
    ):
        raise Exception(
            "Certaines permissions ont plusieurs filtres, impossible de revenir à l’ancienne structure."
        )
    op.add_column(
        schema="gn_permissions",
        table_name="t_permissions",
        column=Column(
            "id_filter",
            Integer,
            ForeignKey("gn_permissions.bib_filters_values.id_filter_value"),
            nullable=True,
        ),
    )
    # Copy filters into t_permissions.id_filter
    op.execute(
        """
        UPDATE
            gn_permissions.t_permissions p
        SET
            id_filter = f.id_filter_value
        FROM (
            SELECT
                f.id_permission,
                f.id_filter_value
            FROM
                gn_permissions.t_filters f
            WHERE
                f.id_filter_value IS NOT NULL
        ) f
        WHERE
            p.id_permission = f.id_permission
        """
    )
    # Set SCOPE=3 for permissions without any filters
    op.execute(
        """
        INSERT INTO
            gn_permissions.bib_filters_values (id_filter_type, label_filter, value_filter, description_filter)
        VALUES (
            (SELECT id_filter_type FROM gn_permissions.bib_filters_type WHERE code_filter_type = 'SCOPE'),
            'Toutes les données',
            '3',
            'Toutes les données'
        )
        """
    )
    op.execute(
        """
        UPDATE
            gn_permissions.t_permissions p
        SET
            id_filter = (
                SELECT
                    v.id_filter_value
                FROM
                    gn_permissions.bib_filters_values v
                JOIN
                    gn_permissions.bib_filters_type t USING (id_filter_type)
                WHERE
                    t.code_filter_type = 'SCOPE'
                AND
                    v.value_filter = '3'
           )
        WHERE
            id_filter IS NULL
        """
    )
    op.alter_column(
        schema="gn_permissions",
        table_name="t_permissions",
        column_name="id_filter",
        nullable=False,
    )
    op.drop_table(schema="gn_permissions", table_name="t_filters")
    op.alter_column(
        schema="gn_permissions",
        table_name="bib_filters_values",
        column_name="id_filter_value",
        new_column_name="id_filter",
    )
    op.rename_table(
        schema="gn_permissions", old_table_name="bib_filters_values", new_table_name="t_filters"
    )
    op.rename_table(
        schema="gn_permissions",
        old_table_name="t_permissions",
        new_table_name="cor_role_action_filter_module_object",
    )
    # TODO: re-create trigger function
    op.execute(
        """
        CREATE TRIGGER tri_check_no_multiple_scope_perm
        BEFORE INSERT OR UPDATE
        ON gn_permissions.cor_role_action_filter_module_object
        FOR EACH ROW
        EXECUTE PROCEDURE gn_permissions.fct_tri_does_user_have_already_scope_filter()
        """
    )
    op.create_table(
        "cor_filter_type_module",
        Column(
            "id_filter_type",
            Integer,
            ForeignKey("gn_permissions.bib_filters_type.id_filter_type"),
            primary_key=True,
        ),
        Column(
            "id_module", Integer, ForeignKey("gn_commons.t_modules.id_module"), primary_key=True
        ),
        schema="gn_permissions",
    )
