"""bump dependencies

Revision ID: 7077aa76da3d
Revises: c0fdf2ee7f4f
Create Date: 2021-09-27 22:33:47.462525

"""
from alembic import op
import sqlalchemy as sa


# revision identifiers, used by Alembic.
revision = "7077aa76da3d"
down_revision = "c0fdf2ee7f4f"
branch_labels = None
depends_on = (
    "951b8270a1cf",  # utilisateurs
    "e0ac4c9f5c0a",  # ref_geo
    "4fb7e197d241",  # taxonomie
)


def upgrade():
    pass


def downgrade():
    pass
