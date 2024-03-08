"""add missing update permission for those that had installed 2.2.0 or 2.2.1 versions

Revision ID: d6bf8eaf088c
Revises: 8611f7aab8dc
Create Date: 2023-09-18 11:29:42.145359

"""

from alembic import op
import sqlalchemy as sa


# revision identifiers, used by Alembic.
revision = "d6bf8eaf088c"
down_revision = "8611f7aab8dc"
branch_labels = None
depends_on = None


def upgrade():
    op.execute(
        """
        INSERT INTO
            gn_permissions.t_permissions_available (
                id_module,
                id_object,
                id_action,
                label,
                scope_filter
            )
        SELECT
            m.id_module,
            o.id_object,
            a.id_action,
            v.label,
            v.scope_filter
        FROM
            (
                VALUES
                    ('IMPORT', 'IMPORT', 'U', True, 'Modifier des imports')
            ) AS v (module_code, object_code, action_code, scope_filter, label)
        JOIN
            gn_commons.t_modules m ON m.module_code = v.module_code
        JOIN
            gn_permissions.t_objects o ON o.code_object = v.object_code
        JOIN
            gn_permissions.bib_actions a ON a.code_action = v.action_code
        WHERE
            NOT EXISTS (
                SELECT 
                    label 
                FROM 
                    gn_permissions.t_permissions_available av
                WHERE 
                    av.id_module = m.id_module AND
                    av.id_object = o.id_object AND
                    av.id_action = a.id_action
            );
        """
    )


def downgrade():
    pass
