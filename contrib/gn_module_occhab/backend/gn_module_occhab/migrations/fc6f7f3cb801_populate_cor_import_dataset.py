"""[import] populate cor_import_datasets

Revision ID: fc6f7f3cb801
Revises: 6f0ac37e9bc4
Create Date: 2026-05-05 14:50:03.076396

"""

from alembic import op
import sqlalchemy as sa


# revision identifiers, used by Alembic.
revision = "fc6f7f3cb801"

down_revision = "6f0ac37e9bc4"
branch_labels = None
depends_on = ("ed1de98c65aa",)


def upgrade():
    op.execute(
        """
        INSERT INTO gn_imports.cor_import_datasets (id_import, id_dataset)
        SELECT DISTINCT id_import, id_dataset
        FROM (
            -- Stations
            SELECT station.id_import, station.id_dataset
            FROM pr_occhab.t_stations station
            WHERE station.id_import IS NOT NULL
              AND station.id_dataset IS NOT NULL

            UNION

            -- Habitats
            SELECT hab.id_import, station.id_dataset
            FROM pr_occhab.t_habitats hab
            JOIN pr_occhab.t_stations station ON station.id_station = hab.id_station
            WHERE hab.id_import IS NOT NULL
              AND station.id_dataset IS NOT NULL
        ) combined
        --  Ignore if already present
        ON CONFLICT (id_import, id_dataset) DO NOTHING
    """
    )


def downgrade():
    pass  # We can't rollback this migration. However rolling back ed1de98c65aa will rollback this migration as well.
