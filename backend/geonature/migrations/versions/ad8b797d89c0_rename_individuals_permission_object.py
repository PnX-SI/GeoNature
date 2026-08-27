"""[individual] rename INDIVIDUALS permission object

Revision ID: ad8b797d89c0
Revises: daeaa45e4cc0
Create Date: 2026-08-03 16:48:34.776634

"""

from alembic import op
import sqlalchemy as sa

# revision identifiers, used by Alembic.
revision = "ad8b797d89c0"
down_revision = "f3a8e2b1c904"
branch_labels = None
depends_on = None


def upgrade():
    op.execute("""
        UPDATE gn_permissions.t_objects
        SET code_object = 'INDIVIDUALS'
        WHERE code_object = 'MONITORINGS_INDIVIDUALS';
    """)
    op.execute("""
        INSERT INTO gn_permissions.t_objects (code_object, description_object)
        SELECT 'INDIVIDUALS', 'Gestion des individus'
        WHERE NOT EXISTS (
            SELECT 1 FROM gn_permissions.t_objects WHERE code_object = 'INDIVIDUALS'
        );
    """)


def downgrade():
    op.execute("""
        UPDATE gn_permissions.t_objects
        SET code_object = 'MONITORINGS_INDIVIDUALS'
        WHERE code_object = 'INDIVIDUALS';
    """)
