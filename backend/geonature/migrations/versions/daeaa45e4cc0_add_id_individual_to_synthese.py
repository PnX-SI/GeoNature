"""add id_individual to synthese

Revision ID: daeaa45e4cc0
Revises: 1f223c509a80
Create Date: 2026-06-22 00:00:00.000000

"""

from alembic import op
import sqlalchemy as sa

# revision identifiers, used by Alembic.
revision = "daeaa45e4cc0"
down_revision = "1f223c509a80"
branch_labels = None
depends_on = None


def upgrade():
    op.add_column(
        "synthese",
        sa.Column(
            "id_individual",
            sa.Integer(),
            sa.ForeignKey(
                "gn_monitoring.t_individuals.id_individual",
                name="fk_synthese_id_individual",
                onupdate="CASCADE",
                ondelete="SET NULL",
            ),
            nullable=True,
        ),
        schema="gn_synthese",
    )


def downgrade():
    op.drop_column("synthese", "id_individual", schema="gn_synthese")
