"""[permissions] add label to objects

Revision ID: 65d922a77eb5
Revises: f6a1feb3f297
Create Date: 2026-06-10 12:58:44.981868

"""

from alembic import op
import sqlalchemy as sa

# revision identifiers, used by Alembic.
revision = "65d922a77eb5"
down_revision = "f6a1feb3f297"
branch_labels = None
depends_on = None


def upgrade():
    op.add_column(
        "t_objects",
        sa.Column("label_object", sa.Unicode(50)),
        schema="gn_permissions",
    )


def downgrade():
    op.drop_column(
        "t_objects",
        "label_object",
        schema="gn_permissions",
    )
