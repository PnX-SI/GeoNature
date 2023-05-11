"""multiple filters per permission

Revision ID: 7fe46b0e4729
Revises: cf1c1fdbde77
Create Date: 2023-04-12 14:38:44.788935

"""
from alembic import op
import sqlalchemy as sa
from sqlalchemy import Column, ForeignKey, Integer, Unicode
from sqlalchemy.types import ARRAY


# revision identifiers, used by Alembic.
revision = "7fe46b0e4729"
down_revision = "0630b93bcfe0"
branch_labels = None
depends_on = None


def upgrade():
    # Remove unused table
    op.drop_table(schema="gn_permissions", table_name="cor_filter_type_module")

    # Rename tables with better names
    op.rename_table(
        schema="gn_permissions", old_table_name="t_actions", new_table_name="bib_actions"
    )
    op.rename_table(
        schema="gn_permissions",
        old_table_name="cor_role_action_filter_module_object",
        new_table_name="t_permissions",
    )

    # Remove triggers
    op.execute("DROP TRIGGER tri_check_no_multiple_scope_perm ON gn_permissions.t_permissions")
    op.execute("DROP FUNCTION gn_permissions.fct_tri_does_user_have_already_scope_filter()")

    # Remove SCOPE '3' as equivalent to no filters
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
                    f.id_filter
                FROM
                    gn_permissions.t_filters f
                JOIN
                    gn_permissions.bib_filters_type t USING (id_filter_type)
                WHERE
                    t.code_filter_type = 'SCOPE'
                AND
                    f.value_filter = '3'
            )
        """
    )
    op.execute(
        """
        DELETE FROM
            gn_permissions.t_filters
        WHERE
            id_filter_type = (SELECT id_filter_type FROM gn_permissions.bib_filters_type WHERE code_filter_type = 'SCOPE')
        AND
            value_filter = '3'
        """
    )

    # Migrate t_permissions.id_filter to t_permissions.filter_scope
    op.create_table(
        "bib_filters_scope",
        Column("value", Integer, primary_key=True),
        Column("label", Unicode),
        Column("description", Unicode),
        schema="gn_permissions",
    )
    op.execute(
        """
        INSERT INTO
            gn_permissions.bib_filters_scope (
                value,
                label,
                description
            )
        SELECT
            f.value_filter::int,
            f.label_filter,
            f.description_filter
        FROM
            gn_permissions.t_filters f
        JOIN
            gn_permissions.bib_filters_type t USING (id_filter_type)
        WHERE
            t.code_filter_type = 'SCOPE'
        """
    )
    op.add_column(
        schema="gn_permissions",
        table_name="t_permissions",
        column=Column(
            "scope_value",
            Integer,
            ForeignKey("gn_permissions.bib_filters_scope.value"),
            nullable=True,
        ),
    )
    op.execute(
        """
        UPDATE
            gn_permissions.t_permissions p
        SET
            scope_value = s.value
        FROM
            gn_permissions.t_filters f
        JOIN
            gn_permissions.bib_filters_scope s ON s.value = f.value_filter::int
        JOIN
            gn_permissions.bib_filters_type t ON t.id_filter_type = f.id_filter_type
        WHERE
            t.code_filter_type = 'SCOPE'
        AND
            p.id_filter = f.id_filter
        """
    )
    op.drop_column(schema="gn_permissions", table_name="t_permissions", column_name="id_filter")
    op.drop_table(schema="gn_permissions", table_name="t_filters")


def downgrade():
    op.create_table(
        "t_filters",
        Column("id_filter", Integer, primary_key=True),
        Column("label_filter", Unicode(255)),
        Column("value_filter", Unicode),
        Column("description_filter", Unicode),
        Column(
            "id_filter_type",
            Integer,
            ForeignKey(
                "gn_permissions.bib_filters_type.id_filter_type",
                name="fk_t_filters_id_filter_type",
            ),
        ),
        schema="gn_permissions",
    )
    op.execute(
        """
        INSERT INTO
            gn_permissions.t_filters (
                label_filter,
                value_filter,
                description_filter,
                id_filter_type
            )
        SELECT
            s.label,
            s.value::varchar,
            s.description,
            t.id_filter_type
        FROM
            gn_permissions.bib_filters_scope s
        JOIN
            gn_permissions.bib_filters_type t ON t.code_filter_type = 'SCOPE'
        """
    )
    op.add_column(
        schema="gn_permissions",
        table_name="t_permissions",
        column=Column(
            "id_filter",
            Integer,
            ForeignKey("gn_permissions.t_filters.id_filter", name="fk_cor_r_a_f_m_o_id_filter"),
            nullable=True,
        ),
    )
    # Copy scope_value into id_filter
    op.execute(
        """
        UPDATE
            gn_permissions.t_permissions p
        SET
            id_filter = f.id_filter
        FROM (
            SELECT
                p.id_permission,
                f.id_filter
            FROM
                gn_permissions.t_permissions p
            JOIN
                gn_permissions.bib_filters_scope s ON p.scope_value = s.value
            JOIN
                gn_permissions.t_filters f ON f.value_filter::int = s.value
            JOIN
                gn_permissions.bib_filters_type t ON t.id_filter_type = f.id_filter_type
            WHERE
                t.code_filter_type = 'SCOPE'
            AND
                p.scope_value IS NOT NULL
        ) f
        WHERE
            p.id_permission = f.id_permission
        """
    )
    op.drop_column(schema="gn_permissions", table_name="t_permissions", column_name="scope_value")
    op.drop_table(schema="gn_permissions", table_name="bib_filters_scope")
    # Set SCOPE=3 for permissions without any filters
    op.execute(
        """
        INSERT INTO
            gn_permissions.t_filters (id_filter_type, label_filter, value_filter, description_filter)
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
                    f.id_filter
                FROM
                    gn_permissions.t_filters f
                JOIN
                    gn_permissions.bib_filters_type t USING (id_filter_type)
                WHERE
                    t.code_filter_type = 'SCOPE'
                AND
                    f.value_filter = '3'
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
    # op.drop_table(schema="gn_permissions", table_name="t_filters")
    op.execute(
        """
        CREATE FUNCTION gn_permissions.fct_tri_does_user_have_already_scope_filter()
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
        ON gn_permissions.t_permissions
        FOR EACH ROW
        EXECUTE PROCEDURE gn_permissions.fct_tri_does_user_have_already_scope_filter()
        """
    )
    op.rename_table(
        schema="gn_permissions",
        old_table_name="t_permissions",
        new_table_name="cor_role_action_filter_module_object",
    )
    op.rename_table(
        schema="gn_permissions", old_table_name="bib_actions", new_table_name="t_actions"
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
