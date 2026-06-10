"""[import] add foreign key to gn_synthese.synthese.id_import

Revision ID: a90fa0630ef5
Revises: c3db57568f88
Create Date: 2026-04-08 13:13:43.839359

"""

from alembic import op
import sqlalchemy as sa

# revision identifiers, used by Alembic.
revision = "a90fa0630ef5"
down_revision = "c3db57568f88"
branch_labels = None
depends_on = None


def upgrade():
    op.create_foreign_key(
        "fk_gn_synthese_id_import",
        "synthese",
        "t_imports",
        ["id_import"],
        ["id_import"],
        ondelete="SET NULL",
        source_schema="gn_synthese",
        referent_schema="gn_imports",
    )


def downgrade():
    op.drop_constraint(
        "fk_gn_synthese_id_import", "synthese", type_="foreignkey", schema="gn_synthese"
    )
