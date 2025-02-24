"""add index on id_import on occhab station and habitat

Revision ID: b4e1e402ece1
Revises: 9c3e1f98361f
Create Date: 2025-02-24 17:14:30.833647

"""

from alembic import op
import sqlalchemy as sa


# revision identifiers, used by Alembic.
revision = "b4e1e402ece1"
down_revision = "9c3e1f98361f"
branch_labels = None
depends_on = None


def upgrade():
    op.create_index(
        "occhab_station_id_import_idx",
        "t_stations",
        ["id_import"],
        schema="pr_occhab",
    )
    op.create_index(
        "occhab_habitat_id_import_idx",
        "t_habitats",
        ["id_import"],
        schema="pr_occhab",
    )


def downgrade():
    op.drop_index(
        "occhab_habitat_id_import_idx",
        table_name="t_habitats",
        schema="pr_occhab",
    )
    op.drop_index(
        "occhab_station_id_import_idx",
        table_name="t_stations",
        schema="pr_occhab",
    )
