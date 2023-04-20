"""add additional fields object

Revision ID: df5a5099e084
Revises: 0630b93bcfe0
Create Date: 2023-04-20 10:46:00.334251

"""
from alembic import op
import sqlalchemy as sa


# revision identifiers, used by Alembic.
revision = "df5a5099e084"
down_revision = "e2a94808cf76"
branch_labels = None
depends_on = None


def upgrade():
    op.execute(
        """
        INSERT INTO
            gn_permissions.t_objects (code_object, description_object)
        VALUES (
            'ADDITIONAL_FIELDS',
            'Gestion du backoffice des champs additionnels'
        )
        """
    )
    op.execute(
        """
        INSERT INTO
            gn_permissions.cor_object_module (id_object, id_module)
        VALUES (
            (SELECT id_object FROM gn_permissions.t_objects WHERE code_object = 'ADDITIONAL_FIELDS'),
            (SELECT id_module FROM gn_commons.t_modules WHERE module_code = 'ADMIN')
        )
        """
    )


def downgrade():
    op.execute("DELETE FROM gn_permissions.t_objects WHERE code_object = 'ADDITIONAL_FIELDS'")
