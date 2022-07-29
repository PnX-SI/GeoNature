"""add id_module in t_sources

Revision ID: f4ffdc68072c
Revises: 3902129a52b3
Create Date: 2022-04-27 13:42:51.851067

"""
from alembic import op
import sqlalchemy as sa


# revision identifiers, used by Alembic.
revision = "f4ffdc68072c"
down_revision = "6070edb31013"
branch_labels = None
depends_on = None


def upgrade():
    op.add_column(
        schema="gn_synthese",
        table_name="t_sources",
        column=sa.Column(
            "id_module",
            sa.Integer,
            sa.ForeignKey("gn_commons.t_modules.id_module"),
        ),
    )


def downgrade():
    op.drop_column(
        schema="gn_synthese",
        table_name="t_sources",
        column_name="id_module",
    )
