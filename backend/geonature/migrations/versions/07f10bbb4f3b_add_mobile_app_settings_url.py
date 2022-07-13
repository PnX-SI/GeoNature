"""add mobile app settings url

Revision ID: 07f10bbb4f3b
Revises: f4ffdc68072c
Create Date: 2022-07-13 12:34:42.450453

"""
from alembic import op
import sqlalchemy as sa


# revision identifiers, used by Alembic.
revision = "07f10bbb4f3b"
down_revision = "f4ffdc68072c"
branch_labels = None
depends_on = None


def upgrade():
    op.add_column(
        schema="gn_commons",
        table_name="t_mobile_apps",
        column=sa.Column(
            "url_settings",
            sa.Unicode,
        ),
    )


def downgrade():
    op.drop_column(
        schema="gn_commons",
        table_name="t_mobile_apps",
        column_name="url_settings",
    )
