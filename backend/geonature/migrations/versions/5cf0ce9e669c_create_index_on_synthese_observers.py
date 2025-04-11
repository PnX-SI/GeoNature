"""create_index_on_synthese_observers

Revision ID: 5cf0ce9e669c
Revises: 9df933cc3c7a
Create Date: 2025-01-13 14:14:30.085725

"""

from alembic import op
import sqlalchemy as sa


# revision identifiers, used by Alembic.
revision = "5cf0ce9e669c"
down_revision = "9df933cc3c7a"
branch_labels = None
depends_on = None


def upgrade():
    op.create_index(
        "synthese_observers_idx",
        "synthese",
        ["observers"],
        if_not_exists=True,
        schema="gn_synthese",
    )


def downgrade():
    op.drop_index(
        "synthese_observers_idx",
        table_name="synthese",
        schema="gn_synthese",
    )
