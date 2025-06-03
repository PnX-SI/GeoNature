"""add tasks table

Revision ID: 67b70584ade0
Revises: 707390c722fe
Create Date: 2025-06-03 09:44:22.628841

"""

from alembic import op
import sqlalchemy as sa


# revision identifiers, used by Alembic.
revision = "67b70584ade0"
down_revision = "707390c722fe"
branch_labels = None
depends_on = None


def upgrade():
    op.create_table(
        "t_tasks",
        sa.Column("id_task", sa.Integer, primary_key=True),
        sa.Column(
            "id_role", sa.Integer, sa.ForeignKey("utilisateurs.t_roles.id_role"), nullable=False
        ),
        sa.Column(
            "id_module", sa.Integer, sa.ForeignKey("gn_commons.t_modules.id_module"), nullable=False
        ),
        sa.Column("start", sa.DateTime, nullable=False),
        sa.Column("end", sa.DateTime),
        sa.Column("status", sa.Unicode(50)),
        sa.Column("message", sa.Text, nullable=False),
        schema="gn_commons",
    )


def downgrade():
    op.drop_table("t_tasks", schema="gn_commons")
