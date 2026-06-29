"""add fk to t_habitats cd_hab

Revision ID: 53e6505aaaa9
Revises: 6f0ac37e9bc4
Create Date: 2026-06-28 19:16:58.760718

"""
from alembic import op
import sqlalchemy as sa


# revision identifiers, used by Alembic.
revision = '53e6505aaaa9'
down_revision = '6f0ac37e9bc4'
branch_labels = None
depends_on = None


def upgrade():
    op.create_foreign_key(
        "fk_t_habitats_cd_hab",
        "t_habitats",
        "habref",
        ["cd_hab"],
        ["cd_hab"],
        source_schema="pr_occhab",
        referent_schema="ref_habitats",
        onupdate="CASCADE",
    )


def downgrade():
    op.drop_constraint(
        "fk_t_habitats_cd_hab",
        "t_habitats",
        schema="pr_occhab",
        type_="foreignkey",
    )
