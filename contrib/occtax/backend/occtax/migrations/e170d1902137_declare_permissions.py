"""declare permissions

Revision ID: e170d1902137
Revises: 1b4f44762020
Create Date: 2023-05-16 09:55:41.005029

"""

from alembic import op
import sqlalchemy as sa


# revision identifiers, used by Alembic.
revision = "e170d1902137"
down_revision = "1b4f44762020"
branch_labels = None
depends_on = ("f051b88a57fd",)


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
                     ('OCCTAX', 'ALL', 'C', True, 'Créer des relevés')
                    ,('OCCTAX', 'ALL', 'R', True, 'Voir les relevés')
                    ,('OCCTAX', 'ALL', 'U', True, 'Modifier les relevés')
                    ,('OCCTAX', 'ALL', 'E', True, 'Exporter les relevés')
                    ,('OCCTAX', 'ALL', 'D', True, 'Supprimer des relevés')
            ) AS v (module_code, object_code, action_code, scope_filter, label)
        JOIN
            gn_commons.t_modules m ON m.module_code = v.module_code
        JOIN
            gn_permissions.t_objects o ON o.code_object = v.object_code
        JOIN
            gn_permissions.bib_actions a ON a.code_action = v.action_code
        """
    )
    op.execute(
        """
        WITH bad_permissions AS (
            SELECT
                p.id_permission
            FROM
                gn_permissions.t_permissions p
            JOIN gn_commons.t_modules m
                    USING (id_module)
            WHERE
                m.module_code = 'OCCTAX'
            EXCEPT
            SELECT
                p.id_permission
            FROM
                gn_permissions.t_permissions p
            JOIN gn_permissions.t_permissions_available pa ON
                (p.id_module = pa.id_module
                    AND p.id_object = pa.id_object
                    AND p.id_action = pa.id_action)
        )
        DELETE
        FROM
            gn_permissions.t_permissions p
                USING bad_permissions bp
        WHERE
            bp.id_permission = p.id_permission;
        """
    )


def downgrade():
    op.execute(
        """
        DELETE FROM
            gn_permissions.t_permissions_available pa
        USING
            gn_commons.t_modules m
        WHERE
            pa.id_module = m.id_module
            AND
            module_code = 'OCCTAX'
        """
    )
