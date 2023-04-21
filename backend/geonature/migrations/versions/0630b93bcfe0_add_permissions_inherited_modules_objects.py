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
    upgrade
    """

    """
    Backup permissions in order to be able to downgrade
    """
    op.execute(
        """
        CREATE TABLE gn_permissions.backup_cor_role_action_filter_module_object
        AS TABLE gn_permissions.cor_role_action_filter_module_object
        """
    )

    """
    Modules inheritance:
    
    Inherit permissions (id_role, id_action, id_filter, _ , id_object) from module GN to other modules
    when a permission (id_role, id_action, _ , _ , id_object) is not already specified for the other module.
    """
    # For roles which are users, and roles which are groups with no user associated that have a scope restriction :
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
        	            ON restriction_perms_exists.id_filter = filter_scope_user.id_filter
        	        JOIN gn_permissions.bib_filters_type filter_type_scope
        	            ON filter_scope_user.id_filter_type = filter_type_scope.id_filter_type
        	    WHERE
        	        restriction_perms_exists.id_action = perm_gn.id_action
        	        AND
        	        restriction_perms_exists.id_module = module_other.id_module
        	        AND
        	        restriction_perms_exists.id_object = perm_gn.id_object
        	        AND
        	        filter_type_scope.code_filter_type = 'SCOPE'
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
        	);
        """
    )
    # For roles which are groups with at least one user associated that have a scope restriction
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
                    ON perm_gn.id_role = role_groupe.id_role,
                JOIN gn_permissions.t_filters filter_scope_group 
                    ON perm_gn.id_filter = filter_scope_group.id_filter
            utilisateurs.t_roles user_other
                JOIN utilisateurs.cor_roles association_group_other_user 
                    ON user_other.id_role = association_group_other_user.id_role_utilisateur
                    AND perm_gn.id_role = association_group_other_user.id_role_groupe
                    AND user_other.id_role != id_user_with_restriction,
        WHERE
            module_gn.module_code = 'GEONATURE'
            AND 
            module_other.module_code != 'GEONATURE'
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
                        ON restriction_perms_exists.id_filter = filter_scope_user.id_filter
        	        JOIN gn_permissions.bib_filters_type filter_type_scope
        	            ON filter_scope_user.id_filter_type = filter_type_scope.id_filter_type
                WHERE
        	        restriction_perms_exists.id_action = perm_gn.id_action
        	        AND
        	        restriction_perms_exists.id_module = module_other.id_module
        	        AND
        	        restriction_perms_exists.id_object = perm_gn.id_object
        	        AND
        	        filter_type_scope.code_filter_type = 'SCOPE'
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
                perm_exists.id_role = user_other.id_role
                AND 
                perm_exists.id_action = perm_gn.id_action
                AND 
                perm_exists.id_module = module_other.id_module
                AND 
                perm_exists.id_object = perm_gn.id_object
            );
        """
    )

    """
    Objects inheritance:
     
    Inherit permissions (id_role, id_action, id_filter, id_module, id_object("ALL")) from object ALL to other objects
    when the other object is associated to the module id_module in the `gn_permissions.cor_object_module`
    and when a permission (id_role, id_action, _ , id_module, _ ) is not already specified for the other object.
    """
    # For roles which are users, and roles which are groups with no user associated that have a scope restriction
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
        	            ON restriction_perms_exists.id_filter = filter_scope_user.id_filter
        	        JOIN gn_permissions.bib_filters_type filter_type_scope
        	            ON filter_scope_user.id_filter_type = filter_type_scope.id_filter_type
        	    WHERE
        	        restriction_perms_exists.id_action = perm_object_all.id_action
        	        AND
        	        restriction_perms_exists.id_module = perm_object_all.id_module
        	        AND
        	        restriction_perms_exists.id_object = object_other.id_object
        	        AND
        	        filter_type_scope.code_filter_type = 'SCOPE'
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
        	);
    """
    )
    # For roles which are groups with at least one user associated that have a scope restriction
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
                    ON perm_object_all.id_role = role_groupe.id_role,
                JOIN gn_permissions.t_filters filter_scope_group 
                    ON perm_object_all.id_filter = filter_scope_group.id_filter
            utilisateurs.t_roles user_other
                JOIN utilisateurs.cor_roles association_group_other_user 
                    ON user_other.id_role = association_group_other_user.id_role_utilisateur
                    AND perm_object_all.id_role = association_group_other_user.id_role_groupe
                    AND user_other.id_role != id_user_with_restriction,
        WHERE
        	object_all.code_object = 'ALL'
        	AND
        	object_other.code_object != 'ALL'
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
                        ON restriction_perms_exists.id_filter = filter_scope_user.id_filter
        	        JOIN gn_permissions.bib_filters_type filter_type_scope
        	            ON filter_scope_user.id_filter_type = filter_type_scope.id_filter_type
                WHERE
        	        restriction_perms_exists.id_action = perm_object_all.id_action
        	        AND
        	        restriction_perms_exists.id_module = perm_object_all.id_module
        	        AND
        	        restriction_perms_exists.id_object = object_other.id_object
        	        AND
        	        filter_type_scope.code_filter_type = 'SCOPE'
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
        		perm_exists.id_role = user_other.id_role
        		AND 
        		perm_exists.id_action = perm_object_all.id_action
        		AND 
        		perm_exists.id_module = perm_object_all.id_module
        		AND 
        		perm_exists.id_object = object_other.id_object
        	);
    """
    )

    # Remove scope '0'
    op.execute(
        """
        DELETE FROM
            gn_permissions.cor_role_action_filter_module_object p
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
                    f.value_filter = '0'
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
            value_filter = '0'
        """
    )


def downgrade():
    """
    Restore permissions from backup table
    """
    op.execute("DELETE FROM gn_permissions.cor_role_action_filter_module_object")
    op.execute(
        """
        INSERT INTO gn_permissions.cor_role_action_filter_module_object (id_role, id_action, id_module, id_object, id_filter)
        SELECT id_role, id_action, id_module, id_object, id_filter
        FROM gn_permissions.backup_cor_role_action_filter_module_object
        """
    )
    op.drop_table(
        schema="gn_permissions", table_name="backup_cor_role_action_filter_module_object"
    )
