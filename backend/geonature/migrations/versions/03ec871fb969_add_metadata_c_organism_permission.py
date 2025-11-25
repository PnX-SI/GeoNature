"""add metadata c organism permission

Revision ID: 03ec871fb969
Revises: 09a637f06b96
Create Date: 2025-11-25 15:17:56

"""

from alembic import op
import sqlalchemy as sa


# revision identifiers, used by Alembic.
revision = "03ec871fb969"
down_revision = "cad98c048b5e"
branch_labels = None
depends_on = None


def upgrade():
    op.get_bind().execute(
        sa.text(
            """
        -- Insert ORGANISM object into t_objects
        INSERT INTO gn_permissions.t_objects
        (code_object, description_object)
        VALUES
        ('ORGANISM', 'Gestion des organismes dans le module METADATA');

        -- Link ORGANISM object to METADATA module
        INSERT INTO gn_permissions.cor_object_module
        (id_object, id_module)
        SELECT 
            _to.id_object, 
            (SELECT id_module FROM gn_commons.t_modules WHERE module_code = 'METADATA')
        FROM (
            VALUES ('ORGANISM')
        ) AS o (object_code)
        JOIN gn_permissions.t_objects _to ON _to.code_object = o.object_code;

        -- Insert available permission "C" for ORGANISM object
        INSERT INTO gn_permissions.t_permissions_available (
            id_module,
            id_object,
            id_action,
            scope_filter,
            label
        )
        SELECT
            m.id_module,
            o.id_object,
            a.id_action,
            v.scope_filter,
            v.label
        FROM (
            VALUES
            ('METADATA', 'ORGANISM', 'C', False, 'Créer des organismes')
        ) AS v (module_code, object_code, action_code, scope_filter, label)
        JOIN gn_commons.t_modules m ON m.module_code = v.module_code
        JOIN gn_permissions.t_objects o ON o.code_object = v.object_code
        JOIN gn_permissions.bib_actions a ON a.code_action = v.action_code
        WHERE m.module_code = 'METADATA';
        """
        )
    )


def downgrade():
    op.execute(
        """
        -- Remove "C" permission for METADATA module and ORGANISM object
        DELETE FROM gn_permissions.t_permissions 
        WHERE id_module = (SELECT id_module FROM gn_commons.t_modules WHERE module_code = 'METADATA')
        AND id_object = (SELECT id_object FROM gn_permissions.t_objects WHERE code_object = 'ORGANISM')
        AND id_action = (SELECT id_action FROM gn_permissions.bib_actions WHERE code_action = 'C');
        
        -- Remove "C" available permission for METADATA module and ORGANISM object
        DELETE FROM gn_permissions.t_permissions_available 
        WHERE id_module = (SELECT id_module FROM gn_commons.t_modules WHERE module_code = 'METADATA')
        AND id_object = (SELECT id_object FROM gn_permissions.t_objects WHERE code_object = 'ORGANISM')
        AND id_action = (SELECT id_action FROM gn_permissions.bib_actions WHERE code_action = 'C');
        
        -- Remove (METADAT, ORGANISM) from cor_object_module
        DELETE FROM gn_permissions.cor_object_module 
        WHERE id_module = (SELECT id_module FROM gn_commons.t_modules WHERE module_code = 'METADATA')
        AND id_object = (SELECT id_object FROM gn_permissions.t_objects WHERE code_object = 'ORGANISM');
        
        -- Remove ORGANISM object
        DELETE FROM gn_permissions.t_objects WHERE code_object = 'ORGANISM';
        """
    )
