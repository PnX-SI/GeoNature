"""add sensitivity filter export synthese

Revision ID: 5a2c9c65129f
Revises: 446e902a14e7
Create Date: 2023-08-08 16:23:53.059110

"""
from alembic import op
import sqlalchemy as sa


# revision identifiers, used by Alembic.
revision = "5a2c9c65129f"
down_revision = "d99a7c22cc3c"
branch_labels = None
depends_on = None


def upgrade():
    op.execute(
        """
        UPDATE
            gn_permissions.t_permissions_available pa
        SET
            sensitivity_filter = True
        FROM
            gn_commons.t_modules m,
            gn_permissions.t_objects o,
            gn_permissions.bib_actions a
        WHERE
            pa.id_module = m.id_module
            AND
            pa.id_object = o.id_object
            AND
            pa.id_action = a.id_action
            AND
            m.module_code = 'SYNTHESE' AND o.code_object = 'ALL' and a.code_action = 'E'
        """
    )


def downgrade():
    op.execute(
        """
        UPDATE
            gn_permissions.t_permissions_available pa
        SET
            sensitivity_filter = False
        FROM
            gn_commons.t_modules m,
            gn_permissions.t_objects o,
            gn_permissions.bib_actions a
        WHERE
            pa.id_module = m.id_module
            AND
            pa.id_object = o.id_object
            AND
            pa.id_action = a.id_action
            AND
            m.module_code = 'SYNTHESE' AND o.code_object = 'ALL' and a.code_action = 'E'
        """
    )
