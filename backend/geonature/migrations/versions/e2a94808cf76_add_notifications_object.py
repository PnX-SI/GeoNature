"""add notifications object

Revision ID: e2a94808cf76
Revises: cf1c1fdbde77
Create Date: 2023-04-14 18:16:57.981499

"""
from alembic import op
import sqlalchemy as sa


# revision identifiers, used by Alembic.
revision = "e2a94808cf76"
down_revision = "cf1c1fdbde77"
branch_labels = None
depends_on = None


def upgrade():
    op.execute(
        """
        INSERT INTO
            gn_permissions.t_objects (code_object, description_object)
        VALUES (
            'NOTIFICATIONS',
            'Gestion du backoffice des notifications'
        )
        """
    )
    op.execute(
        """
        INSERT INTO
            gn_permissions.cor_object_module (id_object, id_module)
        VALUES (
            (SELECT id_object FROM gn_permissions.t_objects WHERE code_object = 'NOTIFICATIONS'),
            (SELECT id_module FROM gn_commons.t_modules WHERE module_code = 'ADMIN')
        )
        """
    )


def downgrade():
    op.execute("DELETE FROM gn_permissions.t_objects WHERE code_object = 'NOTIFICATIONS'")
