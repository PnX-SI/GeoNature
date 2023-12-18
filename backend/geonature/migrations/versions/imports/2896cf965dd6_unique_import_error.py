"""unique import error

Revision ID: 2896cf965dd6
Revises: d6bf8eaf088c
Create Date: 2023-09-28 10:19:10.133530

"""
from alembic import op
import sqlalchemy as sa


# revision identifiers, used by Alembic.
revision = "2896cf965dd6"
down_revision = "ea67bf7b6888"
branch_labels = None
depends_on = None


def upgrade():
    op.create_unique_constraint(
        schema="gn_imports",
        table_name="t_user_errors",
        columns=["id_import", "id_error", "column_error"],
        constraint_name="t_user_errors_un",
    )


def downgrade():
    op.drop_constraint(
        schema="gn_imports", table_name="t_user_errors", constraint_name="t_user_errors_un"
    )
