"""permissions: add extended filters

Revision ID: 707390c722fe
Revises: 4e6ce32305f0
Create Date: 2024-09-30 17:13:44.650757

"""

from alembic import op
import sqlalchemy as sa


# revision identifiers, used by Alembic.
revision = "707390c722fe"
down_revision = "4e6ce32305f0"
branch_labels = None
depends_on = None


def upgrade():
    op.add_column(
        schema="gn_permissions",
        table_name="t_permissions",
        column=sa.Column("expire_on", sa.DateTime),
    )


def downgrade():
    op.drop_column(
        schema="gn_permissions",
        table_name="t_permissions",
        column_name="expire_on",
    )
