"""delete v_releve_list

Revision ID: 4d4e4b7350fe
Revises: b66d30f4e3d1
Create Date: 2026-03-11 11:10:12.342311

"""

from alembic import op
import sqlalchemy as sa

# revision identifiers, used by Alembic.
revision = "4d4e4b7350fe"
down_revision = "b66d30f4e3d1"
branch_labels = None
depends_on = None


def upgrade():
    op.execute("DROP VIEW IF EXISTS pr_occtax.v_releve_list;")


def downgrade():
    print(
        "If you had the view 'v_releve_list', it cannot be restored automatically and is not used anywhere. "
        "This downgrade do nothing."
    )
