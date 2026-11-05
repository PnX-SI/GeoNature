"""Add INDIVIDUALS permissions for phyto module

Revision ID: 1654fd13b10f
Revises: ef4e7d03fbfc
Create Date: 2026-10-08 16:15:29.550573

"""

from alembic import op
import sqlalchemy as sa

# revision identifiers, used by Alembic.
revision = "1654fd13b10f"
down_revision = "ef4e7d03fbfc"
branch_labels = None
depends_on = None


def upgrade():
    op.execute(sa.text("""
                    INSERT INTO gn_permissions.t_permissions_available (
                        id_module, id_object, id_action, label, scope_filter
                    )
                    SELECT
                        m.id_module, o.id_object, a.id_action, v.label, v.scope_filter
                    FROM (
                        VALUES
                            ('PHYTO', 'INDIVIDUALS', 'C', True, 'Créer des individus'),
                            ('PHYTO', 'INDIVIDUALS', 'R', True, 'Voir les individus')
                    ) AS v (module_code, object_code, action_code, scope_filter, label)
                    JOIN gn_commons.t_modules m ON m.module_code = v.module_code
                    JOIN gn_permissions.t_objects o ON o.code_object = v.object_code
                    JOIN gn_permissions.bib_actions a ON a.code_action = v.action_code;
    """))


def downgrade():
    op.execute(sa.text("""
                    DELETE FROM gn_permissions.t_permissions_available
                    WHERE id_module = gn_commons.get_id_module_bycode('PHYTO');
        """))
