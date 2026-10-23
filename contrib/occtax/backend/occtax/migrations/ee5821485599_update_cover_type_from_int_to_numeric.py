"""Update cover type from int to numeric

Revision ID: ee5821485599
Revises: 1654fd13b10f
Create Date: 2026-10-23 09:20:14.830488

"""

from alembic import op
import sqlalchemy as sa

# revision identifiers, used by Alembic.
revision = "ee5821485599"
down_revision = "1654fd13b10f"
branch_labels = None
depends_on = None


def upgrade():
    schema = "pr_occtax"
    op.alter_column(
        "t_vegetation_stratum",
        "percentage_cover_vegetation_stratum",
        existing_type=sa.Integer(),
        type_=sa.Numeric(5, 2),
        existing_nullable=True,
        schema=schema,
    )


def downgrade():
    schema = "pr_occtax"
    op.alter_column(
        "t_vegetation_stratum",
        "percentage_cover_vegetation_stratum",
        existing_type=sa.Numeric(5, 2),
        type_=sa.Integer(),
        existing_nullable=True,
        schema=schema,
    )
