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
    Backup permissions in order to be able to downgrade
    """
    op.execute(
        """
        CREATE TABLE gn_permissions.backup_cor_role_action_filter_module_object
        AS TABLE gn_permissions.cor_role_action_filter_module_object
        """
    )

    """
    Inherit permissions (id_role, id_action, id_filter, _ , id_object) from module GN to other modules
    when a permission (id_role, id_action, _ , _ , id_object) is not already specified for the other module.
    """
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
        JOIN gn_commons.t_modules module_gn ON
        	perm_gn.id_module = module_gn.id_module
        WHERE
        	module_gn.module_code = 'GEONATURE'
        	AND 
        	module_other.module_code != 'GEONATURE'
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

    """
    Inherit permissions (id_role, id_action, id_filter, id_module, id_object("ALL")) from object ALL to other objects
    when the other object is associated to the module id_module in the `gn_permissions.cor_object_module`
    and when a permission (id_role, id_action, _ , id_module, _ ) is not already specified for the other object.
    """
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
        JOIN
            gn_permissions.t_objects object_all ON perm_object_all.id_object = object_all.id_object
        JOIN
            gn_permissions.cor_object_module cor_object_module ON cor_object_module.id_module = perm_object_all.id_module
        JOIN
            gn_permissions.t_objects object_other ON object_other.id_object = cor_object_module.id_object
        WHERE
        	object_all.code_object = 'ALL'
        	AND
        	object_other.code_object != 'ALL'
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
