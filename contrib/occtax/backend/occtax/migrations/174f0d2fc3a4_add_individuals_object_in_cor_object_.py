"""add individuals object in cor_object_module

Revision ID: 174f0d2fc3a4
Revises: b089ac1a2973
Create Date: 2026-08-03 17:03:55.440507

"""

from alembic import op
import sqlalchemy as sa

# revision identifiers, used by Alembic.
revision = "174f0d2fc3a4"
down_revision = "b089ac1a2973"
branch_labels = None
depends_on = "ad8b797d89c0"


def upgrade():
    op.execute("""
        INSERT INTO gn_permissions.cor_object_module(id_module, id_object)
        VALUES (
            (SELECT id_module FROM gn_commons.t_modules WHERE module_code = 'OCCTAX'),
            (SELECT id_object FROM gn_permissions.t_objects WHERE code_object = 'INDIVIDUALS')
        )
        """)

    op.execute(
        """ 
        -- Insert available permissions "R" for INDIVIDUALS object
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
            ('OCCTAX', 'INDIVIDUALS', 'R', True, 'Consulter les individus')
        ) AS v (module_code, object_code, action_code, scope_filter, label)
        JOIN gn_commons.t_modules m ON m.module_code = v.module_code
        JOIN gn_permissions.t_objects o ON o.code_object = v.object_code
        JOIN gn_permissions.bib_actions a ON a.code_action = v.action_code;
        """
    )


def downgrade():
    op.execute("""
        DELETE FROM gn_permissions.cor_object_module
        WHERE id_module = (SELECT id_module FROM gn_commons.t_modules WHERE module_code = 'OCCTAX')
        AND id_object = (SELECT id_object FROM gn_permissions.t_objects WHERE code_object = 'INDIVIDUALS')
        """)

    op.execute(
        """         
        -- Remove "R" available permission for OCCTAX module and INDIVIDUALS object
        DELETE FROM gn_permissions.t_permissions_available 
        WHERE id_module = (SELECT id_module FROM gn_commons.t_modules WHERE module_code = 'OCCTAX')
        AND id_object = (SELECT id_object FROM gn_permissions.t_objects WHERE code_object = 'INDIVIDUALS')
        AND id_action = (SELECT id_action FROM gn_permissions.bib_actions WHERE code_action = 'R');
        """
    )
