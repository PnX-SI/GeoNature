"""set not null on t_releves_occtax.id_module

Revision ID: df088920b2f3
Revises: 61802a0f83b8
Create Date: 2022-12-05 10:44:39.166886

"""
from alembic import op
import sqlalchemy as sa


# revision identifiers, used by Alembic.
revision = "df088920b2f3"
down_revision = "61802a0f83b8"
branch_labels = None
depends_on = None


def upgrade():
    op.execute(
        """
        UPDATE
            pr_occtax.t_releves_occtax
        SET
            id_module = (SELECT id_module FROM gn_commons.t_modules WHERE module_code = 'OCCTAX')
        """
    )
    op.alter_column(
        table_name="t_releves_occtax",
        column_name="id_module",
        nullable=False,
        schema="pr_occtax",
    )


def downgrade():
    op.alter_column(
        table_name="t_releves_occtax",
        column_name="id_module",
        nullable=True,
        schema="pr_occtax",
    )
