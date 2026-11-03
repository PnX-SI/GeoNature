"""[notifications] delete notifications and rules with their role

Revision ID: 72faf6332526
Revises: 78c7e705efd3
Create Date: 2026-10-23 18:08:25.410258

"""

from alembic import op
import sqlalchemy as sa

# revision identifiers, used by Alembic.
revision = "72faf6332526"
down_revision = "78c7e705efd3"
branch_labels = None
depends_on = None


def replace_constraints(ondelete=None):
    for table in ("t_notifications", "t_notifications_rules"):
        op.drop_constraint(
            f"{table}_id_role_fkey",
            table_name=table,
            schema="gn_notifications",
        )
        op.create_foreign_key(
            f"{table}_id_role_fkey",
            source_schema="gn_notifications",
            source_table=table,
            local_cols=["id_role"],
            referent_schema="utilisateurs",
            referent_table="t_roles",
            remote_cols=["id_role"],
            ondelete=ondelete,
        )


def upgrade():
    replace_constraints(ondelete="CASCADE")


def downgrade():
    replace_constraints()
