"""[object] rename OCCTAX_OCCURENCE to OCCTAX_OCCURRENCE

Revision ID: 26f11ef2fe77
Revises: a22f59a3912c
Create Date: 2026-08-27 10:59:00.346923

"""

from alembic import op
import sqlalchemy as sa

# revision identifiers, used by Alembic.
revision = "26f11ef2fe77"
down_revision = "a22f59a3912c"
branch_labels = None
depends_on = None


def upgrade():
    op.execute(
        "UPDATE gn_permissions.t_objects SET code_object = 'OCCTAX_OCCURRENCE' WHERE code_object = 'OCCTAX_OCCURENCE'"
    )


def downgrade():
    op.execute(
        "UPDATE gn_permissions.t_objects SET code_object = 'OCCTAX_OCCURENCE' WHERE code_object = 'OCCTAX_OCCURRENCE'"
    )
