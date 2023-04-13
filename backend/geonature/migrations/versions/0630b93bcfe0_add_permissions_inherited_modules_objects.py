"""add permissions inherited modules objects

Add rows in `gn_permissions.cor_role_action_filter_module_object` to keep the permissions that were previously 
inherited from the module "GEONATURE" and the object "ALL". 
Necessary with the removal of modules and objects inheritance in the function used to get permissions.

Revision ID: 0630b93bcfe0
Revises: cf1c1fdbde77
Create Date: 2023-04-13 14:24:21.124669

"""
from alembic import op
import sqlalchemy as sa


# revision identifiers, used by Alembic.
revision = "0630b93bcfe0"
down_revision = "df5a5099e084"
branch_labels = None
depends_on = None


def upgrade():
    """
    Add the permissions that were computed by modules/objects inheritance
    Remove the 'scope 0' filter

    Create backup tables for the permissions, filters types and filters.
    """

    """
    Backup permissions and filters in order to be able to downgrade
    """
    # Backup permissions
    # include Foreign Keys, so that restore is eventually not broken by update/removal
    # of any referenced role, action, filter, module or object
    op.execute(
        """
        create or replace function create_backup_table(source_table text, new_table text)
        returns void language plpgsql
        as $$
        declare
            rec record;
        begin
            execute format(
                'create table %s (like %s including all)',
                new_table, source_table);
            for rec in
                select oid, conname
                from pg_constraint
                where contype = 'f' 
                and conrelid = source_table::regclass
            loop
                execute format(
                    'alter table %s add constraint %s %s',
                    new_table,
                    'backup_' || rec.conname,
                    pg_get_constraintdef(rec.oid));
            end loop;
            execute format(
                'insert into %s select * from %s', 
                new_table, source_table);
        end $$;
        """
    )
    op.execute(
        """
        SELECT
        create_backup_table(
        'gn_permissions.cor_role_action_filter_module_object',
        'gn_permissions.backup_cor_role_action_filter_module_object'
        );
        """
    )
    op.execute(
        """
        SELECT
        create_backup_table(
        'gn_permissions.t_filters',
        'gn_permissions.backup_t_filters'
        );
        """
    )
    op.execute(
        """
        SELECT
        create_backup_table(
        'gn_permissions.bib_filters_type',
        'gn_permissions.backup_bib_filters_type'
        );
        """
    )
    op.execute(
        """
        DROP FUNCTION create_backup_table;
        """
    )
    # Associate FK 'fk_backup_cor_r_a_f_m_o_id_filter' to 'backup_t_filters' instead of 't_filters'
    # ON DELETE and ON UPDATE rules should not matter, as no modification from 'backup_t_filters' is expected
    op.drop_constraint(
        "backup_fk_cor_r_a_f_m_o_id_filter",
        table_name="backup_cor_role_action_filter_module_object",
        schema="gn_permissions",
    )
    op.create_foreign_key(
        "backup_fk_cor_r_a_f_m_o_id_filter",
        source_schema="gn_permissions",
        source_table="backup_cor_role_action_filter_module_object",
        local_cols=["id_filter"],
        referent_schema="gn_permissions",
        referent_table="backup_t_filters",
        remote_cols=["id_filter"],
        onupdate=None,
        ondelete="CASCADE",
    )
    op.drop_constraint(
        "backup_fk_t_filters_id_filter_type",
        table_name="backup_t_filters",
        schema="gn_permissions",
    )
    op.create_foreign_key(
        "backup_fk_t_filters_id_filter_type",
        source_schema="gn_permissions",
        source_table="backup_t_filters",
        local_cols=["id_filter_type"],
        referent_schema="gn_permissions",
        referent_table="backup_bib_filters_type",
        remote_cols=["id_filter_type"],
        onupdate=None,
        ondelete="CASCADE",
    )

    """
    Remove permissions with filters which are not of SCOPE type
    """
    op.execute(
        """
        DELETE FROM
            gn_permissions.cor_role_action_filter_module_object p
        USING
            gn_permissions.t_filters f,
            gn_permissions.bib_filters_type t
        WHERE
            p.id_filter = f.id_filter
        AND
            f.id_filter_type = t.id_filter_type
        AND
            t.code_filter_type != 'SCOPE'
        """
    )
    op.execute(
        """
        DELETE FROM
            gn_permissions.t_filters f
        USING
            gn_permissions.bib_filters_type t
        WHERE
            f.id_filter_type = t.id_filter_type
        AND
            t.code_filter_type != 'SCOPE'
        """
    )
    op.execute(
        """
        DELETE FROM
            gn_permissions.bib_filters_type t
        WHERE
            t.code_filter_type != 'SCOPE'
        """
    )
    """
    Thereafter, all permissions are of SCOPE type without requiring verification
    """

    """
    Modules inheritance:
    
    Inherit permissions (id_role, id_action, id_filter, _ , id_object) from module GN to other modules
    when a permission (id_role, id_action, _ , _ , id_object) is not already specified for the other module.
    """
    # For permissions associated to roles which are users, and roles which are groups with no corresponding user that
    # have a scope restriction for the permission :
    #   by 'scope restriction' we mean a case where the permission to be inserted is
    #   (id_role_group, id_action, id_filter_group, id_module, id_object), with id_filter_group of type 'SCOPE',
    #   where the role id_role_user is associated to the role id_role_group and where there exists a permission
    #   (id_role_user, id_action, id_filter_user, id_module, id_object) with id_filter_user < id_filter_group).
    op.execute(
        """
        INSERT
            INTO
            gn_permissions.cor_role_action_filter_module_object
                (id_role,
                id_action,
                id_filter,
                id_module,
                id_object)
        SELECT
                perm_gn.id_role,
                perm_gn.id_action,
                perm_gn.id_filter,
                module_other.id_module,
                perm_gn.id_object
        FROM
            gn_commons.t_modules module_other,
            gn_permissions.cor_role_action_filter_module_object perm_gn
            JOIN gn_commons.t_modules module_gn ON perm_gn.id_module = module_gn.id_module
            JOIN utilisateurs.t_roles r ON perm_gn.id_role = r.id_role
            JOIN gn_permissions.t_filters filter_scope_group ON perm_gn.id_filter = filter_scope_group.id_filter 
        WHERE
            module_gn.module_code = 'GEONATURE'
            AND 
            module_other.module_code != 'GEONATURE'
            AND 
            (
                r.groupe IS FALSE
                OR
                NOT EXISTS
                (
                SELECT
                    NULL
                FROM
                    gn_permissions.cor_role_action_filter_module_object restriction_perm_exists
                    JOIN utilisateurs.cor_roles association_group_user 
                        ON restriction_perm_exists.id_role = association_group_user.id_role_utilisateur
                        AND perm_gn.id_role = association_group_user.id_role_groupe
                    JOIN gn_permissions.t_filters filter_scope_user
                        ON restriction_perm_exists.id_filter = filter_scope_user.id_filter
                WHERE
                    restriction_perm_exists.id_action = perm_gn.id_action
                    AND
                    restriction_perm_exists.id_module = module_other.id_module
                    AND
                    restriction_perm_exists.id_object = perm_gn.id_object
                    AND
                    filter_scope_user.value_filter::INTEGER < filter_scope_group.value_filter::INTEGER
                )
            )
            AND
            NOT EXISTS 
            (
            SELECT
                NULL
            FROM
                gn_permissions.cor_role_action_filter_module_object perm_exists
            WHERE
                perm_exists.id_role = perm_gn.id_role
                AND 
                perm_exists.id_action = perm_gn.id_action
                AND 
                perm_exists.id_module = module_other.id_module
                AND 
                perm_exists.id_object = perm_gn.id_object
            )
        ;
        """
    )
    # For permissions associated to roles which are groups with at least one corresponding user that have a scope
    # restriction for the permission
    op.execute(
        """
        INSERT
            INTO
            gn_permissions.cor_role_action_filter_module_object
                (id_role,
                id_action,
                id_filter,
                id_module,
                id_object)
        SELECT
                user_other.id_role,
                perm_gn.id_action,
                perm_gn.id_filter,
                module_other.id_module,
                perm_gn.id_object
        FROM
            gn_commons.t_modules module_other,
            gn_permissions.cor_role_action_filter_module_object perm_gn
                JOIN gn_commons.t_modules module_gn 
                    ON perm_gn.id_module = module_gn.id_module
                JOIN utilisateurs.t_roles role_groupe 
                    ON perm_gn.id_role = role_groupe.id_role
                JOIN gn_permissions.t_filters filter_scope_group 
                    ON perm_gn.id_filter = filter_scope_group.id_filter,
            utilisateurs.t_roles user_other
                JOIN utilisateurs.cor_roles association_group_other_user 
                    ON user_other.id_role = association_group_other_user.id_role_utilisateur
        WHERE
            module_gn.module_code = 'GEONATURE'
            AND 
            module_other.module_code != 'GEONATURE'
            AND 
            perm_gn.id_role = association_group_other_user.id_role_groupe
            AND 
            (
                role_groupe.groupe IS TRUE
                AND
                EXISTS
                (
                SELECT
                    restriction_perm_exists.id_role AS id_user_with_restriction
                FROM
                    gn_permissions.cor_role_action_filter_module_object restriction_perm_exists
                    JOIN utilisateurs.cor_roles association_group_user 
                        ON restriction_perm_exists.id_role = association_group_user.id_role_utilisateur
                        AND perm_gn.id_role = association_group_user.id_role_groupe
                    JOIN gn_permissions.t_filters filter_scope_user
                        ON restriction_perm_exists.id_filter = filter_scope_user.id_filter
                WHERE
                    restriction_perm_exists.id_action = perm_gn.id_action
                    AND
                    restriction_perm_exists.id_module = module_other.id_module
                    AND
                    restriction_perm_exists.id_object = perm_gn.id_object
                    AND
                    filter_scope_user.value_filter::INTEGER < filter_scope_group.value_filter::INTEGER
                )
            )
            AND
            NOT EXISTS 
            (
            SELECT
                NULL
            FROM
                gn_permissions.cor_role_action_filter_module_object perm_group_exists
            WHERE
                perm_group_exists.id_role = perm_gn.id_role
                AND 
                perm_group_exists.id_action = perm_gn.id_action
                AND 
                perm_group_exists.id_module = module_other.id_module
                AND 
                perm_group_exists.id_object = perm_gn.id_object
            )
            AND
            NOT EXISTS 
            (
            SELECT
                NULL
            FROM
                gn_permissions.cor_role_action_filter_module_object perm_user_exists
            WHERE
                perm_user_exists.id_role = user_other.id_role
                AND 
                perm_user_exists.id_action = perm_gn.id_action
                AND 
                perm_user_exists.id_module = module_other.id_module
                AND 
                perm_user_exists.id_object = perm_gn.id_object
            )
        ;
        """
    )

    """
    Objects inheritance:
     
    Inherit permissions (id_role, id_action, id_filter, id_module, id_object("ALL")) from object ALL to other objects
    when the other object is associated to the module id_module in the `gn_permissions.cor_object_module`
    and when a permission (id_role, id_action, _ , id_module, _ ) is not already specified for the other object.
    """
    # For permissions associated to roles which are users, and roles which are groups with no corresponding user that
    # have a scope restriction for the permission :
    op.execute(
        """
        INSERT
            INTO
            gn_permissions.cor_role_action_filter_module_object
                (id_role,
                id_action,
                id_filter,
                id_module,
                id_object)
        SELECT
            perm_object_all.id_role,
            perm_object_all.id_action,
            perm_object_all.id_filter,
            perm_object_all.id_module,
            object_other.id_object
        FROM
            gn_permissions.cor_role_action_filter_module_object perm_object_all
            JOIN gn_permissions.t_objects object_all 
                ON perm_object_all.id_object = object_all.id_object
            JOIN gn_permissions.cor_object_module cor_object_module 
                ON cor_object_module.id_module = perm_object_all.id_module
            JOIN gn_permissions.t_objects object_other 
                ON object_other.id_object = cor_object_module.id_object
            JOIN utilisateurs.t_roles r 
                ON perm_object_all.id_role = r.id_role
            JOIN gn_permissions.t_filters filter_scope_group 
                ON perm_object_all.id_filter = filter_scope_group.id_filter
        WHERE
            object_all.code_object = 'ALL'
            AND
            object_other.code_object != 'ALL'
            AND 
            (
                r.groupe IS FALSE
                OR
                NOT EXISTS
                (
                SELECT
                    NULL
                FROM
                    gn_permissions.cor_role_action_filter_module_object restriction_perm_exists
                    JOIN utilisateurs.cor_roles association_group_user 
                        ON restriction_perm_exists.id_role = association_group_user.id_role_utilisateur
                        AND perm_object_all.id_role = association_group_user.id_role_groupe
                    JOIN gn_permissions.t_filters filter_scope_user
                        ON restriction_perm_exists.id_filter = filter_scope_user.id_filter
                WHERE
                    restriction_perm_exists.id_action = perm_object_all.id_action
                    AND
                    restriction_perm_exists.id_module = perm_object_all.id_module
                    AND
                    restriction_perm_exists.id_object = object_other.id_object
                    AND
                    filter_scope_user.value_filter::INTEGER < filter_scope_group.value_filter::INTEGER
                )
            )
            AND
            NOT EXISTS 
            (
            SELECT
                NULL
            FROM
                gn_permissions.cor_role_action_filter_module_object perm_exists
            WHERE
                perm_exists.id_role = perm_object_all.id_role
                AND 
                perm_exists.id_action = perm_object_all.id_action
                AND 
                perm_exists.id_module = perm_object_all.id_module
                AND 
                perm_exists.id_object = object_other.id_object
            )
        ;
    """
    )
    # For permissions associated to roles which are groups with at least one corresponding user that have a scope
    # restriction for the permission
    op.execute(
        """
        INSERT
            INTO
            gn_permissions.cor_role_action_filter_module_object
                (id_role,
                id_action,
                id_filter,
                id_module,
                id_object)
        SELECT
            user_other.id_role,
            perm_object_all.id_action,
            perm_object_all.id_filter,
            perm_object_all.id_module,
            object_other.id_object
        FROM
            gn_permissions.cor_role_action_filter_module_object perm_object_all
                JOIN gn_permissions.t_objects object_all 
                    ON perm_object_all.id_object = object_all.id_object
                JOIN gn_permissions.cor_object_module cor_object_module 
                    ON cor_object_module.id_module = perm_object_all.id_module
                JOIN gn_permissions.t_objects object_other 
                    ON object_other.id_object = cor_object_module.id_object
                JOIN utilisateurs.t_roles role_groupe
                    ON perm_object_all.id_role = role_groupe.id_role
                JOIN gn_permissions.t_filters filter_scope_group 
                    ON perm_object_all.id_filter = filter_scope_group.id_filter,
            utilisateurs.t_roles user_other
                JOIN utilisateurs.cor_roles association_group_other_user 
                    ON user_other.id_role = association_group_other_user.id_role_utilisateur
        WHERE
            object_all.code_object = 'ALL'
            AND
            object_other.code_object != 'ALL'
            AND 
            perm_object_all.id_role = association_group_other_user.id_role_groupe
            AND
            (
                role_groupe.groupe IS TRUE
                AND
                EXISTS
                (
                SELECT
                    restriction_perm_exists.id_role AS id_user_with_restriction
                FROM
                    gn_permissions.cor_role_action_filter_module_object restriction_perm_exists
                    JOIN utilisateurs.cor_roles association_group_user 
                        ON restriction_perm_exists.id_role = association_group_user.id_role_utilisateur
                        AND perm_object_all.id_role = association_group_user.id_role_groupe
                    JOIN gn_permissions.t_filters filter_scope_user
                        ON restriction_perm_exists.id_filter = filter_scope_user.id_filter
                WHERE
                    restriction_perm_exists.id_action = perm_object_all.id_action
                    AND
                    restriction_perm_exists.id_module = perm_object_all.id_module
                    AND
                    restriction_perm_exists.id_object = object_other.id_object
                    AND
                    filter_scope_user.value_filter::INTEGER < filter_scope_group.value_filter::INTEGER
                )
            )
            AND
            NOT EXISTS 
            (
            SELECT
                NULL
            FROM
                gn_permissions.cor_role_action_filter_module_object perm_group_exists
            WHERE
                perm_group_exists.id_role = perm_object_all.id_role
                AND 
                perm_group_exists.id_action = perm_object_all.id_action
                AND 
                perm_group_exists.id_module = perm_object_all.id_module
                AND 
                perm_group_exists.id_object = object_other.id_object
            )
            AND
            NOT EXISTS 
            (
            SELECT
                NULL
            FROM
                gn_permissions.cor_role_action_filter_module_object perm_user_exists
            WHERE
                perm_user_exists.id_role = user_other.id_role
                AND 
                perm_user_exists.id_action = perm_object_all.id_action
                AND 
                perm_user_exists.id_module = perm_object_all.id_module
                AND 
                perm_user_exists.id_object = object_other.id_object
            )
        ;
    """
    )


def downgrade():
    """
    Restore the permissions and filters from backup
    """

    # First clear existing data
    op.execute(
        """
        DELETE FROM gn_permissions.cor_role_action_filter_module_object;
        DELETE FROM gn_permissions.t_filters;
        DELETE FROM gn_permissions.bib_filters_type;
        """
    )

    """
    Restore filters types from backup table
    """
    op.execute(
        """
        INSERT INTO gn_permissions.bib_filters_type
            (id_filter_type, code_filter_type, label_filter_type, description_filter_type)
        SELECT id_filter_type, code_filter_type, label_filter_type, description_filter_type
        FROM gn_permissions.backup_bib_filters_type
        """
    )

    """
    Restore filters from backup table
    """
    op.execute(
        """
        INSERT INTO gn_permissions.t_filters 
            (id_filter, label_filter, value_filter, description_filter, id_filter_type)
        SELECT id_filter, label_filter, value_filter, description_filter, id_filter_type
        FROM gn_permissions.backup_t_filters
        """
    )

    """
    Restore permissions from backup table
    """
    op.execute(
        """
        INSERT INTO gn_permissions.cor_role_action_filter_module_object 
            (id_permission, id_role, id_action, id_module, id_object, id_filter)
        SELECT id_permission, id_role, id_action, id_module, id_object, id_filter
        FROM gn_permissions.backup_cor_role_action_filter_module_object;
        """
    )

    """
    Drop backup tables
    
    drop 'backup_t_filters' after 'backup_cor_role_action_filter_module_object' because of 
    'fk_backup_cor_r_a_f_m_o_id_filter' referencing 'backup_t_filters'
    """
    op.drop_table(
        schema="gn_permissions", table_name="backup_cor_role_action_filter_module_object"
    )
    op.drop_table(schema="gn_permissions", table_name="backup_t_filters")
    op.drop_table(schema="gn_permissions", table_name="backup_bib_filters_type")
