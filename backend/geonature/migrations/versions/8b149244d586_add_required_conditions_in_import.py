"""add required conditions in import

Revision ID: 8b149244d586
Revises: fe3d0b49ee14
Create Date: 2024-03-20 11:17:57.360785

"""

from alembic import op
import sqlalchemy as sa


# revision identifiers, used by Alembic.
revision = "8b149244d586"
down_revision = "fe3d0b49ee14"
branch_labels = None
depends_on = None


def upgrade():
    op.add_column(
        table_name="bib_fields",
        schema="gn_imports",
        column=sa.Column("mandatory_conditions", sa.ARRAY(sa.Unicode)),
    )
    op.add_column(
        table_name="bib_fields",
        schema="gn_imports",
        column=sa.Column("optional_conditions", sa.ARRAY(sa.Unicode)),
    )


def downgrade():
    op.drop_column(table_name="bib_fields", schema="gn_imports", column_name="mandatory_conditions")
    op.drop_column(table_name="bib_fields", schema="gn_imports", column_name="optional_conditions")
