"""add trigger calculate altitude

Revision ID: cbcb5e464f4f
Revises: 65f77e9d4c6f
Create Date: 2025-04-08 14:58:28.337496

"""

from alembic import op
import sqlalchemy as sa


# revision identifiers, used by Alembic.
revision = "cbcb5e464f4f"
down_revision = "65f77e9d4c6f"
branch_labels = None
depends_on = None


def upgrade():
    op.execute(
        """
    create trigger "tri_t_stations_calculate_altitude" before
    insert or update 
    on
    pr_occhab.t_stations for each row execute function ref_geo.fct_trg_calculate_alt_minmax('geom_4326')
    """
    )


def downgrade():
    """
    drop if exists trigger "tri_t_stations_calculate_altitude";
    """
