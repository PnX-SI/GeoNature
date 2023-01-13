"""Default notification rules

Revision ID: 09a637f06b96
Revises: 4cf3fd5d06f5
Create Date: 2023-01-13 09:55:53.525869

"""
from alembic import op
import sqlalchemy as sa


# revision identifiers, used by Alembic.
revision = "09a637f06b96"
down_revision = "4cf3fd5d06f5"
branch_labels = None
depends_on = None


def upgrade():
    # Allows NULL id_role to define default rules
    op.alter_column(
        schema="gn_notifications",
        table_name="t_notifications_rules",
        column_name="id_role",
        nullable=True,
    )
    # Create partial index on (code_method, code_category) where id_role IS NULL.
    # This allows to create only one default rule for each method / category couple.
    op.create_index(
        schema="gn_notifications",
        table_name="t_notifications_rules",
        index_name="un_method_category",
        columns=["code_method", "code_category"],
        postgresql_where=sa.text("id_role IS NULL"),
    )
    op.add_column(
        schema="gn_notifications",
        table_name="t_notifications_rules",
        column=sa.Column("subscribed", sa.Boolean, nullable=False, server_default=sa.true()),
    )


def downgrade():
    op.drop_column(
        schema="gn_notifications",
        table_name="t_notifications_rules",
        column_name="subscribed",
    )
    op.drop_index(
        schema="gn_notifications",
        table_name="t_notifications_rules",
        index_name="un_method_category",
    )
    op.alter_column(
        schema="gn_notifications",
        table_name="t_notifications_rules",
        column_name="id_role",
        nullable=False,
    )
