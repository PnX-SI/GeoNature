"""set not-null on synthese.id_source

Revision ID: 4cf3fd5d06f5
Revises: 36d0bd313a47
Create Date: 2022-12-05 14:46:04.206294

"""
from alembic import op
import sqlalchemy as sa


# revision identifiers, used by Alembic.
revision = "4cf3fd5d06f5"
down_revision = "36d0bd313a47"
branch_labels = None
depends_on = None


def upgrade():
    op.alter_column(
        table_name="synthese",
        column_name="id_source",
        nullable=False,
        schema="gn_synthese",
    )


def downgrade():
    op.alter_column(
        table_name="synthese",
        column_name="id_source",
        nullable=True,
        schema="gn_synthese",
    )
