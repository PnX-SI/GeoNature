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
    with op.batch_alter_table(schema="gn_permissions", table_name="t_permissions") as batch_op:
        batch_op.add_column(
            column=sa.Column("created_on", sa.DateTime),
        )
        batch_op.add_column(
            column=sa.Column("expire_on", sa.DateTime),
        )
        batch_op.add_column(
            column=sa.Column("validated", sa.Boolean, server_default=sa.true()),
        )
    # We set server_default after column creation to initialialize existing rows with NULL value
    op.alter_column(
        schema="gn_permissions",
        table_name="t_permissions",
        column_name="created_on",
        server_default=sa.func.now(),
    )


def downgrade():
    with op.batch_alter_table(schema="gn_permissions", table_name="t_permissions") as batch_op:
        batch_op.drop_column(column_name="validated")
        batch_op.drop_column(column_name="created_on")
        batch_op.drop_column(column_name="expire_on")
