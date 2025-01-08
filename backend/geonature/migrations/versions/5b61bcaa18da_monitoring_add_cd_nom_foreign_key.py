"""[monitoring] Add cd_nom foreign key

Revision ID: 5b61bcaa18da
Revises: 2894b3c03c66
Create Date: 2025-01-07 14:28:20.475116

"""

from alembic import op
import sqlalchemy as sa


# revision identifiers, used by Alembic.
revision = "5b61bcaa18da"
down_revision = "2894b3c03c66"
branch_labels = None
depends_on = None


def upgrade():
    # Création clé étrangère sur la table t_observations
    op.create_foreign_key(
        "fk_t_observations_cd_nom_fkey",
        source_schema="gn_monitoring",
        source_table="t_observations",
        local_cols=["cd_nom"],
        referent_schema="taxonomie",
        referent_table="taxref",
        remote_cols=["cd_nom"],
        onupdate=None,
        ondelete=None,
    )


def downgrade():
    op.drop_constraint(
        "fk_t_observations_cd_nom_fkey",
        table_name="t_observations",
        schema="gn_monitoring",
    )
