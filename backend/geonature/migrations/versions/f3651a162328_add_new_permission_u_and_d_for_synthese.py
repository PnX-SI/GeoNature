"""add new permission U and D for synthese

Revision ID: f3651a162328
Revises: 707390c722fe
Create Date: 2025-06-03 19:00:30.541152

"""
from alembic import op
import sqlalchemy as sa


# revision identifiers, used by Alembic.
revision = 'f3651a162328'
down_revision = '707390c722fe'
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
                scope_filter,
                areas_filter,
                taxons_filter
            )
        SELECT
            m.id_module,
            o.id_object,
            a.id_action,
            v.label,
            v.scope_filter,
            v.areas_filter,
            v.taxons_filter
        FROM
            (
                VALUES
                     ('SYNTHESE', 'ALL', 'U', True, True, True, 'Modifier les observations')
                    ,('SYNTHESE', 'ALL', 'D', True, True, True, 'Supprimer les observations')
            ) AS v (module_code, object_code, action_code, scope_filter, areas_filter, taxons_filter, label)
        JOIN
            gn_commons.t_modules m ON m.module_code = v.module_code
        JOIN
            gn_permissions.t_objects o ON o.code_object = v.object_code
        JOIN
            gn_permissions.bib_actions a ON a.code_action = v.action_code
        """
    )

def downgrade():
    op.execute(
        """
        DELETE FROM gn_permissions.t_permissions_available
        WHERE id_action IN (
            SELECT a.id_action
            FROM
                (
                    VALUES
                         ('SYNTHESE', 'ALL', 'U')
                        ,('SYNTHESE', 'ALL', 'D')
                ) AS v (module_code, object_code, action_code)
            JOIN gn_commons.t_modules m ON m.module_code = v.module_code
            JOIN gn_permissions.t_objects o ON o.code_object = v.object_code
            JOIN gn_permissions.bib_actions a ON a.code_action = v.action_code
            WHERE
                gn_permissions.t_permissions_available.id_module = m.id_module AND
                gn_permissions.t_permissions_available.id_object = o.id_object AND
                gn_permissions.t_permissions_available.id_action = a.id_action
        )
        """
    )