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
    op.execute("DROP FUNCTION gn_permissions.fct_tri_does_user_have_already_scope_filter()")
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
    op.execute(
        """
        CREATE OR REPLACE FUNCTION gn_permissions.fct_tri_does_user_have_already_scope_filter()
         RETURNS trigger
         LANGUAGE plpgsql
        AS $function$
        -- Check if a role has already a SCOPE permission for an action/module/object
        -- use in constraint to force not set multiple scope permission on the same action/module/object
        DECLARE
        the_code_filter_type character varying;
        the_nb_permission integer;
        BEGIN
         SELECT INTO the_code_filter_type bib.code_filter_type
         FROM gn_permissions.t_filters f
         JOIN gn_permissions.bib_filters_type bib ON bib.id_filter_type = f.id_filter_type
         WHERE f.id_filter = NEW.id_filter
        ;
        -- if the filter type is NOT SCOPE, its OK to set multiple permissions
        IF the_code_filter_type != 'SCOPE' THEN
        RETURN NEW;
        -- if the new filter is 'SCOPE TYPE', check if there is not already a permission for this
        -- action/module/object/role
        ELSE
            SELECT INTO the_nb_permission count(perm.id_permission)
            FROM gn_permissions.cor_role_action_filter_module_object perm
            JOIN gn_permissions.t_filters f ON f.id_filter = perm.id_filter
            JOIN gn_permissions.bib_filters_type bib ON bib.id_filter_type = f.id_filter_type AND bib.code_filter_type = 'SCOPE'
            WHERE id_role=NEW.id_role AND id_action=NEW.id_action AND id_module=NEW.id_module AND id_object=NEW.id_object;

         -- if its an insert 0 row must be present, if its an update 1 row must be present
          IF(TG_OP = 'INSERT' AND the_nb_permission = 0) OR (TG_OP = 'UPDATE' AND the_nb_permission = 1) THEN
                RETURN NEW;
            END IF;
            BEGIN
                RAISE EXCEPTION 'ATTENTION: il existe déjà un enregistrement de type SCOPE pour le role % l''action % sur le module % et l''objet % . Il est interdit de définir plusieurs portées à un role pour le même action sur un module et un objet', NEW.id_role, NEW.id_action, NEW.id_module, NEW.id_object ;
            END;


        END IF;

        END;

        $function$
        ;
        """
    )
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
