"""add additional_data field on gn_meta tables

Revision ID: 26a5d314b886
Revises: 22cb0ffdff6d
Create Date: 2025-03-28 20:12:50.016630

"""
from alembic import op
import sqlalchemy as sa
from sqlalchemy.dialects.postgresql import JSONB



# revision identifiers, used by Alembic.
revision = '26a5d314b886'
down_revision = '22cb0ffdff6d'
branch_labels = None
depends_on = None


def upgrade():
    op.add_column(
        "t_datasets",
        sa.Column("additional_data", JSONB, server_default="{}"),
        schema="gn_meta",
    )
    op.add_column(
        "t_acquisition_frameworks",
        sa.Column("additional_data", JSONB, server_default="{}"),
        schema="gn_meta",
    )


def downgrade():
    op.drop_column("t_datasets", "additional_data", schema="gn_meta")
    op.drop_column("t_acquisition_frameworks", "additional_data", schema="gn_meta")

