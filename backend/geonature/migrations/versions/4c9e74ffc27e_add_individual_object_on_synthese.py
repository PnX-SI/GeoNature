"""add individual object on synthese

Revision ID: 4c9e74ffc27e
Revises: ad8b797d89c0
Create Date: 2026-08-03 17:34:14.664376

"""

from alembic import op
import sqlalchemy as sa

# revision identifiers, used by Alembic.
revision = "4c9e74ffc27e"
down_revision = "ad8b797d89c0"
branch_labels = None
depends_on = None


def upgrade():
    op.execute("""
        INSERT INTO gn_permissions.cor_object_module(id_module, id_object)
        VALUES (
            (SELECT id_module FROM gn_commons.t_modules WHERE module_code = 'SYNTHESE'),
            (SELECT id_object FROM gn_permissions.t_objects WHERE code_object = 'INDIVIDUALS')
        )
        """)


def downgrade():
    op.execute("""
        DELETE FROM gn_permissions.cor_object_module
        WHERE id_module = (SELECT id_module FROM gn_commons.t_modules WHERE module_code = 'SYNTHESE')
        AND id_object = (SELECT id_object FROM gn_permissions.t_objects WHERE code_object = 'INDIVIDUALS')
        """)
