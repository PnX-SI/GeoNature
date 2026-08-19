"""[production database] add new permissions

Revision ID: 103ea033e21d
Revises: 21fe37188895
Create Date: 2026-08-19 11:40:12.510291

"""

from alembic import op
import sqlalchemy as sa

# revision identifiers, used by Alembic.
revision = "103ea033e21d"
down_revision = "21fe37188895"
branch_labels = None
depends_on = None


def upgrade():
    op.execute("""
            INSERT INTO gn_permissions.t_objects (code_object, description_object)
            VALUES (
                'PRODUCTION_DATABASE',
                'Base de données de production'
            )
        """)
    op.execute("""
            INSERT INTO gn_permissions.cor_object_module
                (id_object, id_module)
            VALUES(
                (SELECT id_object FROM gn_permissions.t_objects WHERE code_object = 'PRODUCTION_DATABASE'),
                (SELECT id_module FROM gn_commons.t_modules WHERE module_code = 'METADATA')
            )
        """)
    op.execute("""
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
                    ('METADATA', 'PRODUCTION_DATABASE', 'C', False, 'Créer une base de production')
                    ,('METADATA', 'PRODUCTION_DATABASE', 'U', False, 'Modifier une base de production')
                    ,('METADATA', 'PRODUCTION_DATABASE', 'D', False, 'Supprimer une base de production')
            ) AS v (module_code, object_code, action_code, scope_filter, label)
        JOIN
            gn_commons.t_modules m ON m.module_code = v.module_code
        JOIN
            gn_permissions.t_objects o ON o.code_object = v.object_code
        JOIN
            gn_permissions.bib_actions a ON a.code_action = v.action_code
        """)


def downgrade():
    op.execute("""
        DELETE FROM
            gn_permissions.t_permissions_available pa
        USING
            gn_commons.t_modules m
        WHERE
            pa.id_module = m.id_module
            AND
            module_code = 'PRODUCTION_DATABASE'
        """)
    op.execute("""
        DELETE FROM
            gn_permissions.t_permissions p
        USING
            gn_commons.t_modules m,
            gn_permissions.t_objects o
        WHERE
            p.id_module = m.id_module
            AND
            module_code = 'METADATA'
            AND
            p.id_object = o.id_object
            AND
            code_object = 'PRODUCTION_DATABASE'
        """)
    op.execute("DELETE FROM gn_permissions.t_objects WHERE code_object = 'PRODUCTION_DATABASE'")
