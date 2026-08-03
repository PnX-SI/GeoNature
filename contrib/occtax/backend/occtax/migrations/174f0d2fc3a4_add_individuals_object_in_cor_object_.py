"""add individuals object in cor_object_module

Revision ID: 174f0d2fc3a4
Revises: b089ac1a2973
Create Date: 2026-08-03 17:03:55.440507

"""
from alembic import op
import sqlalchemy as sa


# revision identifiers, used by Alembic.
revision = '174f0d2fc3a4'
down_revision = 'b089ac1a2973'
branch_labels = None
depends_on = 'ad8b797d89c0'


def upgrade():
    op.execute(
        """
        INSERT INTO gn_permissions.cor_object_module(id_module, id_object)
        VALUES (
            (SELECT id_module FROM gn_commons.t_modules WHERE module_code = 'OCCTAX'),
            (SELECT id_object FROM gn_permissions.t_objects WHERE code_object = 'INDIVIDUALS')
        )
        """
    )


def downgrade():
    op.execute(
        """
        DELETE FROM gn_permissions.cor_object_module
        WHERE id_module = (SELECT id_module FROM gn_commons.t_modules WHERE module_code = 'OCCTAX')
        AND id_object = (SELECT id_object FROM gn_permissions.t_objects WHERE code_object = 'INDIVIDUALS')
        """
    )
